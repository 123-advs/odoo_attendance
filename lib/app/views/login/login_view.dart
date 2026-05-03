import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_notify.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/tcs_logo.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32.h),
                const Center(child: TcsLogo(size: 80)),
                SizedBox(height: 32.h),
                Text(
                  'Chấm công Odoo',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Đăng nhập để tiếp tục',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 32.h),
                Obx(() => AppTextField(
                      label: 'Tên đăng nhập',
                      controller: controller.loginCtrl,
                      hintText: 'odoo@gmail.com',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      errorText: controller.loginError.value,
                      onChanged: controller.onLoginChanged,
                    )),
                SizedBox(height: 20.h),
                Obx(() => AppTextField(
                      label: 'Mật khẩu',
                      controller: controller.passwordCtrl,
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: Icons.lock_outline,
                      obscureText: controller.obscurePassword.value,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      errorText: controller.passwordError.value,
                      onChanged: controller.onPasswordChanged,
                      onSubmitted: (_) => controller.submit(),
                      suffix: IconButton(
                        onPressed: controller.toggleObscure,
                        icon: Icon(
                          controller.obscurePassword.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )),
                SizedBox(height: 16.h),
                Obx(() {
                  final err = controller.formError.value;
                  if (err == null) return SizedBox(height: 0);
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
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
                      label: 'ĐĂNG NHẬP',
                      isLoading: controller.isLoading.value,
                      onPressed: controller.submit,
                    )),
                SizedBox(height: 16.h),
                Center(
                  child: TextButton(
                    onPressed: () => AppNotify.info(
                      'Quên mật khẩu',
                      'Vui lòng liên hệ quản trị viên hệ thống.',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                SizedBox(height: 32.h),
                Divider(color: AppColors.divider, height: 1),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    '© 2026 TCS TECH. Giải pháp doanh nghiệp chính xác.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
