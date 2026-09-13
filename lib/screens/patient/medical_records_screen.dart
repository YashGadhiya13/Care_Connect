import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'appointment_detail_screen.dart';

/// Read-only history of completed visits — consultation notes and
/// prescriptions from past appointments.
class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Records')),
      body: StreamBuilder<List<Appointment>>(
        stream: auth.firestoreService.watchPatientAppointments(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = (snapshot.data ?? []).where((a) => a.status == AppointmentStatus.completed).toList();
          if (records.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_shared_outlined,
              title: 'No records yet',
              message: 'Notes and prescriptions from completed visits will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final record = records[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: record))),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                          child: const Icon(Icons.description_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dr. ${record.doctorName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(record.specialty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${record.date.day}/${record.date.month}/${record.date.year}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
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
