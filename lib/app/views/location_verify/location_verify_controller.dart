import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../core/constants/gps_constants.dart';
import '../../data/models/company_config.dart';
import '../../data/models/location_check.dart';
import '../../services/location_service.dart';
import '../profile/profile_controller.dart';

enum LocationVerifyState {
  initializing,
  fetching,
  withinRadius,
  outsideRadius,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  error,
}

class LocationVerifyController extends GetxController {
  final state = LocationVerifyState.initializing.obs;
  final position = Rxn<Position>();
  final distance = 0.0.obs;
  final errorMessage = RxnString();

  /// 'in' | 'out' — affects title text only. The result returned via
  /// Get.back is identical for both intents.
  String _intent = 'in';
  String get intent => _intent;
  String get title =>
      _intent == 'out' ? 'Xác thực để check-out' : 'Xác thực để chấm công';

  CompanyConfig? _config;
  CompanyConfig? get config => _config;

  bool _disposed = false;

  ProfileController get _profile => Get.find<ProfileController>();

  bool get withinRadius =>
      state.value == LocationVerifyState.withinRadius;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['intent'] is String) {
      _intent = args['intent'] as String;
    }

    final cfg = _profile.companyConfig.value;
    if (cfg == null || !cfg.isConfigured) {
      _fail(
        'Công ty chưa cấu hình tọa độ chấm công. '
        'Liên hệ HR để cập nhật trên Odoo.',
      );
      return;
    }
    _config = cfg;

    fetchLocation();
  }

  Future<void> fetchLocation() async {
    if (_disposed) return;
    state.value = LocationVerifyState.fetching;
    errorMessage.value = null;

    final result = await LocationService.fetchPosition(
      timeout: GpsConstants.fetchTimeout,
    );
    if (_disposed) return;

    switch (result.status) {
      case LocationFetchStatus.success:
        final pos = result.position!;
        position.value = pos;
        final cfg = _config!;
        final d = LocationService.distanceMeters(
          pos.latitude,
          pos.longitude,
          cfg.anchorLatitude,
          cfg.anchorLongitude,
        );
        distance.value = d;
        debugPrint(
          '[LocationVerify] pos=(${pos.latitude}, ${pos.longitude}) '
          'accuracy=${pos.accuracy.toStringAsFixed(1)}m '
          'distance=${d.toStringAsFixed(1)}m '
          'radius=${cfg.radiusMeters}m',
        );
        state.value = d <= cfg.radiusMeters
            ? LocationVerifyState.withinRadius
            : LocationVerifyState.outsideRadius;
        break;

      case LocationFetchStatus.serviceDisabled:
        state.value = LocationVerifyState.serviceDisabled;
        break;
      case LocationFetchStatus.permissionDenied:
        state.value = LocationVerifyState.permissionDenied;
        break;
      case LocationFetchStatus.permissionDeniedForever:
        state.value = LocationVerifyState.permissionDeniedForever;
        break;
      case LocationFetchStatus.timeout:
        state.value = LocationVerifyState.timeout;
        errorMessage.value = result.message;
        break;
      case LocationFetchStatus.error:
        state.value = LocationVerifyState.error;
        errorMessage.value = result.message;
        break;
    }
  }

  void confirm() {
    if (state.value != LocationVerifyState.withinRadius) return;
    final pos = position.value;
    if (pos == null) return;
    Get.back<LocationCheckResult>(
      result: LocationCheckResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyMeters: pos.accuracy,
        distanceMeters: distance.value,
        withinRadius: true,
      ),
    );
  }

  void cancel() {
    Get.back<LocationCheckResult?>();
  }

  Future<void> openLocationSettings() async {
    await LocationService.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await LocationService.openAppSettings();
  }

  void _fail(String message) {
    errorMessage.value = message;
    state.value = LocationVerifyState.error;
  }

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }
}
