import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';

enum _NotifyKind { success, error, info, warning }

class AppNotify {
  AppNotify._();

  static void success(String title, String message) =>
      _show(_NotifyKind.success, title, message);

  static void error(String title, String message) =>
      _show(_NotifyKind.error, title, message);

  static void info(String title, String message) =>
      _show(_NotifyKind.info, title, message);

  static void warning(String title, String message) =>
      _show(_NotifyKind.warning, title, message);

  static void _show(_NotifyKind kind, String title, String message) {
    final ctx = Get.context;
    if (ctx == null) return;

    final (color, icon) = switch (kind) {
      _NotifyKind.success => (AppColors.primary, Icons.check_circle_rounded),
      _NotifyKind.error => (AppColors.error, Icons.error_rounded),
      _NotifyKind.info => (AppColors.accent, Icons.info_rounded),
      _NotifyKind.warning => (
          const Color(0xFFF59E0B),
          Icons.warning_amber_rounded,
        ),
    };

    Flushbar(
      titleText: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 13.sp,
        ),
      ),
      icon: Icon(icon, color: Colors.white, size: 22.sp),
      leftBarIndicatorColor: Colors.white.withValues(alpha: 0.5),
      backgroundColor: color,
      boxShadows: [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      borderRadius: BorderRadius.circular(14.r),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      flushbarPosition: FlushbarPosition.TOP,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 320),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    ).show(ctx);
  }
}
