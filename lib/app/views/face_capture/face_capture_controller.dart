import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/face_constants.dart';
import '../../data/models/face_record.dart';
import '../../services/face_capture_utils.dart';
import '../../services/face_match_service.dart';
import '../../widgets/app_notify.dart';
import '../profile/profile_controller.dart';

enum FaceCaptureState {
  initializing,
  ready,
  capturing,
  processing,
  matchSuccess,
  matchFailed,
  exhausted,
  error,
}

class FaceCaptureController extends GetxController {
  CameraController? _camera;
  CameraController? get camera => _camera;
  late final FaceDetector _detector;

  final state = FaceCaptureState.initializing.obs;
  final feedback = ''.obs;
  final attempts = 0.obs;
  final lastScore = Rxn<double>();
  final errorMessage = RxnString();

  /// 'in' or 'out' — only affects the title/snackbar wording. Match
  /// logic is identical for both.
  String _intent = 'in';
  String get intent => _intent;
  String get title =>
      _intent == 'out' ? 'Xác thực để check-out' : 'Xác thực để chấm công';

  // ── Auto-capture state ─────────────────────────────────────────────
  static const _frameThrottleMs = 350;
  static const _consecutiveGoodNeeded = 3;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _goodFrameCount = 0;
  bool _autoCaptureFiring = false;
  bool _disposed = false;

  // Used to derive the ML Kit InputImage rotation. Cached from the
  // CameraDescription once the camera is initialized.
  int _sensorOrientation = 0;

