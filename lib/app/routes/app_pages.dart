import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../views/change_password/change_password_controller.dart';
import '../views/change_password/change_password_view.dart';
import '../views/face_capture/face_capture_controller.dart';
import '../views/face_capture/face_capture_view.dart';
import '../views/face_enroll/face_enroll_controller.dart';
import '../views/face_enroll/face_enroll_view.dart';
import '../views/login/login_controller.dart';
import '../views/login/login_view.dart';
import '../views/main/main_controller.dart';
import '../views/main/main_view.dart';
import '../views/onboarding/onboarding_controller.dart';
import '../views/onboarding/onboarding_view.dart';
import '../views/personal_info/personal_info_controller.dart';
import '../views/personal_info/personal_info_view.dart';
import '../views/profile/profile_controller.dart';
import '../views/splash/splash_controller.dart';
import '../views/splash/splash_view.dart';
import '../views/statistics/statistics_controller.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OnboardingController());
      }),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoginController());
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainView(),
      binding: BindingsBuilder(() {
        Get.put(MainController());
        Get.put(ProfileController()); // must come before HomeController (it Get.finds Profile)
        Get.put(HomeController());
        Get.put(StatisticsController());
      }),
    ),
    GetPage(
      name: AppRoutes.personalInfo,
      page: () => const PersonalInfoView(),
      binding: BindingsBuilder(() {
        Get.put(PersonalInfoController());
      }),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
      binding: BindingsBuilder(() {
        Get.put(ChangePasswordController());
      }),
    ),
    GetPage(
      name: AppRoutes.faceEnroll,
      page: () => const FaceEnrollView(),
      binding: BindingsBuilder(() {
        Get.put(FaceEnrollController());
      }),
    ),
    GetPage(
      name: AppRoutes.faceCapture,
      page: () => const FaceCaptureView(),
      binding: BindingsBuilder(() {
        Get.put(FaceCaptureController());
      }),
    ),
  ];
}
