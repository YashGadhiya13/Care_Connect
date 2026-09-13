import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/appointment.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

const List<String> availableTimeSlots = [
  '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
  '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
];

/// Books a new appointment with [doctor], or — when [existingAppointment] is
/// passed — reschedules it (keeps the same doctor, updates date/time and
/// resets status to pending so the doctor re-confirms).
class BookAppointmentScreen extends StatefulWidget {
  final AppUser doctor;
  final Appointment? existingAppointment;

  const BookAppointmentScreen({super.key, required this.doctor, this.existingAppointment});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _reasonController = TextEditingController();
  DateTime? _date;
  String? _timeSlot;
  bool _loading = false;

  bool get _isReschedule => widget.existingAppointment != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAppointment;
    if (existing != null) {
      _date = existing.date;
      _timeSlot = existing.timeSlot;
      _reasonController.text = existing.reason;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_date == null || _timeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a date and time')));
      return;
    }
    final auth = context.read<AppAuthProvider>();
    final patient = auth.profile;
    final uid = auth.firebaseUser?.uid;
    if (patient == null || uid == null) return;

    setState(() => _loading = true);
    try {
      if (_isReschedule) {
        final appt = widget.existingAppointment!;
        await auth.firestoreService.rescheduleAppointment(appt.id, date: _date!, timeSlot: _timeSlot!);
        await auth.firestoreService.sendNotification(
          appt.doctorId,
          title: 'Appointment rescheduled',
          body: '${patient.name} moved their appointment to ${_timeSlot!} on ${_formatDate(_date!)}.',
        );
      } else {
        final appointment = Appointment(
          id: '',
          patientId: uid,
          patientName: patient.name,
          doctorId: widget.doctor.uid,
          doctorName: widget.doctor.name,
          specialty: widget.doctor.specialty,
          date: _date!,
          timeSlot: _timeSlot!,
          reason: _reasonController.text.trim(),
          status: AppointmentStatus.pending,
        );
        await auth.firestoreService.createAppointment(appointment);
        await auth.firestoreService.sendNotification(
          widget.doctor.uid,
          title: 'New appointment request',
          body: '${patient.name} requested ${_timeSlot!} on ${_formatDate(_date!)}.',
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isReschedule ? 'Reschedule Appointment' : 'Book Appointment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Dr. ${widget.doctor.name}', style: Theme.of(context).textTheme.titleLarge),
            Text(widget.doctor.specialty, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Text('Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    Text(_date == null ? 'Select a date' : _formatDate(_date!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTimeSlots
                  .map((slot) => ChoiceChip(
                        label: Text(slot),
                        selected: _timeSlot == slot,
                        onSelected: (_) => setState(() => _timeSlot = slot),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _reasonController,
              label: 'Reason for visit (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: _isReschedule ? 'Save Changes' : 'Confirm Booking',
              onPressed: _submit,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
