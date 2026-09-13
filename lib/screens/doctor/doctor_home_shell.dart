import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'doctor_schedule_screen.dart';

/// Bottom-nav shell for an approved Doctor: Schedule / History / Profile.
class DoctorHomeShell extends StatefulWidget {
  const DoctorHomeShell({super.key});

  @override
  State<DoctorHomeShell> createState() => _DoctorHomeShellState();
}

class _DoctorHomeShellState extends State<DoctorHomeShell> {
  int _index = 0;

  static const _screens = [
    DoctorScheduleScreen(),
    DoctorScheduleScreen(showHistory: true),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
