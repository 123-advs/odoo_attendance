import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.lottieAsset,
    required this.title,
    required this.body,
  });

  final String lottieAsset;
  final String title;
  final String body;
}

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentIndex = 0.obs;

  static const slides = <OnboardingSlide>[
    OnboardingSlide(
      lottieAsset: 'assets/lottie/face_scan.json',
      title: 'Chấm công bằng khuôn mặt',
      body:
          'Chỉ cần nhìn vào camera, hệ thống tự động xác thực và ghi nhận giờ làm trong vài giây.',
    ),
    OnboardingSlide(
      lottieAsset: 'assets/lottie/location_pin.json',
      title: 'Xác thực vị trí',
      body:
          'GPS xác nhận bạn đang ở đúng địa điểm làm việc khi check-in / check-out.',
    ),
    OnboardingSlide(
      lottieAsset: 'assets/lottie/history_clock.json',
      title: 'Lịch sử chấm công minh bạch',
      body:
          'Xem báo cáo theo ngày, tuần, tháng. Đồng bộ trực tiếp về Odoo.',
    ),
  ];

  bool get isLast => currentIndex.value == slides.length - 1;

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  void next() {
    if (isLast) {
      finish();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> finish() async {
    await Get.find<StorageService>().setOnboardingSeen();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
