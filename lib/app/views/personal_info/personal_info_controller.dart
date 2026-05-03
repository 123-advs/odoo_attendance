import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../data/providers/odoo_provider.dart';
import '../../widgets/app_notify.dart';
import '../profile/profile_controller.dart';

class PersonalInfoController extends GetxController {
  final emailCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  final isSaving = false.obs;
  final emailError = RxnString();
  final dirty = false.obs;

  late final ProfileController _profile;
  final _provider = OdooProvider();

  String _origEmail = '';
  String _origMobile = '';
  String _origPhone = '';

  bool get canEdit => _profile.employeeId.value != null;

  @override
  void onInit() {
    super.onInit();
    _profile = Get.find<ProfileController>();

    emailCtrl.text = _profile.email.value;
    mobileCtrl.text = _profile.phone.value;
    phoneCtrl.text = '';

    _origEmail = emailCtrl.text;
    _origMobile = mobileCtrl.text;
    _origPhone = phoneCtrl.text;

    emailCtrl.addListener(_onChanged);
    mobileCtrl.addListener(_onChanged);
    phoneCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    dirty.value = emailCtrl.text.trim() != _origEmail ||
        mobileCtrl.text.trim() != _origMobile ||
        phoneCtrl.text.trim() != _origPhone;
    if (emailError.value != null) emailError.value = null;
  }

  Map<String, dynamic> _diff() {
    final values = <String, dynamic>{};
    if (emailCtrl.text.trim() != _origEmail) {
      values['work_email'] = emailCtrl.text.trim();
    }
    if (mobileCtrl.text.trim() != _origMobile) {
      values['mobile_phone'] = mobileCtrl.text.trim();
    }
    if (phoneCtrl.text.trim() != _origPhone) {
      values['work_phone'] = phoneCtrl.text.trim();
    }
    return values;
  }

  bool _validate() {
    final email = emailCtrl.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailError.value = 'Email không hợp lệ';
      return false;
    }
    emailError.value = null;
    return true;
  }

  Future<void> save() async {
    if (isSaving.value) return;
    if (!canEdit) {
      AppNotify.warning(
        'Không thể lưu',
        'Không tìm thấy hồ sơ nhân viên gắn với tài khoản.',
      );
      return;
    }
    if (!dirty.value) {
      Get.back();
      return;
    }
    if (!_validate()) return;

    isSaving.value = true;
    try {
      final empId = _profile.employeeId.value!;
      final ok = await _provider.updateEmployee(empId, _diff());
      if (ok) {
        AppNotify.success('Đã lưu', 'Thông tin của bạn đã được cập nhật.');
        await _profile.refreshProfile();
        Get.back();
      } else {
        AppNotify.error('Lỗi', 'Không thể cập nhật thông tin.');
      }
    } on DioException catch (e) {
      AppNotify.error('Lỗi', e.message ?? 'Không kết nối được máy chủ.');
    } catch (e) {
      AppNotify.error('Lỗi', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    mobileCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}
