import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/attendance_model.dart';
import 'statistics_controller.dart';

class StatisticsView extends GetView<StatisticsController> {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Thống kê',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Obx(() => controller.isLoading.value
                        ? SizedBox(
                            width: 14.r,
                            height: 14.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          )
                        : const SizedBox.shrink()),
                    const Spacer(),
                    Obx(() => _PeriodToggle(
                          value: controller.period.value,
                          onChanged: controller.setPeriod,
                        )),
                  ],
                ),
                Obx(() {
                  final err = controller.loadError.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: _ErrorBanner(message: err),
                  );
                }),
                SizedBox(height: 20.h),
                Obx(() => Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.event_available_rounded,
                            color: AppColors.primary,
                            label: 'Số ngày',
                            value: '${controller.totalDays}',
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.timer_rounded,
                            color: AppColors.accent,
                            label: 'Tổng giờ',
                            value: controller.totalHoursFormatted,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.error,
                            label: 'Đi muộn',
                            value: '${controller.lateCount}',
                          ),
                        ),
                      ],
                    )),
                SizedBox(height: 24.h),
                _ChartCard(controller: controller),
                SizedBox(height: 24.h),
                Text(
                  'Hoạt động gần đây',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Obx(() {
                  final list = controller.recent;
                  if (controller.isLoading.value && list.isEmpty) {
                    return _SkeletonList();
                  }
                  if (list.isEmpty) {
                    return _EmptyState();
                  }
                  return Column(
                    children: list
                        .map((r) => Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: _RecordTile(record: r),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.value, required this.onChanged});
  final StatsPeriod value;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodButton(
            label: 'Tuần',
            selected: value == StatsPeriod.week,
            onTap: () => onChanged(StatsPeriod.week),
          ),
          _PeriodButton(
            label: 'Tháng',
            selected: value == StatsPeriod.month,
            onTap: () => onChanged(StatsPeriod.month),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.controller});
  final StatisticsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Giờ làm 7 ngày qua',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _LegendDot(color: AppColors.primary, label: 'Đủ giờ'),
              SizedBox(width: 12.w),
              _LegendDot(color: AppColors.error, label: 'Muộn'),
            ],
          ),
          SizedBox(height: 20.h),
          Obx(() {
            final bars = controller.bars;
            if (bars.isEmpty) {
              return SizedBox(
                height: 170.h,
                child: const Center(
                  child: Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }
            final maxHours = bars.fold<double>(
              0,
              (m, b) => b.hours > m ? b.hours : m,
            );
            final scale = maxHours == 0 ? 1.0 : maxHours;
            return SizedBox(
              height: 170.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars.map((b) {
                  final ratio = b.hours / scale;
                  final color = b.late
                      ? AppColors.error
                      : AppColors.primary;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            b.hours == 0
                                ? ''
                                : b.hours.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            height: 110.h * ratio,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.6),
                                  color,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            b.label,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final AttendanceRecord record;

  String _humanDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDate = DateTime(d.year, d.month, d.day);
    final diff = today.difference(dDate).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    if (diff < 7) {
      const labels = [
        'Thứ 2',
        'Thứ 3',
        'Thứ 4',
        'Thứ 5',
        'Thứ 6',
        'Thứ 7',
        'Chủ nhật',
      ];
      return labels[d.weekday - 1];
    }
    return DateFormat('dd/MM/yyyy').format(d);
  }

  String _hm(DateTime? d) =>
      d == null ? '--:--' : DateFormat('HH:mm').format(d);

  String _formatHours(double h) {
    if (h == 0) return '—';
    final hours = h.floor();
    final mins = ((h - hours) * 60).round();
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final ci = record.checkIn;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (record.isLate ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(
              record.isLate
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              color: record.isLate ? AppColors.error : AppColors.primary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ci != null ? _humanDate(ci) : '—',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (record.isLate) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Muộn',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (record.checkOut == null) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Đang mở',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_hm(record.checkIn)} → ${_hm(record.checkOut)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatHours(record.workedHours),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 36.sp,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8.h),
          Text(
            'Chưa có dữ liệu chấm công',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Khi bạn chấm công, lịch sử sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Container(
            height: 64.h,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.divider),
            ),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.divider,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 10.h,
                          width: 100.w,
                          color: AppColors.divider,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          height: 8.h,
                          width: 140.w,
                          color: AppColors.divider,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: AppColors.warning, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
