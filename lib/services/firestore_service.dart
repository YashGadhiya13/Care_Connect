import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/notification_item.dart';
import '../models/review.dart';
import '../models/specialty.dart';

/// All Firestore reads/writes for CareConnect: user profiles, appointments,
/// specialties, reviews and in-app notifications.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _appointments => _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _specialties => _db.collection('specialties');
  CollectionReference<Map<String, dynamic>> get _reviews => _db.collection('reviews');

  // ---- Users ----

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(uid, doc.data()!);
    });
  }

  Future<void> updateProfile(String uid, {required String name, required String phone, String? bio}) {
    final data = <String, dynamic>{'name': name.trim(), 'phone': phone.trim()};
    if (bio != null) data['bio'] = bio.trim();
    return _users.doc(uid).update(data);
  }

  Future<void> updateMedications(String uid, List<Medication> medications) {
    return _users.doc(uid).update({'medications': medications.map((m) => m.toMap()).toList()});
  }

  Future<void> updateEmergencyContacts(String uid, List<EmergencyContact> contacts) {
    return _users.doc(uid).update({'emergencyContacts': contacts.map((c) => c.toMap()).toList()});
  }

  // ---- Doctors ----

  /// Approved doctors, optionally filtered by specialty, for patient search.
  Stream<List<AppUser>> watchApprovedDoctors({String? specialty}) {
    Query<Map<String, dynamic>> query = _users
        .where('role', isEqualTo: UserRole.doctor.name)
        .where('doctorStatus', isEqualTo: DoctorStatus.approved.name);
    return query.snapshots().map((snap) {
      var doctors = snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
      if (specialty != null && specialty.isNotEmpty) {
        doctors = doctors.where((d) => d.specialty == specialty).toList();
      }
      doctors.sort((a, b) => a.name.compareTo(b.name));
      return doctors;
    });
  }

  Stream<List<AppUser>> watchAllDoctors() {
    return _users.where('role', isEqualTo: UserRole.doctor.name).snapshots().map(
          (snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Stream<List<AppUser>> watchAllPatients() {
    return _users.where('role', isEqualTo: UserRole.patient.name).snapshots().map(
          (snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Future<void> setDoctorStatus(String doctorId, DoctorStatus status) {
    return _users.doc(doctorId).update({'doctorStatus': status.name});
  }

  // ---- Appointments ----

  Future<String> createAppointment(Appointment appointment) async {
    final doc = await _appointments.add(appointment.toCreateMap());
    return doc.id;
  }

  Stream<List<Appointment>> watchPatientAppointments(String patientId) {
    return _appointments.where('patientId', isEqualTo: patientId).snapshots().map(_toSortedList);
  }

  Stream<List<Appointment>> watchDoctorAppointments(String doctorId) {
    return _appointments.where('doctorId', isEqualTo: doctorId).snapshots().map(_toSortedList);
  }

  Stream<List<Appointment>> watchAllAppointments() {
    return _appointments.snapshots().map(_toSortedList);
  }

  List<Appointment> _toSortedList(QuerySnapshot<Map<String, dynamic>> snap) {
    final appointments = snap.docs.map(Appointment.fromDoc).toList();
    appointments.sort((a, b) => b.date.compareTo(a.date));
    return appointments;
  }

  Future<void> updateAppointmentStatus(String id, AppointmentStatus status) {
    return _appointments.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addConsultationNotes(String id, {required String notes, required String prescription}) {
    return _appointments.doc(id).update({
      'consultationNotes': notes.trim(),
      'prescription': prescription.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rescheduleAppointment(String id, {required DateTime date, required String timeSlot}) {
    return _appointments.doc(id).update({
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'status': AppointmentStatus.pending.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---- Specialties ----

  Stream<List<Specialty>> watchSpecialties() {
    return _specialties.orderBy('name').snapshots().map((snap) => snap.docs.map(Specialty.fromDoc).toList());
  }

  Future<void> addSpecialty(String name) {
    return _specialties.add({'name': name.trim()});
  }

  Future<void> deleteSpecialty(String id) {
    return _specialties.doc(id).delete();
  }

  /// Creates the default specialty list if the collection is empty. Safe to
  /// call every time the Admin dashboard loads.
  Future<void> seedSpecialtiesIfEmpty() async {
    final existing = await _specialties.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final name in defaultSpecialties) {
      batch.set(_specialties.doc(), {'name': name});
    }
    await batch.commit();
  }

  // ---- Reviews ----

  /// Adds a review and updates the doctor's running average in one atomic
  /// transaction (no Cloud Function needed).
  Future<void> addReview(Review review) async {
    final doctorRef = _users.doc(review.doctorId);
    final reviewRef = _reviews.doc();
    await _db.runTransaction((txn) async {
      final doctorSnap = await txn.get(doctorRef);
      final currentAvg = (doctorSnap.data()?['ratingAvg'] as num?)?.toDouble() ?? 0;
      final currentCount = (doctorSnap.data()?['ratingCount'] as num?)?.toInt() ?? 0;
      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + review.stars) / newCount;

      txn.set(reviewRef, review.toCreateMap());
      txn.update(doctorRef, {'ratingAvg': newAvg, 'ratingCount': newCount});
      txn.update(_appointments.doc(review.appointmentId), {'reviewed': true});
    });
  }

  Stream<List<Review>> watchDoctorReviews(String doctorId) {
    return _reviews.where('doctorId', isEqualTo: doctorId).snapshots().map((snap) {
      final reviews = snap.docs.map(Review.fromDoc).toList();
      reviews.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return reviews;
    });
  }

  Stream<List<Review>> watchAllReviews() {
    return _reviews.snapshots().map((snap) {
      final reviews = snap.docs.map(Review.fromDoc).toList();
      reviews.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return reviews;
    });
  }

  // ---- Notifications (in-app) ----

  /// Writes a notification into another user's mailbox — e.g. the doctor
  /// accepting an appointment notifies the patient, and vice versa.
  Future<void> sendNotification(String toUid, {required String title, required String body}) {
    return _users.doc(toUid).collection('notifications').add({
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<NotificationItem>> watchNotifications(String uid) {
    return _users.doc(uid).collection('notifications').snapshots().map((snap) {
      final items = snap.docs.map(NotificationItem.fromDoc).toList();
      items.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Future<void> markNotificationRead(String uid, String notificationId) {
    return _users.doc(uid).collection('notifications').doc(notificationId).update({'read': true});
  }

  /// Admin broadcast: writes the same notification into every matching
  /// user's mailbox. [audience] is 'all', 'patients', or 'doctors'.
  Future<void> sendBroadcastNotification({required String title, required String body, required String audience}) async {
    Query<Map<String, dynamic>> query = _users;
    if (audience == 'patients') query = query.where('role', isEqualTo: UserRole.patient.name);
    if (audience == 'doctors') query = query.where('role', isEqualTo: UserRole.doctor.name);
    if (audience == 'all') query = query.where('role', whereIn: [UserRole.patient.name, UserRole.doctor.name]);

    final recipients = await query.get();
    final batch = _db.batch();
    for (final doc in recipients.docs) {
      final ref = _users.doc(doc.id).collection('notifications').doc();
      batch.set(ref, {'title': title, 'body': body, 'read': false, 'createdAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }
}
