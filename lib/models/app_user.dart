enum UserRole { patient, doctor, admin }

/// A doctor's account is `pending` until an Admin approves it — they can't
/// appear in patient search or accept appointments until then.
enum DoctorStatus { pending, approved, rejected }

// Case/whitespace-insensitive so a role typed by hand in the Firebase
// Console (e.g. "Admin") still matches instead of silently falling back.
UserRole _roleFromString(String? value) {
  final normalized = value?.trim().toLowerCase();
  return UserRole.values.firstWhere((r) => r.name == normalized, orElse: () => UserRole.patient);
}

DoctorStatus _doctorStatusFromString(String? value) {
  final normalized = value?.trim().toLowerCase();
  return DoctorStatus.values.firstWhere((s) => s.name == normalized, orElse: () => DoctorStatus.pending);
}

class Medication {
  final String name;
  final String time;
  final String notes;

  Medication({required this.name, required this.time, this.notes = ''});

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      name: map['name'] as String? ?? '',
      time: map['time'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'time': time, 'notes': notes};
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({required this.name, required this.phone, this.relation = ''});

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      relation: map['relation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'phone': phone, 'relation': relation};
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  // Doctor-only fields.
  final String specialty;
  final String department;
  final String bio;
  final DoctorStatus doctorStatus;
  final double ratingAvg;
  final int ratingCount;

  // Patient-only fields.
  final List<Medication> medications;
  final List<EmergencyContact> emergencyContacts;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.patient,
    this.specialty = '',
    this.department = '',
    this.bio = '',
    this.doctorStatus = DoctorStatus.pending,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.medications = const [],
    this.emergencyContacts = const [],
  });

  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;
  bool get isAdmin => role == UserRole.admin;
  bool get isApprovedDoctor => isDoctor && doctorStatus == DoctorStatus.approved;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: _roleFromString(map['role'] as String?),
      specialty: map['specialty'] as String? ?? '',
      department: map['department'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      doctorStatus: _doctorStatusFromString(map['doctorStatus'] as String?),
      ratingAvg: (map['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      medications: (map['medications'] as List<dynamic>? ?? [])
          .map((m) => Medication.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>? ?? [])
          .map((c) => EmergencyContact.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'specialty': specialty,
      'department': department,
      'bio': bio,
      'doctorStatus': doctorStatus.name,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'medications': medications.map((m) => m.toMap()).toList(),
      'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
    };
  }
}
