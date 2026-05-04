import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/odoo_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_notify.dart';

// Decode any image format the `image` package supports, re-encode as PNG.
// Runs in an isolate via compute() so it doesn't block UI.
Uint8List? _decodeAndReencode(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    return Uint8List.fromList(img.encodePng(decoded, level: 6));
  } catch (_) {
    return null;
  }
}

class ProfileController extends GetxController {
  final employeeId = RxnInt();
  final fullName = ''.obs;
  final email = ''.obs;
  final role = 'Nhân viên'.obs;
  final department = ''.obs;
  final phone = ''.obs;
  final avatarBytes = Rxn<Uint8List>();

  // Face ID state mirrored from hr.employee.
  final faceEnrolled = false.obs;
  final faceEmbedding = Rxn<List<double>>();
  final faceEnrolledAt = Rxn<DateTime>();

  final isLoading = true.obs;
  final loadError = RxnString();
  final appVersion = ''.obs;

  final _storage = Get.find<StorageService>();
  final _provider = OdooProvider();

  @override
  void onInit() {
    super.onInit();
    _loadVersion();
    refreshProfile();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = 'v${info.version}+${info.buildNumber}';
    } catch (_) {
      appVersion.value = 'v1.0.0';
    }
  }

  Future<void> refreshProfile() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final emp = await _provider.fetchCurrentEmployee();
      if (emp != null) {
        employeeId.value = emp.id;
        fullName.value = emp.name;
        email.value = emp.workEmail ?? '';
        role.value = emp.jobTitle ?? 'Nhân viên';
        department.value = emp.department ?? '';
        phone.value = emp.mobilePhone ?? '';
        faceEnrolled.value = emp.faceEnrolled;
        faceEmbedding.value = emp.faceEmbedding;
        faceEnrolledAt.value = emp.faceEnrolledAt;
        // Fetch + transcode avatar in background so the UI shows other fields immediately.
        unawaited(_fetchAvatar(emp.id));
        return;
      }
      employeeId.value = null;
      faceEnrolled.value = false;
      faceEmbedding.value = null;
      faceEnrolledAt.value = null;

      final user = await _provider.fetchCurrentUser();
      if (user != null) {
        fullName.value =
            (user['name'] as String?)?.trim().isNotEmpty == true
                ? user['name'] as String
                : 'Người dùng';
        email.value = (user['email'] as String?) ??
            (user['login'] as String?) ??
            '';
        role.value = 'Người dùng';
        department.value = '';
        avatarBytes.value = null;
      } else {
        _setFallback();
        loadError.value = 'Không tìm thấy thông tin nhân viên';
      }
    } catch (e, st) {
      debugPrint('[Profile] refresh failed: $e');
      debugPrintStack(stackTrace: st);
      _setFallback();
      loadError.value = 'Không tải được thông tin nhân viên';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchAvatar(int employeeId) async {
    avatarBytes.value = null;
    try {
      final res = await _provider
          .fetchBinary('/web/image/hr.employee/$employeeId/image_512');
      final raw = res.data;
      final contentType = res.headers.value('content-type') ?? '';
      debugPrint(
          '[Profile] avatar HTTP ${res.statusCode} type=$contentType len=${raw?.length}');

      if (raw == null || raw.isEmpty) return;
      if (raw.length >= 4) {
        final magic = raw
            .take(8)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(' ');
        debugPrint('[Profile] avatar first bytes: $magic');
      }
      if (!contentType.startsWith('image/')) {
        debugPrint(
            '[Profile] response is not an image (likely HTML / auth fail).');
        return;
      }

      final input = Uint8List.fromList(raw);
      final png = await compute(_decodeAndReencode, input);
      if (png != null) {
        avatarBytes.value = png;
      } else {
        debugPrint(
            '[Profile] image package failed to decode. Falling back to letter avatar.');
      }
    } catch (e, st) {
      debugPrint('[Profile] _fetchAvatar error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _setFallback() {
    if (fullName.value.isEmpty) fullName.value = 'Nhân viên';
    if (email.value.isEmpty) email.value = '';
    avatarBytes.value = null;
  }

  Future<void> logout() async {
    final confirmed = await AppDialog.confirm(
      title: 'Đăng xuất?',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng.',
      confirmLabel: 'Đăng xuất',
      cancelLabel: 'Hủy',
      type: DialogType.warning,
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;

    await _storage.clearSession();
    AppNotify.success('Đã đăng xuất', 'Hẹn gặp lại bạn.');
    Get.offAllNamed(AppRoutes.login);
  }
}
