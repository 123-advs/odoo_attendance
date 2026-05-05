/// Output of the location verify screen, returned via `Get.back` to
/// `HomeController.onCheckInPressed` for forwarding to Odoo as
/// `in_latitude` / `in_longitude` (or out_*) on `hr.attendance`.
class LocationCheckResult {
  const LocationCheckResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.distanceMeters,
    required this.withinRadius,
  });

  final double latitude;
  final double longitude;

  /// GPS accuracy radius reported by the OS (meters). Lower = better.
  final double accuracyMeters;

  /// Distance from the company anchor at the moment of capture.
  final double distanceMeters;

  /// `distance <= companyConfig.radius` at capture time.
  final bool withinRadius;
}
