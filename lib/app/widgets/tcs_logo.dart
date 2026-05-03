import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_colors.dart';

class TcsLogo extends StatelessWidget {
  const TcsLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dim = size.r;
    final radius = dim * 0.18;
    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/icon.png',
          width: dim,
          height: dim,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
