import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';

class DoctorAppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const DoctorAppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<DoctorAppointmentDetailScreen> createState() => _DoctorAppointmentDetailScreenState();
}

class _DoctorAppointmentDetailScreenState extends State<DoctorAppointmentDetailScreen> {
  late final TextEditingController _notesController;
  late final TextEditingController _prescriptionController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.appointment.consultationNotes);
    _prescriptionController = TextEditingController(text: widget.appointment.prescription);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _respond(AppointmentStatus status) async {
    final auth = context.read<AppAuthProvider>();
    final appt = widget.appointment;
    setState(() => _loading = true);
    try {
      await auth.firestoreService.updateAppointmentStatus(appt.id, status);
      await auth.firestoreService.sendNotification(
        appt.patientId,
        title: status == AppointmentStatus.accepted ? 'Appointment accepted' : 'Appointment update',
        body: 'Dr. ${appt.doctorName} ${status == AppointmentStatus.accepted ? 'accepted' : status.label.toLowerCase()} your ${appt.timeSlot} appointment.',
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    final auth = context.read<AppAuthProvider>();
    final appt = widget.appointment;
    setState(() => _loading = true);
    try {
      await auth.firestoreService.addConsultationNotes(
        appt.id,
        notes: _notesController.text,
        prescription: _prescriptionController.text,
      );
      await auth.firestoreService.updateAppointmentStatus(appt.id, AppointmentStatus.completed);
      await auth.firestoreService.sendNotification(
        appt.patientId,
        title: 'Appointment completed',
        body: 'Dr. ${appt.doctorName} added consultation notes for your visit.',
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(appt.patientName, style: Theme.of(context).textTheme.titleLarge)),
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            if (appt.status == AppointmentStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Accept',
                      loading: _loading,
                      onPressed: () => _respond(AppointmentStatus.accepted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Reject',
                      outlined: true,
                      loading: _loading,
                      onPressed: () => _respond(AppointmentStatus.rejected),
                    ),
                  ),
                ],
              ),
            ] else if (appt.status == AppointmentStatus.accepted) ...[
              Text('Consultation Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AppTextField(controller: _notesController, label: 'Notes', maxLines: 4),
              const SizedBox(height: 16),
              Text('Prescription', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AppTextField(controller: _prescriptionController, label: 'Medicines, dosage, instructions', maxLines: 4),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Mark as Completed', loading: _loading, onPressed: _complete),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Cancel Appointment',
                outlined: true,
                loading: _loading,
                onPressed: () => _respond(AppointmentStatus.cancelled),
              ),
            ] else ...[
              Text('Consultation Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(appt.consultationNotes.isEmpty ? 'No notes added.' : appt.consultationNotes),
              const SizedBox(height: 16),
              Text('Prescription', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(appt.prescription.isEmpty ? 'No prescription added.' : appt.prescription),
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
}
