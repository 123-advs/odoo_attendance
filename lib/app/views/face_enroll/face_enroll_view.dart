import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/face_overlay.dart';
import 'face_enroll_controller.dart';

class FaceEnrollView extends GetView<FaceEnrollController> {
  const FaceEnrollView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Đăng ký khuôn mặt',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final state = controller.state.value;
          switch (state) {
            case FaceEnrollState.initializing:
              return const _LoadingView(message: 'Đang khởi động camera...');
            case FaceEnrollState.error:
              return _ErrorView(
                message: controller.errorMessage.value ??
                    'Đã có lỗi xảy ra.',
                onRetry: controller.retry,
              );
            case FaceEnrollState.done:
              return const _LoadingView(message: 'Hoàn tất!');
            default:
              return _CaptureView(controller: controller);
          }
        }),
      ),
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({required this.controller});
  final FaceEnrollController controller;

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
                    width: controller.camera!.value.previewSize?.height ??
                        1080,
                    height: controller.camera!.value.previewSize?.width ??
                        1920,
                    child: CameraPreview(controller.camera!),
                  ),
                )
              else
                const ColoredBox(color: Colors.black),
              const FaceOverlay(),
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Obx(() => _StepPills(
                      currentIndex: controller.stepIndex.value,
                      total: FaceEnrollController.stepLabels.length,
                    )),
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
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  )),
              SizedBox(height: 8.h),
              Text(
                'Đảm bảo đủ ánh sáng, không đeo kính râm hoặc khẩu trang.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              Obx(() {
                final state = controller.state.value;
                final busy = state == FaceEnrollState.capturing ||
                    state == FaceEnrollState.processing ||
                    state == FaceEnrollState.uploading;
                return _ShutterButton(
                  busy: busy,
                  onTap: state == FaceEnrollState.ready
                      ? controller.capture
                      : null,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepPills extends StatelessWidget {
  const _StepPills({required this.currentIndex, required this.total});
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: i == currentIndex ? 28.w : 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(5.r),
          ),
        );
      }),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dim = 76.r;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: dim,
        height: dim,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.primary,
            width: 4,
          ),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
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
                  valueColor:
                      AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            : Icon(
                Icons.camera_alt_rounded,
                size: 30.sp,
                color: AppColors.primary,
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
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

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
              'Không thể bắt đầu đăng ký',
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
