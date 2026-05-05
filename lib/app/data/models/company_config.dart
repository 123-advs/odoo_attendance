/// Company-level GPS check-in configuration.
///
/// Mirrors the 3 fields added by `tcs_attendance_management_product` v1.3
/// on `res.company`. HR sets these on the Odoo web (Settings → Companies
/// → Attendance Anchor tab); the mobile app fetches them once after
/// login and uses them to geofence check-in / check-out.
class CompanyConfig {
  const CompanyConfig({
    required this.anchorLatitude,
    required this.anchorLongitude,
    required this.radiusMeters,
  });

  final double anchorLatitude;
  final double anchorLongitude;
  final double radiusMeters;

  /// HR hasn't filled the anchor when both lat & lng are 0 — real
  /// office coords will never be exactly (0, 0). Radius default (100)
  /// alone isn't enough to consider it configured.
  bool get isConfigured =>
      anchorLatitude != 0 || anchorLongitude != 0;

  factory CompanyConfig.fromJson(Map<String, dynamic> json) {
    return CompanyConfig(
      anchorLatitude: _toDouble(json['attendance_latitude']),
      anchorLongitude: _toDouble(json['attendance_longitude']),
      radiusMeters: _toDouble(json['attendance_radius'], fallback: 100),
    );
  }

  // Odoo returns `false` for un-filled Float fields. Treat as 0.
  static double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null || v == false) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }
}
