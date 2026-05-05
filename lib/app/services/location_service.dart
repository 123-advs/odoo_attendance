import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationFetchStatus {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  success,
  timeout,
  error,
}

class LocationFetchResult {
  const LocationFetchResult({
    required this.status,
    this.position,
    this.message,
  });

  final LocationFetchStatus status;
  final Position? position;
  final String? message;

  bool get isSuccess =>
      status == LocationFetchStatus.success && position != null;
}

/// Static helpers around `geolocator` for the location-verify flow.
/// Caller owns lifecycle — this class is stateless.
class LocationService {
  LocationService._();

  /// Try to get a fresh GPS reading. Walks the standard preflight:
  /// service-on → permission-granted → high-accuracy reading. Each
  /// failure mode maps to a distinct [LocationFetchStatus] so the UI
  /// can show the right "Open settings" CTA.
  static Future<LocationFetchResult> fetchPosition({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        return const LocationFetchResult(
          status: LocationFetchStatus.serviceDisabled,
        );
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        return const LocationFetchResult(
          status: LocationFetchStatus.permissionDeniedForever,
        );
      }
      if (perm == LocationPermission.denied) {
        return const LocationFetchResult(
          status: LocationFetchStatus.permissionDenied,
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return LocationFetchResult(
        status: LocationFetchStatus.success,
        position: pos,
      );
    } on TimeoutException {
      return const LocationFetchResult(
        status: LocationFetchStatus.timeout,
        message: 'Hết thời gian chờ tín hiệu GPS.',
      );
    } catch (e, st) {
      debugPrint('[LocationService] fetchPosition failed: $e');
      debugPrintStack(stackTrace: st);
      return LocationFetchResult(
        status: LocationFetchStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Haversine distance in meters between two coordinates.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  /// Forward to system Settings → Location so user can flip the GPS
  /// toggle. Used when [LocationFetchStatus.serviceDisabled].
  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  /// Forward to system Settings → App → Permissions for the case where
  /// user has permanently denied location.
  static Future<bool> openAppSettings() =>
      Geolocator.openAppSettings();
}
