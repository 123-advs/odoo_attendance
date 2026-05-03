import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_view.dart';
import '../profile/profile_view.dart';
import '../statistics/statistics_view.dart';
import 'main_controller.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: const [
              HomeView(),
              StatisticsView(),
              ProfileView(),
            ],
          )),
      bottomNavigationBar: Obx(() => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: controller.currentIndex.value,
                onDestinationSelected: controller.changeTab,
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                indicatorColor: AppColors.primary.withValues(alpha: 0.12),
                height: 68.h,
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  _destination(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Trang chủ',
                  ),
                  _destination(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart_rounded,
                    label: 'Thống kê',
                  ),
                  _destination(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person_rounded,
                    label: 'Tài khoản',
                  ),
                ],
              ),
            ),
          )),
    );
  }

  NavigationDestination _destination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textMuted),
      selectedIcon: Icon(selectedIcon, color: AppColors.primary),
      label: label,
    );
  }
}
