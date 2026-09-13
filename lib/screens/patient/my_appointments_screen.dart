import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import 'appointment_detail_screen.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Appointments'),
          bottom: const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'Previous')]),
        ),
        body: StreamBuilder<List<Appointment>>(
          stream: auth.firestoreService.watchPatientAppointments(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data ?? [];
            final upcoming = all.where((a) => a.status.isUpcoming).toList();
            final previous = all.where((a) => !a.status.isUpcoming).toList();

            return TabBarView(
              children: [
                _AppointmentList(appointments: upcoming, emptyMessage: 'No upcoming appointments.'),
                _AppointmentList(appointments: previous, emptyMessage: 'No past appointments yet.'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<Appointment> appointments;
  final String emptyMessage;

  const _AppointmentList({required this.appointments, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return EmptyState(icon: Icons.event_note_outlined, title: 'Nothing here yet', message: emptyMessage);
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
              MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: appt)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('Dr. ${appt.doctorName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
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
  }
}
