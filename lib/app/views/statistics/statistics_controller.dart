import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/attendance_model.dart';
import '../../data/providers/odoo_provider.dart';
import '../profile/profile_controller.dart';

enum StatsPeriod { week, month }

class DailyBar {
  const DailyBar({
    required this.label,
    required this.hours,
    this.late = false,
  });
  final String label;
  final double hours;
  final bool late;
}

class StatisticsController extends GetxController {
  final period = StatsPeriod.week.obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  final records = <AttendanceRecord>[].obs;
  final bars = <DailyBar>[].obs;

  late final ProfileController _profile;
  final _provider = OdooProvider();
  Worker? _employeeWatcher;

  // ── Computed summaries ─────────────────────────────────────────────
  int get totalDays => _distinctDays.length;

  double get totalHours =>
      records.fold(0.0, (sum, r) => sum + r.workedHours);

  String get totalHoursFormatted {
    final h = totalHours.floor();
    final m = ((totalHours - h) * 60).round();
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  int get lateCount => records.where((r) => r.isLate).length;

  List<AttendanceRecord> get recent => records.take(5).toList();

  Set<DateTime> get _distinctDays => records
      .where((r) => r.checkIn != null)
      .map((r) =>
          DateTime(r.checkIn!.year, r.checkIn!.month, r.checkIn!.day))
      .toSet();

  // ── Lifecycle ──────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _profile = Get.find<ProfileController>();
    _employeeWatcher = ever<int?>(_profile.employeeId, (id) {
      if (id != null) loadData();
    });
    if (_profile.employeeId.value != null) loadData();
  }

  @override
  void onClose() {
    _employeeWatcher?.dispose();
    super.onClose();
  }

  void setPeriod(StatsPeriod p) {
    if (period.value == p) return;
    period.value = p;
    loadData();
  }

  Future<void> loadData() async {
    final empId = _profile.employeeId.value;
    if (empId == null || isLoading.value) return;

    isLoading.value = true;
    loadError.value = null;
    try {
      final now = DateTime.now();
      late DateTime from;
      late DateTime to;
      if (period.value == StatsPeriod.week) {
        from = DateTime(now.year, now.month, now.day - 6);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else {
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }

      final fetched = await _provider.fetchAttendances(
        employeeId: empId,
        from: from,
        to: to,
      );
      records.assignAll(fetched);
      bars.assignAll(_buildBars(fetched, now));
    } catch (e, st) {
      debugPrint('[Stats] load failed: $e');
      debugPrintStack(stackTrace: st);
      loadError.value = 'Không tải được dữ liệu chấm công';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────
  List<DailyBar> _buildBars(
      List<AttendanceRecord> recs, DateTime now) {
    // Always show last 7 days from today, regardless of period.
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );
    return days.map((d) {
      var total = 0.0;
      var late = false;
      for (final r in recs) {
        if (r.checkIn != null && _sameDay(r.checkIn!, d)) {
          total += r.workedHours;
          if (r.isLate) late = true;
        }
      }
      return DailyBar(
        label: _vnWeekdayShort(d.weekday),
        hours: total,
        late: late,
      );
    }).toList();
  }

  static String _vnWeekdayShort(int weekday) {
    const labels = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return labels[weekday];
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
