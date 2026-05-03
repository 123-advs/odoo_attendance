import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/home_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_notify.dart';
import '../profile/profile_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refreshAttendance,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(controller: controller),
                SizedBox(height: 24.h),
                _StatusCard(controller: controller),
                SizedBox(height: 16.h),
                _CheckInButton(controller: controller),
                SizedBox(height: 24.h),
                _QuickStats(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    final size = 48.r;
    return Obx(() {
      final name = profile.fullName.value.trim().isEmpty
          ? 'Nhân viên'
          : profile.fullName.value;
      final firstChar = name.trim()[0].toUpperCase();
      final bytes = profile.avatarBytes.value;

      Widget letter() => Text(
            firstChar,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          );

      return Row(
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: bytes != null
                ? Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => letter(),
                  )
                : letter(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.greeting,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => AppNotify.info(
              'Thông báo',
              'Chưa có thông báo mới.',
            ),
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppColors.textPrimary,
          ),
        ],
      );
    });
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
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
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    controller.formattedDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                controller.formattedTime,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: 16.h),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _StatusItem(
                      icon: Icons.login_rounded,
                      label: 'Vào ca',
                      value: controller.checkInAt.value == null
                          ? '--:--'
                          : DateFormat('HH:mm')
                              .format(controller.checkInAt.value!),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32.h,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: _StatusItem(
                      icon: Icons.logout_rounded,
                      label: 'Ra ca',
                      value: controller.checkOutAt.value == null
                          ? '--:--'
                          : DateFormat('HH:mm')
                              .format(controller.checkOutAt.value!),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 18.sp),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11.sp,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isIn = controller.hasCheckedIn;
      final busy = controller.isProcessing.value;
      final accent = isIn ? AppColors.accent : AppColors.primary;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : controller.onCheckInPressed,
          borderRadius: BorderRadius.circular(20.r),
          child: Ink(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: accent.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                  ),
                  alignment: Alignment.center,
                  child: busy
                      ? SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(accent),
                          ),
                        )
                      : Icon(
                          isIn
                              ? Icons.logout_rounded
                              : Icons.fingerprint_rounded,
                          color: accent,
                          size: 28.sp,
                        ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        busy
                            ? (isIn ? 'Đang check-out…' : 'Đang chấm công…')
                            : (isIn ? 'Check-out ngay' : 'Chấm công vào ca'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        isIn
                            ? 'Bấm để kết thúc ca làm việc'
                            : 'Bấm để bắt đầu ca làm việc',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    return Row(
      children: [
        Expanded(
          child: Obx(() => _StatTile(
                icon: Icons.timer_outlined,
                iconColor: AppColors.primary,
                label: 'Giờ làm hôm nay',
                value: controller.workedHours,
              )),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Obx(() {
            final dept = profile.department.value;
            return _StatTile(
              icon: Icons.apartment_rounded,
              iconColor: AppColors.accent,
              label: 'Phòng ban',
              value: dept.isEmpty ? 'Chưa cập nhật' : dept,
              valueMaxLines: 2,
              valueSize: 13,
            );
          }),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueMaxLines = 1,
    this.valueSize = 18,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final int valueMaxLines;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: valueSize.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
