import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';

class SplashController extends GetxController {
  Timer? _decideTimer;
  bool _disposed = false;

  @override
  void onReady() {
    super.onReady();
    _decideTimer = Timer(const Duration(milliseconds: 400), _decide);
  }

  Future<void> _decide() async {
    if (_disposed) return;
    debugPrint('[Splash] _decide() started');
    try {
      final storage = Get.find<StorageService>();

      if (!storage.onboardingSeen) {
        debugPrint('[Splash] onboardingSeen=false -> /onboarding');
        if (!_disposed) Get.offAllNamed(AppRoutes.onboarding);
        return;
      }

      String? session;
      try {
        session = await storage.readSessionId().timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                debugPrint('[Splash] readSessionId TIMEOUT after 3s');
                return null;
              },
            );
      } catch (e, st) {
        debugPrint('[Splash] readSessionId FAILED: $e');
        debugPrintStack(stackTrace: st);
        session = null;
      }

      if (_disposed) return;
      if (session != null && session.isNotEmpty) {
        debugPrint('[Splash] session present -> /home');
        Get.offAllNamed(AppRoutes.home);
      } else {
        debugPrint('[Splash] no session -> /login');
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e, st) {
      debugPrint('[Splash] UNCAUGHT in _decide: $e');
      debugPrintStack(stackTrace: st);
      if (!_disposed) Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    _disposed = true;
    _decideTimer?.cancel();
    super.onClose();
  }
}
