import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/gps_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'location_verify_controller.dart';

class LocationVerifyView extends GetView<LocationVerifyController> {
  const LocationVerifyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: controller.cancel,
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textPrimary,
        ),
        title: Text(
          controller.title,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _MapPanel(controller: controller)),
            _BottomPanel(controller: controller),
          ],
        ),
      ),
    );
  }
}

// ─── Map ────────────────────────────────────────────────────────────

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.controller});
  final LocationVerifyController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cfg = controller.config;
      if (cfg == null) {
        return const SizedBox.shrink();
      }
      final anchor = LatLng(cfg.anchorLatitude, cfg.anchorLongitude);
      final pos = controller.position.value;
      final user =
          pos != null ? LatLng(pos.latitude, pos.longitude) : null;

      return Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: user ?? anchor,
              initialZoom: GpsConstants.mapZoom,
              minZoom: 4,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: GpsConstants.osmTileUrl,
                userAgentPackageName: GpsConstants.osmUserAgent,
                tileProvider: NetworkTileProvider(),
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: anchor,
                    radius: cfg.radiusMeters,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderColor:
                        AppColors.primary.withValues(alpha: 0.7),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: anchor,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const _AnchorPin(),
                  ),
                  if (user != null)
                    Marker(
                      point: user,
                      width: 24,
                      height: 24,
                      child: const _UserDot(),
                    ),
                ],
              ),
            ],
          ),
          // Loading overlay while fetching first position
          if (controller.state.value == LocationVerifyState.fetching ||
              controller.state.value ==
                  LocationVerifyState.initializing)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14.r,
                        height: 14.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Đang lấy vị trí...',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _AnchorPin extends StatelessWidget {
  const _AnchorPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Icon(Icons.location_on_rounded, color: AppColors.error, size: 44.sp),
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Container(
            width: 8.r,
            height: 8.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom panel ───────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.controller});
  final LocationVerifyController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      child: Obx(() {
        final s = controller.state.value;
        final cfg = controller.config;

        switch (s) {
          case LocationVerifyState.serviceDisabled:
            return _ErrorPanel(
              icon: Icons.location_off_rounded,
              title: 'Dịch vụ định vị đã tắt',
              message:
                  'Bật GPS trong cài đặt hệ thống để chấm công bằng vị trí.',
              primaryLabel: 'MỞ CÀI ĐẶT GPS',
              onPrimary: controller.openLocationSettings,
              onSecondary: controller.fetchLocation,
            );
          case LocationVerifyState.permissionDenied:
            return _ErrorPanel(
              icon: Icons.gps_off_rounded,
              title: 'Cần cấp quyền vị trí',
              message:
                  'Vui lòng cho phép app truy cập vị trí để xác thực chấm công.',
              primaryLabel: 'THỬ LẠI',
              onPrimary: controller.fetchLocation,
            );
          case LocationVerifyState.permissionDeniedForever:
            return _ErrorPanel(
              icon: Icons.no_accounts_rounded,
              title: 'Quyền vị trí đã bị từ chối',
              message:
                  'Vào cài đặt ứng dụng và bật lại quyền vị trí cho app.',
              primaryLabel: 'MỞ CÀI ĐẶT APP',
              onPrimary: controller.openAppSettings,
            );
          case LocationVerifyState.timeout:
          case LocationVerifyState.error:
            return _ErrorPanel(
              icon: Icons.error_outline_rounded,
              title: s == LocationVerifyState.timeout
                  ? 'Hết thời gian chờ GPS'
                  : 'Có lỗi khi lấy vị trí',
              message: controller.errorMessage.value ??
                  'Vui lòng thử lại sau ít giây.',
              primaryLabel: 'THỬ LẠI',
              onPrimary: controller.fetchLocation,
            );
          case LocationVerifyState.initializing:
          case LocationVerifyState.fetching:
          case LocationVerifyState.withinRadius:
          case LocationVerifyState.outsideRadius:
            return _StatusPanel(controller: controller, config: cfg);
        }
      }),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.controller, required this.config});
  final LocationVerifyController controller;
  final dynamic config; // CompanyConfig?

  @override
  Widget build(BuildContext context) {
    final s = controller.state.value;
    final fetching = s == LocationVerifyState.fetching ||
        s == LocationVerifyState.initializing;
    final ok = s == LocationVerifyState.withinRadius;
    final hasReading = controller.position.value != null;

    final distanceText = hasReading
        ? '${controller.distance.value.toStringAsFixed(0)} m'
        : '--';
    final radiusText = config?.radiusMeters != null
        ? '${(config.radiusMeters as double).toStringAsFixed(0)} m'
        : '—';
    final accuracyText = hasReading
        ? '±${controller.position.value!.accuracy.toStringAsFixed(0)} m'
        : '';

    final accentColor = ok
        ? AppColors.primary
        : (s == LocationVerifyState.outsideRadius
            ? AppColors.error
            : AppColors.textMuted);
    final statusText = fetching
        ? 'Đang xác định vị trí...'
        : (ok
            ? 'Trong phạm vi'
            : (s == LocationVerifyState.outsideRadius
                ? 'Ngoài phạm vi cho phép'
                : '—'));
    final statusIcon = fetching
        ? Icons.gps_fixed_rounded
        : (ok ? Icons.check_circle_rounded : Icons.cancel_rounded);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: accentColor, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (accuracyText.isNotEmpty)
              Text(
                'Độ chính xác $accuracyText',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              distanceText,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '/ $radiusText',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: fetching ? null : controller.fetchLocation,
              icon: Icon(
                Icons.refresh_rounded,
                color: fetching
                    ? AppColors.textMuted
                    : AppColors.primary,
                size: 26.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'Khoảng cách tới văn phòng / bán kính cho phép',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: 16.h),
        PrimaryButton(
          label: ok ? 'XÁC NHẬN CHẤM CÔNG' : 'CẦN VÀO PHẠM VI',
          isLoading: fetching,
          icon: ok ? Icons.check_rounded : null,
          onPressed: ok ? controller.confirm : null,
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.error, size: 28.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          message,
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16.h),
        PrimaryButton(
          label: primaryLabel,
          onPressed: onPrimary,
        ),
        if (onSecondary != null) ...[
          SizedBox(height: 8.h),
          Center(
            child: TextButton(
              onPressed: onSecondary,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                'Thử lại',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
