import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small colored pill for appointment/doctor status labels.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.forAppointmentStatus(String statusName) {
    switch (statusName) {
      case 'accepted':
        return StatusChip(label: 'Accepted', color: AppColors.primary);
      case 'completed':
        return StatusChip(label: 'Completed', color: AppColors.success);
      case 'rejected':
        return StatusChip(label: 'Rejected', color: AppColors.danger);
      case 'cancelled':
        return StatusChip(label: 'Cancelled', color: AppColors.textSecondary);
      case 'pending':
      default:
        return StatusChip(label: 'Pending', color: AppColors.warning);
    }
  }

  factory StatusChip.forDoctorStatus(String statusName) {
    switch (statusName) {
      case 'approved':
        return StatusChip(label: 'Approved', color: AppColors.success);
      case 'rejected':
        return StatusChip(label: 'Not Approved', color: AppColors.danger);
      case 'pending':
      default:
        return StatusChip(label: 'Pending', color: AppColors.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
