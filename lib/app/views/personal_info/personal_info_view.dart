import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../profile/profile_controller.dart';
import 'personal_info_controller.dart';

class PersonalInfoView extends GetView<PersonalInfoController> {
  const PersonalInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Obx(() {
            final saving = controller.isSaving.value;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: TextButton(
                onPressed: saving ? null : controller.save,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: saving
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                              AppColors.primary),
                        ),
                      )
                    : Text(
                        'Lưu',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _Avatar(profile: profile)),
              SizedBox(height: 8.h),
              Center(
                child: Obx(() => Text(
                      profile.fullName.value,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    )),
              ),
              SizedBox(height: 4.h),
              Center(
                child: Obx(() => Text(
                      profile.role.value,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textMuted,
                      ),
                    )),
              ),
              SizedBox(height: 24.h),
              _SectionLabel(text: 'Thông tin liên hệ'),
              SizedBox(height: 12.h),
              Obx(() => AppTextField(
                    label: 'Email công việc',
                    controller: controller.emailCtrl,
                    hintText: 'name@example.com',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: controller.emailError.value,
                  )),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'Số điện thoại di động',
                controller: controller.mobileCtrl,
                hintText: '0901 234 567',
                prefixIcon: Icons.smartphone_rounded,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'Số máy bàn',
                controller: controller.phoneCtrl,
                hintText: '028 1234 5678',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 28.h),
              _SectionLabel(text: 'Tổ chức'),
              SizedBox(height: 12.h),
              _ReadOnlyRow(
                icon: Icons.badge_outlined,
                label: 'Họ và tên',
                valueListenable: profile.fullName,
              ),
              _Divider(),
              _ReadOnlyRow(
                icon: Icons.work_outline_rounded,
                label: 'Chức vụ',
                valueListenable: profile.role,
              ),
              _Divider(),
              _ReadOnlyRow(
                icon: Icons.apartment_rounded,
                label: 'Phòng ban',
                valueListenable: profile.department,
              ),
              SizedBox(height: 24.h),
              Obx(() {
                if (controller.canEdit) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18.sp, color: AppColors.warning),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Tài khoản của bạn chưa được liên kết hồ sơ nhân viên — chưa thể chỉnh sửa.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});
  final ProfileController profile;

  @override
  Widget build(BuildContext context) {
    final dim = 96.r;
    return Obx(() {
      final bytes = profile.avatarBytes.value;
      Widget letter() => Text(
            profile.fullName.value.trim().isEmpty
                ? '?'
                : profile.fullName.value.trim()[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 36.sp,
              fontWeight: FontWeight.w700,
            ),
          );
      return Container(
        width: dim,
        height: dim,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: bytes != null
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: dim,
                height: dim,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => letter(),
              )
            : letter(),
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.valueListenable,
  });

  final IconData icon;
  final String label;
  final RxString valueListenable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 2.h),
                Obx(() => Text(
                      valueListenable.value.isEmpty
                          ? '—'
                          : valueListenable.value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    )),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 14.sp,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(height: 8.h);
}
