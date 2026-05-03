import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Đổi mật khẩu',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              Center(child: _LockHero()),
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  'Bảo mật tài khoản',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Text(
                    'Mật khẩu mới sẽ áp dụng ngay cho mọi thiết bị đăng nhập tài khoản này.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Obx(() => AppTextField(
                    label: 'Mật khẩu hiện tại',
                    controller: controller.oldPwdCtrl,
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: controller.obscureOld.value,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    errorText: controller.oldError.value,
                    onChanged: controller.onOldChanged,
                    suffix: _EyeToggle(
                      obscured: controller.obscureOld.value,
                      onTap: controller.toggleOld,
                    ),
                  )),
              SizedBox(height: 16.h),
              Obx(() => AppTextField(
                    label: 'Mật khẩu mới',
                    controller: controller.newPwdCtrl,
                    hintText: 'Tối thiểu 8 ký tự',
                    prefixIcon: Icons.lock_reset_rounded,
                    obscureText: controller.obscureNew.value,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: controller.newError.value,
                    onChanged: controller.onNewChanged,
                    suffix: _EyeToggle(
                      obscured: controller.obscureNew.value,
                      onTap: controller.toggleNew,
                    ),
                  )),
              SizedBox(height: 8.h),
              Obx(() => _StrengthMeter(score: controller.strength.value)),
              SizedBox(height: 16.h),
              Obx(() => AppTextField(
                    label: 'Nhập lại mật khẩu mới',
                    controller: controller.confirmPwdCtrl,
                    hintText: 'Nhập lại mật khẩu mới',
                    prefixIcon: Icons.check_circle_outline_rounded,
                    obscureText: controller.obscureConfirm.value,
                    textInputAction: TextInputAction.done,
                    errorText: controller.confirmError.value,
                    onChanged: controller.onConfirmChanged,
                    onSubmitted: (_) => controller.submit(),
                    suffix: _EyeToggle(
                      obscured: controller.obscureConfirm.value,
                      onTap: controller.toggleConfirm,
                    ),
                  )),
              SizedBox(height: 16.h),
              Obx(() {
                final err = controller.formError.value;
                if (err == null) return const SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.error, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          err,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 8.h),
              Obx(() => PrimaryButton(
                    label: 'CẬP NHẬT MẬT KHẨU',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.submit,
                  )),
              SizedBox(height: 20.h),
              _Tips(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dim = 96.r;
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
      alignment: Alignment.center,
      child: Icon(
        Icons.shield_rounded,
        color: Colors.white,
        size: dim * 0.5,
      ),
    );
  }
}

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.obscured, required this.onTap});
  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscured
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        size: 20.sp,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score});
  final int score;

  static const _labels = ['Quá ngắn', 'Yếu', 'Trung bình', 'Mạnh', 'Rất mạnh'];

  Color _colorFor(int s) {
    if (s <= 1) return AppColors.error;
    if (s == 2) return AppColors.warning;
    if (s == 3) return AppColors.accent;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(score);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (i) {
                final active = i < score;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 4.w : 0),
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: active ? color : AppColors.divider,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            _labels[score],
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: score == 0 ? AppColors.textMuted : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  color: AppColors.accent, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'Gợi ý mật khẩu mạnh',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ..._tips.map((t) => Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 5.h),
                      child: Container(
                        width: 4.r,
                        height: 4.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static const _tips = [
    'Tối thiểu 12 ký tự, kết hợp chữ hoa, chữ thường và số.',
    'Thêm ký tự đặc biệt (! @ # \$ %) để tăng độ bảo mật.',
    'Không dùng mật khẩu đã dùng cho tài khoản khác.',
    'Tránh thông tin cá nhân dễ đoán (ngày sinh, tên, số điện thoại).',
  ];
}
