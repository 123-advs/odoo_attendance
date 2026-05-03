import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../data/providers/odoo_provider.dart';
import '../../widgets/app_notify.dart';

class ChangePasswordController extends GetxController {
  final oldPwdCtrl = TextEditingController();
  final newPwdCtrl = TextEditingController();
  final confirmPwdCtrl = TextEditingController();

  final obscureOld = true.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;

  final isLoading = false.obs;
  final oldError = RxnString();
  final newError = RxnString();
  final confirmError = RxnString();
  final formError = RxnString();

  /// 0 (empty) → 4 (very strong)
  final strength = 0.obs;

  final _provider = OdooProvider();

  void toggleOld() => obscureOld.toggle();
  void toggleNew() => obscureNew.toggle();
  void toggleConfirm() => obscureConfirm.toggle();

  void onOldChanged(String _) {
    if (oldError.value != null) oldError.value = null;
    if (formError.value != null) formError.value = null;
  }

  void onNewChanged(String s) {
    if (newError.value != null) newError.value = null;
    if (formError.value != null) formError.value = null;
    strength.value = _scorePassword(s);
  }

  void onConfirmChanged(String _) {
    if (confirmError.value != null) confirmError.value = null;
    if (formError.value != null) formError.value = null;
  }

  int _scorePassword(String pwd) {
    if (pwd.isEmpty) return 0;
    var score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(pwd)) score++;
    return score.clamp(0, 4);
  }

  bool _validate() {
    var ok = true;
    if (oldPwdCtrl.text.isEmpty) {
      oldError.value = 'Vui lòng nhập mật khẩu hiện tại';
      ok = false;
    }
    if (newPwdCtrl.text.length < 8) {
      newError.value = 'Mật khẩu mới phải có ít nhất 8 ký tự';
      ok = false;
    }
    if (newPwdCtrl.text.isNotEmpty &&
        newPwdCtrl.text == oldPwdCtrl.text) {
      newError.value = 'Mật khẩu mới phải khác mật khẩu hiện tại';
      ok = false;
    }
    if (confirmPwdCtrl.text != newPwdCtrl.text) {
      confirmError.value = 'Mật khẩu nhập lại không khớp';
      ok = false;
    }
    return ok;
  }

  Future<void> submit() async {
    if (isLoading.value) return;
    if (!_validate()) return;

    isLoading.value = true;
    formError.value = null;
    try {
      final ok = await _provider.changePassword(
        oldPassword: oldPwdCtrl.text,
        newPassword: newPwdCtrl.text,
      );
      if (ok) {
        AppNotify.success(
          'Đã đổi mật khẩu',
          'Mật khẩu của bạn đã được cập nhật thành công.',
        );
        Get.back();
      } else {
        formError.value = 'Không thể đổi mật khẩu. Vui lòng thử lại.';
      }
    } on DioException catch (e) {
      final msg = e.message ?? '';
      if (msg.toLowerCase().contains('password') ||
          msg.toLowerCase().contains('access')) {
        formError.value = 'Mật khẩu hiện tại không đúng';
      } else {
        formError.value = msg.isEmpty
            ? 'Không kết nối được máy chủ'
            : msg;
      }
    } catch (e) {
      formError.value = 'Đã có lỗi xảy ra: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    oldPwdCtrl.dispose();
    newPwdCtrl.dispose();
    confirmPwdCtrl.dispose();
    super.onClose();
  }
}
