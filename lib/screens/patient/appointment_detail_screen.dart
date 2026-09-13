import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/appointment.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/status_chip.dart';
import 'book_appointment_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final appt = appointment;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Dr. ${appt.doctorName}', style: Theme.of(context).textTheme.titleLarge),
                ),
                StatusChip.forAppointmentStatus(appt.status.name),
              ],
            ),
            Text(appt.specialty, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _infoRow(Icons.calendar_today_outlined, '${appt.date.day}/${appt.date.month}/${appt.date.year}'),
            const SizedBox(height: 10),
            _infoRow(Icons.access_time_rounded, appt.timeSlot),
            if (appt.reason.isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(Icons.notes_rounded, appt.reason),
            ],
            if (appt.status == AppointmentStatus.completed) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text('Consultation Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                appt.consultationNotes.isEmpty ? 'No notes added.' : appt.consultationNotes,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text('Prescription', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                appt.prescription.isEmpty ? 'No prescription added.' : appt.prescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              if (!appt.reviewed)
                PrimaryButton(
                  label: 'Rate & Review',
                  icon: Icons.star_outline_rounded,
                  onPressed: () => _showReviewDialog(context, auth),
                )
              else
                const Text('You already reviewed this appointment.', style: TextStyle(color: AppColors.textSecondary)),
            ],
            if (appt.status.isUpcoming) ...[
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Reschedule',
                icon: Icons.edit_calendar_outlined,
                outlined: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookAppointmentScreen(
                      doctor: AppUser(uid: appt.doctorId, name: appt.doctorName, email: '', specialty: appt.specialty),
                      existingAppointment: appt,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Cancel Appointment',
                icon: Icons.cancel_outlined,
                onPressed: () => _confirmCancel(context, auth),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context, AppAuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirmed != true) return;

    await auth.firestoreService.updateAppointmentStatus(appointment.id, AppointmentStatus.cancelled);
    await auth.firestoreService.sendNotification(
      appointment.doctorId,
      title: 'Appointment cancelled',
      body: '${appointment.patientName} cancelled their ${appointment.timeSlot} appointment.',
    );
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _showReviewDialog(BuildContext context, AppAuthProvider auth) async {
    int stars = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Rate your doctor'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RatingStarsInput(value: stars, onChanged: (v) => setState(() => stars = v)),
                const SizedBox(height: 8),
                AppTextField(controller: commentController, label: 'Comment (optional)', maxLines: 3),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  final patient = auth.profile;
                  if (patient == null) return;
                  await auth.firestoreService.addReview(Review(
                    id: '',
                    doctorId: appointment.doctorId,
                    patientId: patient.uid,
                    patientName: patient.name,
                    appointmentId: appointment.id,
                    stars: stars,
                    comment: commentController.text.trim(),
                  ));
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}
