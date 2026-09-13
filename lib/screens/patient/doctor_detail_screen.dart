import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_utils.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import 'book_appointment_screen.dart';

class DoctorDetailScreen extends StatelessWidget {
  final AppUser doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                InitialsAvatar(initials: doctor.initials, radius: 34),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${doctor.name}', style: Theme.of(context).textTheme.titleLarge),
                      Text(doctor.specialty, style: const TextStyle(color: AppColors.textSecondary)),
                      if (doctor.department.isNotEmpty)
                        Text(doctor.department, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingStars(rating: doctor.ratingAvg),
                          const SizedBox(width: 6),
                          Text(
                            doctor.ratingCount == 0 ? 'No reviews yet' : '${doctor.ratingAvg.toStringAsFixed(1)} (${doctor.ratingCount} reviews)',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (doctor.bio.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(doctor.bio, style: Theme.of(context).textTheme.bodyLarge),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text('Patient Reviews', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            StreamBuilder<List<Review>>(
              stream: auth.firestoreService.watchDoctorReviews(doctor.uid),
              builder: (context, snapshot) {
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const Text('No reviews yet.', style: TextStyle(color: AppColors.textSecondary));
                }
                return Column(
                  children: reviews
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(timeAgo(r.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                RatingStars(rating: r.stars.toDouble(), size: 14),
                                if (r.comment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r.comment),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'Book Appointment',
            icon: Icons.calendar_month_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctor: doctor)),
            ),
          ),
        ),
      ),
    );
  }
}
