import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/status_chip.dart';

class AdminDoctorsScreen extends StatelessWidget {
  const AdminDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Doctors')),
      body: StreamBuilder<List<AppUser>>(
        stream: auth.firestoreService.watchAllDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final doctors = snapshot.data ?? [];
          if (doctors.isEmpty) {
            return const EmptyState(
              icon: Icons.medical_services_outlined,
              title: 'No doctors yet',
              message: 'Doctor sign-ups will appear here for approval.',
            );
          }
          // Pending registrations need attention first.
          final sorted = List.of(doctors)
            ..sort((a, b) => a.doctorStatus == b.doctorStatus ? 0 : (a.doctorStatus == DoctorStatus.pending ? -1 : 1));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doctor = sorted[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InitialsAvatar(initials: doctor.initials),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dr. ${doctor.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(doctor.specialty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                          StatusChip.forDoctorStatus(doctor.doctorStatus.name),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(doctor.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      if (doctor.ratingCount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            RatingStars(rating: doctor.ratingAvg, size: 14),
                            const SizedBox(width: 6),
                            Text('${doctor.ratingAvg.toStringAsFixed(1)} (${doctor.ratingCount})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                      if (doctor.doctorStatus == DoctorStatus.pending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => auth.firestoreService.setDoctorStatus(doctor.uid, DoctorStatus.approved),
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => auth.firestoreService.setDoctorStatus(doctor.uid, DoctorStatus.rejected),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ] else if (doctor.doctorStatus == DoctorStatus.approved) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.block_outlined, size: 18),
                            label: const Text('Suspend'),
                            onPressed: () => auth.firestoreService.setDoctorStatus(doctor.uid, DoctorStatus.rejected),
                          ),
                        ),
                      ] else if (doctor.doctorStatus == DoctorStatus.rejected) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text('Reactivate'),
                            onPressed: () => auth.firestoreService.setDoctorStatus(doctor.uid, DoctorStatus.approved),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