  ProfileController get _profile => Get.find<ProfileController>();
  FaceMatchService get _faceMatch => Get.find<FaceMatchService>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['intent'] is String) {
      _intent = args['intent'] as String;
    }
    _detector = FaceCaptureUtils.createDetector();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!_faceMatch.isReady) {
      _fail(
        'Mô hình nhận diện chưa được tải. '
        'Vui lòng cài đặt mobilefacenet.tflite.',
      );
      return;
    }
    if (_profile.employeeId.value == null) {
      _fail('Tài khoản chưa được liên kết hồ sơ nhân viên.');
      return;
    }
    if (_profile.faceEmbedding.value == null ||
        _profile.faceEmbedding.value!.isEmpty) {
      _fail('Bạn chưa đăng ký khuôn mặt. Hãy đăng ký trước.');
      return;
    }

    final perm = await Permission.camera.request();
    if (!perm.isGranted) {
      _fail('Bạn cần cấp quyền Camera để chấm công.');
      return;
    }

    _camera = await FaceCaptureUtils.initFrontCamera();
    if (_camera == null) {
      _fail('Không thể khởi động camera trước.');
      return;
    }
    _sensorOrientation = _camera!.description.sensorOrientation;

    feedback.value = 'Đưa mặt vào khung — máy sẽ tự chụp';
    state.value = FaceCaptureState.ready;
    update();

    _startScanning();
  }

  void _fail(String message) {
    errorMessage.value = message;
    state.value = FaceCaptureState.error;
  }

  // ── Auto-capture scanning ──────────────────────────────────────────

  void _startScanning() {
    if (_disposed) return;
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (cam.value.isStreamingImages) return;
    _goodFrameCount = 0;
    _autoCaptureFiring = false;
    cam.startImageStream(_processFrame);
  }

  Future<void> _stopScanning() async {
    final cam = _camera;
    if (cam == null) return;
    if (!cam.value.isStreamingImages) return;
    try {
      await cam.stopImageStream();
    } catch (e) {
      debugPrint('[FaceCapture] stopImageStream: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_disposed) return;
    if (_autoCaptureFiring) return;
    if (state.value != FaceCaptureState.ready) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameAt).inMilliseconds < _frameThrottleMs) {
      return;
    }
    _lastFrameAt = now;

    try {
      // Concat all planes; nv21 emits 1 plane on Android, this also
      // works defensively if the device emits multiple planes.
      final all = WriteBuffer();
      for (final plane in image.planes) {
        all.putUint8List(plane.bytes);
      }
      final bytes = all.done().buffer.asUint8List();

      final input = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size:
              Size(image.width.toDouble(), image.height.toDouble()),
          rotation:
              InputImageRotationValue.fromRawValue(_sensorOrientation) ??
                  InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _detector.processImage(input);
      if (_disposed) return;
      if (state.value != FaceCaptureState.ready) return;

      final quality = FaceCaptureUtils.assess(faces);

      if (quality.isGood) {
        _goodFrameCount++;
        if (_goodFrameCount < _consecutiveGoodNeeded) {
          feedback.value =
              'Giữ yên... $_goodFrameCount/$_consecutiveGoodNeeded';
        } else {
          _autoCaptureFiring = true;
          feedback.value = 'Đang chụp...';
          await _stopScanning();
          await capture();
        }
      } else {
        _goodFrameCount = 0;
        feedback.value = quality.reason;
      }
    } catch (e) {
      // Frame errors are non-fatal — drop and keep scanning.
      debugPrint('[FaceCapture] frame analysis error: $e');
    }
  }

  // ── Capture (manual shutter or auto-fire) ──────────────────────────

  Future<void> capture() async {
    final s = state.value;
    if (s != FaceCaptureState.ready &&
        s != FaceCaptureState.matchFailed) {
      return;
    }
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;

    await _stopScanning();

    state.value = FaceCaptureState.capturing;
    feedback.value = 'Đang chụp...';

    try {
      final shot = await cam.takePicture();
      final bytes = await shot.readAsBytes();

      final quality =
          await FaceCaptureUtils.detectFromFile(_detector, shot.path);
      if (!quality.isGood || quality.face == null) {
        feedback.value = quality.reason;
        state.value = FaceCaptureState.matchFailed;
        AppNotify.warning('Không đạt yêu cầu', quality.reason);
        _scheduleRescan();
        return;
      }

      state.value = FaceCaptureState.processing;
      feedback.value = 'Đang xác thực khuôn mặt...';

      final cropped =
          FaceCaptureUtils.cropFaceJpeg(bytes, quality.face!);
      if (cropped == null) {
        state.value = FaceCaptureState.matchFailed;
        feedback.value = 'Không cắt được vùng khuôn mặt.';
        AppNotify.error('Lỗi', 'Không cắt được vùng khuôn mặt.');
        _scheduleRescan();
        return;
      }

      final embedding = await _faceMatch.extractEmbedding(cropped);
      if (embedding == null || embedding.isEmpty) {
        state.value = FaceCaptureState.matchFailed;
        feedback.value = 'Không trích xuất được đặc trưng.';
        AppNotify.error('Lỗi', 'Không trích xuất được đặc trưng.');
        _scheduleRescan();
        return;
      }

      final stored = _profile.faceEmbedding.value!;
      final score = FaceMatchService.cosine(embedding, stored);
      lastScore.value = score;
      attempts.value++;

      final pct = (score * 100).clamp(0, 100).toStringAsFixed(0);

      if (score >= FaceConstants.matchThreshold) {
        state.value = FaceCaptureState.matchSuccess;
        feedback.value = 'Khớp $pct% — xác thực thành công!';

        final selfie =
            FaceCaptureUtils.compressSelfie(bytes) ?? bytes;
        final result = FaceCaptureResult(
          selfieJpeg: selfie,
          faceCropJpeg: cropped,
          embedding: embedding,
          matchScore: score,
        );
        // Brief pause so user perceives the success state.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!_disposed) Get.back<FaceCaptureResult>(result: result);
      } else {
        if (attempts.value >= FaceConstants.maxMatchAttempts) {
          state.value = FaceCaptureState.exhausted;
          feedback.value =
              'Đã thử ${attempts.value} lần và chưa khớp. Vui lòng thử lại sau hoặc đăng ký lại khuôn mặt.';
        } else {
          state.value = FaceCaptureState.matchFailed;
          final left = FaceConstants.maxMatchAttempts - attempts.value;
          feedback.value =
              'Khuôn mặt không khớp ($pct%). Còn $left lượt thử.';
          _scheduleRescan();
        }
      }
    } catch (e, st) {
      debugPrint('[FaceCapture] capture failed: $e');
      debugPrintStack(stackTrace: st);
      state.value = FaceCaptureState.matchFailed;
      feedback.value = 'Không chụp được, vui lòng thử lại.';
      AppNotify.error('Lỗi', 'Không chụp được, vui lòng thử lại.');
      _scheduleRescan();
    }
  }

  /// Auto-restart scanning 2.5s after matchFailed so user doesn't have
  /// to tap shutter manually.
  void _scheduleRescan() {
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (_disposed) return;
      if (state.value != FaceCaptureState.matchFailed) return;
      _autoCaptureFiring = false;
      _goodFrameCount = 0;
      state.value = FaceCaptureState.ready;
      feedback.value = 'Đưa mặt vào khung — máy sẽ tự chụp';
      _startScanning();
    });
  }

  void retry() {
    if (state.value == FaceCaptureState.exhausted) return;
    _autoCaptureFiring = false;
    _goodFrameCount = 0;
    state.value = FaceCaptureState.ready;
    feedback.value = 'Đưa mặt vào khung — máy sẽ tự chụp';
    _startScanning();
  }

  void cancel() {
    Get.back<FaceCaptureResult?>();
  }

  @override
  void onClose() {
    _disposed = true;
    _stopScanning();
    _detector.close();
    _camera?.dispose();
    super.onClose();
  }
}
