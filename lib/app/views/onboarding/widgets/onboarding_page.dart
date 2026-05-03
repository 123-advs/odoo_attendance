import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_colors.dart';
import '../onboarding_controller.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          Center(
            child: SizedBox(
              height: 280.h,
              child: Lottie.asset(
                slide.lottieAsset,
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          ),
          SizedBox(height: 40.h),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            slide.body,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
