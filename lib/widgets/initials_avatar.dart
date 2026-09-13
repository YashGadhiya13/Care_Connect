import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A circular avatar with a soft brand-color gradient and the person's
/// initials — used everywhere we don't have a real profile photo.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double radius;

  const InitialsAvatar({super.key, required this.initials, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.65),
      ),
    );
  }
}
