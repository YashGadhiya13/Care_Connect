import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import 'admin_feedback_screen.dart';
import 'admin_send_notification_screen.dart';
import 'admin_specialties_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Safe to call every time — it's a no-op once specialties already exist.
    context.read<AppAuthProvider>().firestoreService.seedSpecialtiesIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            StreamBuilder<List<AppUser>>(
              stream: auth.firestoreService.watchAllDoctors(),
              builder: (context, doctorSnap) {
                final doctors = doctorSnap.data ?? [];
                final pending = doctors.where((d) => d.doctorStatus == DoctorStatus.pending).length;
                return StreamBuilder<List<AppUser>>(
                  stream: auth.firestoreService.watchAllPatients(),
                  builder: (context, patientSnap) {
                    final patients = patientSnap.data ?? [];
                    return StreamBuilder<List<Appointment>>(
                      stream: auth.firestoreService.watchAllAppointments(),
                      builder: (context, apptSnap) {
                        final appointments = apptSnap.data ?? [];
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            StatCard(label: 'Patients', value: '${patients.length}', icon: Icons.people_outline_rounded),
                            StatCard(label: 'Doctors', value: '${doctors.length}', icon: Icons.medical_services_outlined, color: AppColors.success),
                            StatCard(label: 'Appointments', value: '${appointments.length}', icon: Icons.event_note_outlined, color: AppColors.accent),
                            StatCard(label: 'Pending Approvals', value: '$pending', icon: Icons.hourglass_top_rounded, color: AppColors.warning),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 28),
            Text('Manage', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.category_outlined,
              label: 'Specialties & Departments',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSpecialtiesScreen())),
            ),
            _NavTile(
              icon: Icons.campaign_outlined,
              label: 'Send Notification',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSendNotificationScreen())),
            ),
            _NavTile(
              icon: Icons.reviews_outlined,
              label: 'Feedback & Ratings',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminFeedbackScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
