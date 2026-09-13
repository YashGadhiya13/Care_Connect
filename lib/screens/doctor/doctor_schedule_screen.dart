import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import '../notifications_screen.dart';
import 'doctor_appointment_detail_screen.dart';

/// Shows the doctor's upcoming (pending/accepted) appointments when
/// [showHistory] is false, or past (completed/rejected/cancelled) ones when
/// true — used for both the "Schedule" and "History" tabs.
class DoctorScheduleScreen extends StatelessWidget {
  final bool showHistory;

  const DoctorScheduleScreen({super.key, this.showHistory = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(showHistory ? 'Appointment History' : 'My Schedule'),
        actions: showHistory
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
              ],
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: auth.firestoreService.watchDoctorAppointments(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final appointments = all.where((a) => a.status.isUpcoming != showHistory).toList();
          if (!showHistory) {
            // Pending requests need action first, then soonest accepted visits.
            appointments.sort((a, b) {
              if (a.status != b.status) return a.status == AppointmentStatus.pending ? -1 : 1;
              return a.date.compareTo(b.date);
            });
          }

          if (appointments.isEmpty) {
            return EmptyState(
              icon: showHistory ? Icons.history_rounded : Icons.event_available_outlined,
              title: showHistory ? 'No history yet' : 'No appointments yet',
              message: showHistory ? 'Completed visits will show up here.' : 'New requests from patients will show up here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final appt = appointments[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DoctorAppointmentDetailScreen(appointment: appt)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.w700))),
                            StatusChip.forAppointmentStatus(appt.status.name),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(appt.specialty, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('${appt.date.day}/${appt.date.month}/${appt.date.year}  •  ${appt.timeSlot}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
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
