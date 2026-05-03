class AttendanceState {
  const AttendanceState({
    required this.state,
    this.lastId,
    this.checkIn,
    this.checkOut,
  });

  final String state; // 'checked_in' | 'checked_out'
  final int? lastId;
  final DateTime? checkIn; // local time
  final DateTime? checkOut; // local time

  bool get isCheckedIn => state == 'checked_in';

  static const empty = AttendanceState(state: 'checked_out');
}

/// One row of `hr.attendance` for the current employee. Used by Statistics tab.
class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    this.checkIn,
    this.checkOut,
    this.workedHours = 0,
  });

  final int id;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double workedHours;

  /// Configurable late threshold. Default: any check-in after 09:00 local time.
  bool isLateAfter({int hour = 9, int minute = 0}) {
    final ci = checkIn;
    if (ci == null) return false;
    if (ci.hour > hour) return true;
    if (ci.hour == hour && ci.minute > minute) return true;
    return false;
  }

  bool get isLate => isLateAfter();

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: (json['id'] as num).toInt(),
      checkIn: parseOdooDateTime(json['check_in']),
      checkOut: parseOdooDateTime(json['check_out']),
      workedHours: ((json['worked_hours'] as num?) ?? 0).toDouble(),
    );
  }
}

/// Odoo stores datetimes as 'YYYY-MM-DD HH:MM:SS' in UTC, no TZ marker.
DateTime? parseOdooDateTime(dynamic value) {
  if (value == null || value == false) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  try {
    return DateTime.parse('${s.replaceAll(' ', 'T')}Z').toLocal();
  } catch (_) {
    return null;
  }
}

/// Format a local DateTime as Odoo expects: 'YYYY-MM-DD HH:MM:SS' UTC.
String formatOdooDateTime(DateTime localOrUtc) {
  final utc = localOrUtc.toUtc();
  String pad2(int v) => v.toString().padLeft(2, '0');
  return '${utc.year}-${pad2(utc.month)}-${pad2(utc.day)} '
      '${pad2(utc.hour)}:${pad2(utc.minute)}:${pad2(utc.second)}';
}
