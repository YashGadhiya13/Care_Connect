import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_patients_screen.dart';

/// Bottom-nav shell for an Admin: Dashboard / Doctors / Patients / Appointments / Profile.
class AdminHomeShell extends StatefulWidget {
  const AdminHomeShell({super.key});

  @override
  State<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<AdminHomeShell> {
  int _index = 0;

  static const _screens = [
    AdminDashboardScreen(),
    AdminDoctorsScreen(),
    AdminPatientsScreen(),
    AdminAppointmentsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
