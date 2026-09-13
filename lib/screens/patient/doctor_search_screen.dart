import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/specialty.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/rating_stars.dart';
import '../notifications_screen.dart';
import 'doctor_detail_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  String? _specialtyFilter;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Doctor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: StreamBuilder<List<Specialty>>(
              stream: auth.firestoreService.watchSpecialties(),
              builder: (context, snapshot) {
                final specialties = snapshot.data ?? [];
                final names = specialties.isEmpty ? defaultSpecialties : specialties.map((s) => s.name).toList();
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip('All', _specialtyFilter == null, () => setState(() => _specialtyFilter = null)),
                    const SizedBox(width: 8),
                    ...names.map(
                      (name) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _filterChip(name, _specialtyFilter == name, () => setState(() => _specialtyFilter = name)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: auth.firestoreService.watchApprovedDoctors(specialty: _specialtyFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final doctors = snapshot.data ?? [];
                if (doctors.isEmpty) {
                  return const EmptyState(
                    icon: Icons.medical_services_outlined,
                    title: 'No doctors available',
                    message: 'Check back soon, or try a different specialty.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: doctors.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doctor = doctors[i];
                    return _DoctorCard(doctor: doctor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _DoctorCard extends StatelessWidget {
  final AppUser doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              InitialsAvatar(initials: doctor.initials, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${doctor.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(doctor.specialty, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingStars(rating: doctor.ratingAvg),
                        const SizedBox(width: 6),
                        Text(
                          doctor.ratingCount == 0 ? 'No reviews yet' : '${doctor.ratingAvg.toStringAsFixed(1)} (${doctor.ratingCount})',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
