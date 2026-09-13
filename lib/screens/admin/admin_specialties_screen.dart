import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/specialty.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

class AdminSpecialtiesScreen extends StatelessWidget {
  const AdminSpecialtiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Specialties & Departments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, auth),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Specialty>>(
        stream: auth.firestoreService.watchSpecialties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final specialties = snapshot.data ?? [];
          if (specialties.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'No specialties yet',
              message: 'Tap + to add one (e.g. Cardiology, Dentistry).',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: specialties.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final specialty = specialties[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                  title: Text(specialty.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    onPressed: () => auth.firestoreService.deleteSpecialty(specialty.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, AppAuthProvider auth) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Specialty'),
        content: AppTextField(controller: controller, label: 'Name'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          PrimaryButton(
            label: 'Add',
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              auth.firestoreService.addSpecialty(controller.text);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}
