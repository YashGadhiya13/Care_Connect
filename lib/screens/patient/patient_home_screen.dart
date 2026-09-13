import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../models/specialty.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/status_chip.dart';
import '../notifications_screen.dart';
import 'appointment_detail_screen.dart';

const Map<String, IconData> specialtyIcons = {
  'General Physician': Icons.local_hospital_outlined,
  'Cardiology': Icons.favorite_outline_rounded,
  'Dermatology': Icons.face_retouching_natural_outlined,
  'Pediatrics': Icons.child_care_outlined,
  'Orthopedics': Icons.accessibility_new_outlined,
  'Dentistry': Icons.medical_information_outlined,
};

/// The Patient's "Home" tab — greeting, quick search, nearest upcoming
/// appointment, and specialty shortcuts. [onFindDoctors] switches the shell
/// to the Doctors tab (used by the search bar and category taps).
class PatientHomeScreen extends StatelessWidget {
  final VoidCallback onFindDoctors;

  const PatientHomeScreen({super.key, required this.onFindDoctors});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final profile = auth.profile;
    final uid = auth.firebaseUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                InitialsAvatar(initials: profile?.initials ?? '?', radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, ${profile?.name.split(' ').first ?? 'there'}', style: Theme.of(context).textTheme.titleLarge),
                      const Text('How are you feeling today?', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: onFindDoctors,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Search doctors, specialties...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (uid != null)
              StreamBuilder<List<Appointment>>(
                stream: auth.firestoreService.watchPatientAppointments(uid),
                builder: (context, snapshot) {
                  final upcoming = (snapshot.data ?? []).where((a) => a.status.isUpcoming).toList()
                    ..sort((a, b) => a.date.compareTo(b.date));
                  if (upcoming.isEmpty) return const SizedBox.shrink();
                  final next = upcoming.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upcoming.length == 1 ? 'You have 1 upcoming appointment' : 'You have ${upcoming.length} upcoming appointments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dr. ${next.doctorName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  Text('${next.timeSlot} • ${next.specialty}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  StatusChip.forAppointmentStatus(next.status.name),
                                ],
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: next))),
                              child: const Text('Details'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            StreamBuilder<List<Specialty>>(
              stream: auth.firestoreService.watchSpecialties(),
              builder: (context, snapshot) {
                final names = (snapshot.data ?? []).map((s) => s.name).toList();
                final list = names.isEmpty ? defaultSpecialties : names;
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.6,
                  children: list.take(6).map((name) => _CategoryTile(name: name, onTap: onFindDoctors)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _CategoryTile({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(specialtyIcons[name] ?? Icons.local_hospital_outlined, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
