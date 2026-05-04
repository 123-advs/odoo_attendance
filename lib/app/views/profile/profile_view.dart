import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_notify.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tài khoản',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Obx(() => IconButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.refreshProfile,
                          icon: controller.isLoading.value
                              ? SizedBox(
                                  width: 18.r,
                                  height: 18.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        AppColors.primary),
                                  ),
                                )
                              : Icon(
                                  Icons.refresh_rounded,
                                  color: AppColors.textPrimary,
                                  size: 22.sp,
                                ),
                        )),
                  ],
                ),
                SizedBox(height: 12.h),
                _ProfileHeader(controller: controller),
                Obx(() {
                  final err = controller.loadError.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.warning, size: 18.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              err,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 16.h),
                Obx(() {
                  if (controller.department.value.isEmpty &&
                      controller.phone.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _DetailsCard(controller: controller),
                  );
                }),
                Obx(() => _MenuSection(
                      title: 'Tài khoản',
                      items: [
                        _MenuItemData(
                          icon: Icons.person_outline_rounded,
                          label: 'Thông tin cá nhân',
                          onTap: () =>
                              Get.toNamed(AppRoutes.personalInfo),
                        ),
                        _MenuItemData(
                          icon: Icons.lock_outline_rounded,
                          label: 'Đổi mật khẩu',
                          onTap: () =>
                              Get.toNamed(AppRoutes.changePassword),
                        ),
                        _MenuItemData(
                          icon: Icons.fingerprint_rounded,
                          label: 'Quản lý dữ liệu khuôn mặt',
                          trailing: controller.faceEnrolled.value
                              ? 'Đã đăng ký'
                              : null,
                          onTap: () =>
                              Get.toNamed(AppRoutes.faceEnroll),
                        ),
                      ],
                    )),
                SizedBox(height: 16.h),
                _MenuSection(
                  title: 'Cài đặt',
                  items: [
                    _MenuItemData(
                      icon: Icons.notifications_none_rounded,
                      label: 'Thông báo',
                      onTap: () => _todo('Thông báo'),
                    ),
                    _MenuItemData(
                      icon: Icons.language_rounded,
                      label: 'Ngôn ngữ',
                      trailing: 'Tiếng Việt',
                      onTap: () => _todo('Ngôn ngữ'),
                    ),
                    _MenuItemData(
                      icon: Icons.help_outline_rounded,
                      label: 'Trợ giúp & Phản hồi',
                      onTap: () => _todo('Trợ giúp'),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _LogoutTile(onTap: controller.logout),
                SizedBox(height: 16.h),
                Center(
                  child: Obx(() => Text(
                        'Odoo Attendance ${controller.appVersion.value}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                        ),
                      )),
                ),
                SizedBox(height: 4.h),
                Center(
                  child: Text(
                    '© TCS · Powered by Odoo 17',
                    style: TextStyle(
                      fontSize: 11.sp,
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

  void _todo(String feature) {
    AppNotify.info(feature, 'Tính năng đang được phát triển.');
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller});
  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Obx(() {
        final loading =
            controller.isLoading.value && controller.fullName.value.isEmpty;
        return Row(
          children: [
            _Avatar(controller: controller),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (loading)
                    _SkeletonLine(width: 140.w, height: 18.h)
                  else
                    Text(
                      controller.fullName.value.isEmpty
                          ? 'Nhân viên'
                          : controller.fullName.value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 4.h),
                  if (loading)
                    _SkeletonLine(width: 180.w, height: 12.h)
                  else if (controller.email.value.isNotEmpty)
                    Text(
                      controller.email.value,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 8.h),
                  if (!loading)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        controller.role.value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.controller});
  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final dim = 64.r;
    return Obx(() {
      final bytes = controller.avatarBytes.value;
      final loading =
          controller.isLoading.value && controller.fullName.value.isEmpty;

      Widget letterFallback() => Text(
            controller.fullName.value.trim().isEmpty
                ? '?'
                : controller.fullName.value.trim()[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
            ),
          );

      Widget body;
      if (loading) {
        body = SizedBox(
          width: 22.r,
          height: 22.r,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        );
      } else if (bytes != null) {
        body = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: dim,
          height: dim,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => letterFallback(),
        );
      } else {
        body = letterFallback();
      }

      return Container(
        width: dim,
        height: dim,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: body,
      );
    });
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.controller});
  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Obx(() => Column(
            children: [
              if (controller.department.value.isNotEmpty)
                _DetailRow(
                  icon: Icons.apartment_rounded,
                  label: 'Phòng ban',
                  value: controller.department.value,
                ),
              if (controller.department.value.isNotEmpty &&
                  controller.phone.value.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
              if (controller.phone.value.isNotEmpty)
                _DetailRow(
                  icon: Icons.phone_rounded,
                  label: 'Điện thoại',
                  value: controller.phone.value,
                ),
            ],
          )),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  _MenuItem(item: items[i]),
                  if (!isLast)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Divider(
                        height: 1,
                        color: AppColors.divider,
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.item});
  final _MenuItemData item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
              child: Icon(item.icon, color: AppColors.primary, size: 16.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (item.trailing != null) ...[
              Text(
                item.trailing!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.1),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
