import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'doctor_search_screen.dart';
import 'medical_records_screen.dart';
import 'my_appointments_screen.dart';
import 'patient_home_screen.dart';

/// Bottom-nav shell for a signed-in Patient: Home / Doctors / Appointments / Records / Profile.
class PatientHomeShell extends StatefulWidget {
  const PatientHomeShell({super.key});

  @override
  State<PatientHomeShell> createState() => _PatientHomeShellState();
}

class _PatientHomeShellState extends State<PatientHomeShell> {
  int _index = 0;

  void _goToDoctors() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final screens = [
      PatientHomeScreen(onFindDoctors: _goToDoctors),
      const DoctorSearchScreen(),
      const MyAppointmentsScreen(),
      const MedicalRecordsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Appts'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_shared_outlined), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
