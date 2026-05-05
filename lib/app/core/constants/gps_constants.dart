class GpsConstants {
  GpsConstants._();

  /// Max wait for the OS to deliver a fresh GPS reading. Cold start
  /// (first fix in a building or indoors) can be 8–10s, so 12s gives a
  /// little margin without leaving the user staring at a spinner.
  static const Duration fetchTimeout = Duration(seconds: 12);

  /// Map zoom level. 15 ≈ neighborhood, 17 ≈ street, 19 ≈ building.
  static const double mapZoom = 17;

  /// Identify ourselves to OpenStreetMap tile server (their usage
  /// policy expects a meaningful User-Agent / package name).
  static const String osmUserAgent = 'com.tcs.odoo_attendance';

  /// OSM tile URL template — free, no API key. For prod scale, switch
  /// to a self-hosted tile server or a paid provider (Mapbox / Carto).
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
