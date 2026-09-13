import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String appointmentId;
  final int stars;
  final String comment;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.appointmentId,
    required this.stars,
    this.comment = '',
    this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Review(
      id: doc.id,
      doctorId: data['doctorId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? 'Someone',
      appointmentId: data['appointmentId'] as String? ?? '',
      stars: (data['stars'] as num?)?.toInt() ?? 5,
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'appointmentId': appointmentId,
      'stars': stars,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
