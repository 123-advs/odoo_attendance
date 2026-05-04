import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:intl/intl.dart';

import '../data/models/face_record.dart';
import '../data/providers/odoo_provider.dart';
import '../routes/app_routes.dart';
import '../views/profile/profile_controller.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_notify.dart';

class HomeController extends GetxController {
  final now = DateTime.now().obs;

  // Server-driven attendance state
  final attendanceState = 'checked_out'.obs;
  final lastAttendanceId = RxnInt();
  final checkInAt = Rxn<DateTime>();
  final checkOutAt = Rxn<DateTime>();

  // Network locks
  final isProcessing = false.obs; // toggling check-in/out
  final isRefreshing = false.obs; // background fetch

  Timer? _ticker;
  Worker? _employeeWatcher;

  late final ProfileController _profile;
  final _provider = OdooProvider();

  bool get hasCheckedIn => attendanceState.value == 'checked_in';

  String get greeting {
    final h = now.value.hour;
    if (h < 11) return 'Chào buổi sáng';
    if (h < 14) return 'Chào buổi trưa';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String get formattedDate =>
      DateFormat("EEEE, dd 'tháng' M, y", 'vi_VN').format(now.value);

  String get formattedTime =>
      DateFormat('HH:mm:ss', 'vi_VN').format(now.value);

  String get workedHours {
    final ci = checkInAt.value;
    if (ci == null) return '--:--';
    final end = checkOutAt.value ?? now.value;
    final dur = end.difference(ci);
    if (dur.isNegative) return '--:--';
    final h = dur.inHours.toString().padLeft(2, '0');
    final m = (dur.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void onInit() {
    super.onInit();
    _profile = Get.find<ProfileController>();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });

    // React when employee_id becomes available (profile loads after home).
    _employeeWatcher = ever<int?>(_profile.employeeId, (id) {
      if (id != null) refreshAttendance();
    });
    if (_profile.employeeId.value != null) refreshAttendance();
  }

  Future<void> refreshAttendance() async {
    final empId = _profile.employeeId.value;
    if (empId == null || isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      final state = await _provider.fetchAttendanceState(empId);
      attendanceState.value = state.state;
      lastAttendanceId.value = state.lastId;
      checkInAt.value = state.checkIn;
      checkOutAt.value = state.checkOut;
    } catch (e, st) {
      debugPrint('[Home] refreshAttendance failed: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> onCheckInPressed() async {
    if (isProcessing.value) return;

    final empId = _profile.employeeId.value;
    if (empId == null) {
      AppNotify.warning(
        'Chưa thể chấm công',
        'Tài khoản chưa được liên kết hồ sơ nhân viên.',
      );
      return;
    }

    // Guard: must have enrolled face before check-in/out.
    if (!_profile.faceEnrolled.value ||
        _profile.faceEmbedding.value == null) {
      final goEnroll = await AppDialog.confirm(
        title: 'Chưa đăng ký khuôn mặt',
        message:
            'Bạn cần đăng ký khuôn mặt một lần trước khi chấm công. Đăng ký ngay?',
        confirmLabel: 'Đăng ký',
        cancelLabel: 'Để sau',
        type: DialogType.info,
      );
      if (goEnroll) {
        Get.toNamed(AppRoutes.faceEnroll);
      }
      return;
    }

    final isOut = hasCheckedIn;

    // Open face capture screen and wait for verdict. Returns null
    // if user cancels or hits the max-attempts wall.
    final result = await Get.toNamed<dynamic>(
      AppRoutes.faceCapture,
      arguments: {'intent': isOut ? 'out' : 'in'},
    );
    if (result is! FaceCaptureResult) return;

    isProcessing.value = true;
    try {
      if (isOut) {
        final lastId = lastAttendanceId.value;
        if (lastId == null) {
          AppNotify.error(
            'Lỗi',
            'Không tìm thấy phiên chấm công đang mở.',
          );
          return;
        }
        await _provider.checkOutAttendance(
          lastId,
          faceImage: result.selfieJpeg,
          matchScore: result.matchScore,
        );
        debugPrint('[Home] check-out ok, attendance id=$lastId, '
            'score=${result.matchScore.toStringAsFixed(3)}');
        AppNotify.success(
          'Đã check-out',
          'Hoàn tất ca lúc ${DateFormat('HH:mm').format(DateTime.now())}.',
        );
      } else {
        final newId = await _provider.checkInAttendance(
          empId,
          faceImage: result.selfieJpeg,
          matchScore: result.matchScore,
        );
        debugPrint('[Home] check-in ok, attendance id=$newId, '
            'score=${result.matchScore.toStringAsFixed(3)}');
        AppNotify.success(
          'Đã chấm công',
          'Bắt đầu ca làm việc lúc ${DateFormat('HH:mm').format(DateTime.now())}.',
        );
      }
      await refreshAttendance();
    } on DioException catch (e) {
      AppNotify.error('Lỗi', e.message ?? 'Không kết nối được máy chủ.');
    } catch (e) {
      AppNotify.error('Lỗi', e.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _employeeWatcher?.dispose();
    super.onClose();
  }
}
