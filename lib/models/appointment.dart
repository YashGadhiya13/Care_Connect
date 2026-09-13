import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { pending, accepted, rejected, completed, cancelled }

AppointmentStatus _statusFromString(String? value) {
  return AppointmentStatus.values.firstWhere((s) => s.name == value, orElse: () => AppointmentStatus.pending);
}

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.accepted:
        return 'Accepted';
      case AppointmentStatus.rejected:
        return 'Rejected';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// True while the appointment still lies ahead and can be acted on
  /// (cancelled/rescheduled by the patient, accepted/rejected by the doctor).
  bool get isUpcoming => this == AppointmentStatus.pending || this == AppointmentStatus.accepted;
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final String timeSlot;
  final String reason;
  final AppointmentStatus status;
  final String consultationNotes;
  final String prescription;
  final bool reviewed;
  final DateTime? createdAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.timeSlot,
    required this.reason,
    required this.status,
    this.consultationNotes = '',
    this.prescription = '',
    this.reviewed = false,
    this.createdAt,
  });

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      status: _statusFromString(data['status'] as String?),
      consultationNotes: data['consultationNotes'] as String? ?? '',
      prescription: data['prescription'] as String? ?? '',
      reviewed: data['reviewed'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'reason': reason,
      'status': AppointmentStatus.pending.name,
      'consultationNotes': '',
      'prescription': '',
      'reviewed': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
