import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/face_overlay.dart';
import 'face_capture_controller.dart';

class FaceCaptureView extends GetView<FaceCaptureController> {
  const FaceCaptureView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: controller.cancel,
          icon: const Icon(Icons.close_rounded),
        ),
        title: Obx(() => Text(
              controller.title,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            )),
      ),
      body: SafeArea(
        child: Obx(() {
          final s = controller.state.value;
          switch (s) {
            case FaceCaptureState.initializing:
              return const _LoadingView(message: 'Đang khởi động camera...');
            case FaceCaptureState.error:
              return _ErrorView(
                message:
                    controller.errorMessage.value ?? 'Đã có lỗi xảy ra.',
              );
            case FaceCaptureState.exhausted:
              return _ExhaustedView(controller: controller);
            default:
              return _CaptureBody(controller: controller);
          }
        }),
      ),
    );
  }
}

class _CaptureBody extends StatelessWidget {
  const _CaptureBody({required this.controller});
  final FaceCaptureController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller.camera != null &&
                  controller.camera!.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.camera!.value.previewSize?.height ?? 1080,
                    height:
                        controller.camera!.value.previewSize?.width ?? 1920,
                    child: CameraPreview(controller.camera!),
                  ),
                )
              else
                const ColoredBox(color: Colors.black),
              Obx(() {
                final s = controller.state.value;
                final color = switch (s) {
                  FaceCaptureState.matchSuccess => AppColors.primary,
                  FaceCaptureState.matchFailed => AppColors.error,
                  _ => Colors.white,
                };
                return FaceOverlay(borderColor: color);
              }),
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: _AttemptBadge(controller: controller),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.black,
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
          child: Column(
            children: [
              Obx(() => Text(
                    controller.feedback.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _feedbackColor(controller.state.value),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  )),
              SizedBox(height: 20.h),
              Obx(() {
                final s = controller.state.value;
                final busy = s == FaceCaptureState.capturing ||
                    s == FaceCaptureState.processing;
                final showRetry = s == FaceCaptureState.matchFailed;
                return _ShutterButton(
                  busy: busy,
                  retry: showRetry,
                  success: s == FaceCaptureState.matchSuccess,
                  onTap: switch (s) {
                    FaceCaptureState.ready => controller.capture,
                    FaceCaptureState.matchFailed => controller.capture,
                    _ => null,
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Color _feedbackColor(FaceCaptureState s) {
    switch (s) {
      case FaceCaptureState.matchSuccess:
        return AppColors.primary;
      case FaceCaptureState.matchFailed:
        return AppColors.error;
      default:
        return Colors.white;
    }
  }
}

class _AttemptBadge extends StatelessWidget {
  const _AttemptBadge({required this.controller});
  final FaceCaptureController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        final score = controller.lastScore.value;
        if (score == null) return const SizedBox.shrink();
        final pct = (score * 100).clamp(0, 100).toStringAsFixed(0);
        final s = controller.state.value;
        final isOk = s == FaceCaptureState.matchSuccess;
        final color = isOk ? AppColors.primary : AppColors.error;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 8.h,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOk ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: Colors.white,
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'Độ khớp: $pct%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.busy,
    required this.retry,
    required this.success,
    required this.onTap,
  });

  final bool busy;
  final bool retry;
  final bool success;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dim = 76.r;
    final color = success ? AppColors.primary : AppColors.primary;
    final icon = success
        ? Icons.check_rounded
        : retry
            ? Icons.refresh_rounded
            : Icons.camera_alt_rounded;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: dim,
        height: dim,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: success ? AppColors.primary : Colors.white,
          border: Border.all(
            color: onTap == null && !success
                ? Colors.white.withValues(alpha: 0.3)
                : color,
            width: 4,
          ),
          boxShadow: onTap == null && !success
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 22,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: busy
            ? SizedBox(
                width: 28.r,
                height: 28.r,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              )
            : Icon(
                icon,
                size: 30.sp,
                color: success ? Colors.white : color,
              ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32.r,
            height: 32.r,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              'Không thể bắt đầu xác thực',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Quay lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExhaustedView extends StatelessWidget {
  const _ExhaustedView({required this.controller});
  final FaceCaptureController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_accounts_rounded,
              color: AppColors.error,
              size: 56.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'Đã hết số lần thử',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Obx(() => Text(
                  controller.feedback.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.sp,
                    height: 1.5,
                  ),
                )),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: controller.cancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Đóng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
