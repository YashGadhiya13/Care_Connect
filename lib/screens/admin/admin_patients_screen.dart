import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/initials_avatar.dart';

class AdminPatientsScreen extends StatelessWidget {
  const AdminPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Patients')),
      body: StreamBuilder<List<AppUser>>(
        stream: auth.firestoreService.watchAllPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final patients = snapshot.data ?? [];
          if (patients.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No patients yet',
              message: 'Registered patients will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final patient = patients[i];
              return Card(
                child: ListTile(
                  leading: InitialsAvatar(initials: patient.initials),
                  title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([patient.email, if (patient.phone.isNotEmpty) patient.phone].join(' • ')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
