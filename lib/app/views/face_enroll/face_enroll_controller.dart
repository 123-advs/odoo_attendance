import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/providers/odoo_provider.dart';
import '../../services/face_capture_utils.dart';
import '../../services/face_match_service.dart';
import '../../widgets/app_notify.dart';
import '../profile/profile_controller.dart';

enum FaceEnrollState {
  initializing,
  ready,
  capturing,
  processing,
  uploading,
  done,
  error,
}

class FaceEnrollController extends GetxController {
  CameraController? _camera;
  CameraController? get camera => _camera;

  late final FaceDetector _detector;

  final state = FaceEnrollState.initializing.obs;
  final stepIndex = 0.obs;
  final feedback = ''.obs;
  final errorMessage = RxnString();

  /// 3 raw embeddings (one per pose) collected during the wizard.
  final List<List<double>> _embeddings = [];

  /// Best full-frame selfie kept for the enrollment audit photo. We
  /// keep the FIRST successful capture since it's the user-facing
  /// "thẳng" pose — most representative for HR review.
  Uint8List? _bestSelfie;

  static const stepLabels = <String>[
    'Bước 1/3 — Nhìn thẳng vào camera',
    'Bước 2/3 — Hơi quay đầu sang TRÁI',
    'Bước 3/3 — Hơi quay đầu sang PHẢI',
  ];

  ProfileController get _profile => Get.find<ProfileController>();
  FaceMatchService get _faceMatch => Get.find<FaceMatchService>();
  final _provider = OdooProvider();

  @override
  void onInit() {
    super.onInit();
    _detector = FaceCaptureUtils.createDetector();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!_faceMatch.isReady) {
      _fail('Mô hình nhận diện chưa được tải. Vui lòng cài đặt mobilefacenet.tflite.');
      return;
    }
    if (_profile.employeeId.value == null) {
      _fail('Tài khoản chưa được liên kết hồ sơ nhân viên.');
      return;
    }

    final perm = await Permission.camera.request();
    if (!perm.isGranted) {
      _fail('Bạn cần cấp quyền Camera để đăng ký khuôn mặt.');
      return;
    }

    _camera = await FaceCaptureUtils.initFrontCamera();
    if (_camera == null) {
      _fail('Không thể khởi động camera trước.');
      return;
    }

    feedback.value = stepLabels[0];
    state.value = FaceEnrollState.ready;
    update(); // signal CameraPreview can render
  }

  void _fail(String message) {
    errorMessage.value = message;
    state.value = FaceEnrollState.error;
  }

  Future<void> capture() async {
    if (state.value != FaceEnrollState.ready) return;
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;

    state.value = FaceEnrollState.capturing;
    feedback.value = 'Đang chụp...';

    try {
      final shot = await cam.takePicture();
      final bytes = await shot.readAsBytes();

      final quality =
          await FaceCaptureUtils.detectFromFile(_detector, shot.path);
      if (!quality.isGood || quality.face == null) {
        state.value = FaceEnrollState.ready;
        feedback.value = quality.reason;
        AppNotify.warning('Không đạt yêu cầu', quality.reason);
        return;
      }

      state.value = FaceEnrollState.processing;
      feedback.value = 'Đang xử lý khuôn mặt...';

      final cropped = FaceCaptureUtils.cropFaceJpeg(bytes, quality.face!);
      if (cropped == null) {
        state.value = FaceEnrollState.ready;
        AppNotify.error('Lỗi', 'Không cắt được vùng khuôn mặt.');
        return;
      }

      final embedding = await _faceMatch.extractEmbedding(cropped);
      if (embedding == null || embedding.isEmpty) {
        state.value = FaceEnrollState.ready;
        AppNotify.error('Lỗi', 'Không trích xuất được đặc trưng.');
        return;
      }

      _embeddings.add(embedding);
      _bestSelfie ??= FaceCaptureUtils.compressSelfie(bytes);

      if (stepIndex.value < stepLabels.length - 1) {
        stepIndex.value++;
        feedback.value = stepLabels[stepIndex.value];
        state.value = FaceEnrollState.ready;
      } else {
        await _finalizeAndUpload();
      }
    } catch (e, st) {
      debugPrint('[FaceEnroll] capture failed: $e');
      debugPrintStack(stackTrace: st);
      state.value = FaceEnrollState.ready;
      AppNotify.error('Lỗi', 'Không chụp được, vui lòng thử lại.');
    }
  }

  Future<void> _finalizeAndUpload() async {
    final empId = _profile.employeeId.value;
    if (empId == null) {
      _fail('Không tìm thấy nhân viên.');
      return;
    }
    if (_bestSelfie == null || _embeddings.isEmpty) {
      _fail('Không có dữ liệu để lưu.');
      return;
    }

    state.value = FaceEnrollState.uploading;
    feedback.value = 'Đang lưu lên máy chủ...';

    try {
      final avg = FaceMatchService.averageNormalized(_embeddings);
      final ok = await _provider.enrollFace(
        employeeId: empId,
        imageBytes: _bestSelfie!,
        embedding: avg,
      );
      if (!ok) {
        _fail('Máy chủ từ chối yêu cầu.');
        return;
      }
      state.value = FaceEnrollState.done;

      // Order matters: pop first, then notify after the pop frame is
      // committed. AppNotify uses Flushbar which internally pushes a
      // route — colliding with Get.back triggers Navigator's
      // `!_debugLocked` assertion. Deferring via postFrame avoids it.
      Get.back<bool>(result: true);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        AppNotify.success(
          'Đăng ký thành công',
          'Khuôn mặt của bạn đã được lưu.',
        );
      });
      _profile.refreshProfile().ignore();
    } on DioException catch (e) {
      _fail(e.message ?? 'Không kết nối được máy chủ.');
    } catch (e) {
      _fail('Đã có lỗi xảy ra: $e');
    }
  }

  void retry() {
    _embeddings.clear();
    _bestSelfie = null;
    stepIndex.value = 0;
    errorMessage.value = null;
    feedback.value = stepLabels[0];
    state.value = FaceEnrollState.ready;
  }

  @override
  void onClose() {
    _detector.close();
    _camera?.dispose();
    super.onClose();
  }
}
