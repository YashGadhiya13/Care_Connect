import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Read-only star display, e.g. for a doctor's average rating.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: filled ? AppColors.accent : AppColors.border,
        );
      }),
    );
  }
}

/// Tappable star picker, e.g. for submitting a review.
class RatingStarsInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const RatingStarsInput({super.key, required this.value, required this.onChanged, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        return IconButton(
          onPressed: () => onChanged(starIndex),
          icon: Icon(
            starIndex <= value ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: AppColors.accent,
          ),
        );
      }),
    );
  }
}
