import 'package:cloud_firestore/cloud_firestore.dart';

class Specialty {
  final String id;
  final String name;

  Specialty({required this.id, required this.name});

  factory Specialty.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Specialty(id: doc.id, name: data['name'] as String? ?? '');
  }
}

/// Seeded once (by the Admin dashboard, on first load) so doctor sign-up and
/// patient search have something to pick from immediately.
const List<String> defaultSpecialties = [
  'General Physician',
  'Cardiology',
  'Dermatology',
  'Pediatrics',
  'Orthopedics',
  'Dentistry',
];
