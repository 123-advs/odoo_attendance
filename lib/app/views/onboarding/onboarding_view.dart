import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_indicator.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Obx(() => AnimatedOpacity(
                          opacity: controller.isLast ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed:
                                controller.isLast ? null : controller.finish,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              textStyle: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: const Text('Bỏ qua'),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: OnboardingController.slides.length,
                itemBuilder: (_, i) => OnboardingPage(
                  slide: OnboardingController.slides[i],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Obx(() => PageIndicator(
                  count: OnboardingController.slides.length,
                  activeIndex: controller.currentIndex.value,
                )),
            SizedBox(height: 32.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Obx(() => PrimaryButton(
                    label: controller.isLast ? 'BẮT ĐẦU' : 'TIẾP TỤC',
                    icon: controller.isLast ? null : Icons.arrow_forward,
                    onPressed: controller.next,
                  )),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
