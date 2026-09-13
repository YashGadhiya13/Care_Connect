import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/primary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final profile = auth.profile;
    final email = auth.firebaseUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  InitialsAvatar(initials: profile?.initials ?? '?', radius: 40),
                  const SizedBox(height: 12),
                  Text(
                    profile?.isDoctor == true ? 'Dr. ${profile?.name ?? '...'}' : (profile?.name ?? '...'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
                  if (profile?.isDoctor == true) ...[
                    const SizedBox(height: 4),
                    Text(profile!.specialty, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
              title: const Text('Phone'),
              subtitle: Text(profile?.phone.isNotEmpty == true ? profile!.phone : 'Not set'),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showEditProfileSheet(context, auth),
              ),
            ),
            if (profile?.isDoctor == true) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                title: const Text('Bio'),
                subtitle: Text(profile!.bio.isNotEmpty ? profile.bio : 'Not set'),
              ),
            ],
            if (profile?.isPatient == true) ...[
              const Divider(),
              const SizedBox(height: 12),
              _SectionHeader(
                title: 'Medication Reminders',
                onAdd: () => _showAddMedicationSheet(context, auth, profile!),
              ),
              const SizedBox(height: 8),
              if (profile!.medications.isEmpty)
                const Text('No medications added.', style: TextStyle(color: AppColors.textSecondary))
              else
                ...profile.medications.map(
                  (m) => _ListCard(
                    icon: Icons.medication_outlined,
                    title: m.name,
                    subtitle: [m.time, m.notes].where((s) => s.isNotEmpty).join(' • '),
                    onDelete: () {
                      final updated = List.of(profile.medications)..remove(m);
                      auth.firestoreService.updateMedications(profile.uid, updated);
                    },
                  ),
                ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Emergency Contacts',
                onAdd: () => _showAddContactSheet(context, auth, profile),
              ),
              const SizedBox(height: 8),
              if (profile.emergencyContacts.isEmpty)
                const Text('No emergency contacts added.', style: TextStyle(color: AppColors.textSecondary))
              else
                ...profile.emergencyContacts.map(
                  (c) => _ListCard(
                    icon: Icons.emergency_outlined,
                    title: c.name,
                    subtitle: [c.relation, c.phone].where((s) => s.isNotEmpty).join(' • '),
                    onDelete: () {
                      final updated = List.of(profile.emergencyContacts)..remove(c);
                      auth.firestoreService.updateEmergencyContacts(profile.uid, updated);
                    },
                  ),
                ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Log Out',
              outlined: true,
              onPressed: () => auth.authService.signOut(),
              icon: Icons.logout,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AppAuthProvider auth) {
    final nameController = TextEditingController(text: auth.profile?.name ?? '');
    final phoneController = TextEditingController(text: auth.profile?.phone ?? '');
    final bioController = TextEditingController(text: auth.profile?.bio ?? '');
    final isDoctor = auth.profile?.isDoctor == true;
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Profile', style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: nameController,
                      label: 'Full name',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(controller: phoneController, label: 'Phone', keyboardType: TextInputType.phone),
                    if (isDoctor) ...[
                      const SizedBox(height: 12),
                      AppTextField(controller: bioController, label: 'Bio', maxLines: 3),
                    ],
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Save',
                      loading: loading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final uid = auth.firebaseUser?.uid;
                        if (uid == null) return;

                        setState(() => loading = true);
                        try {
                          await auth.firestoreService.updateProfile(
                            uid,
                            name: nameController.text,
                            phone: phoneController.text,
                            bio: isDoctor ? bioController.text : null,
                          );
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMedicationSheet(BuildContext context, AppAuthProvider auth, AppUser profile) {
    final nameController = TextEditingController();
    final timeController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Medication', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(controller: nameController, label: 'Medicine name'),
              const SizedBox(height: 12),
              AppTextField(controller: timeController, label: 'Time (e.g. 8:00 AM)'),
              const SizedBox(height: 12),
              AppTextField(controller: notesController, label: 'Notes (optional)'),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Add',
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  final updated = List.of(profile.medications)
                    ..add(Medication(name: nameController.text.trim(), time: timeController.text.trim(), notes: notesController.text.trim()));
                  auth.firestoreService.updateMedications(profile.uid, updated);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddContactSheet(BuildContext context, AppAuthProvider auth, AppUser profile) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Emergency Contact', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(controller: nameController, label: 'Name'),
              const SizedBox(height: 12),
              AppTextField(controller: phoneController, label: 'Phone', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              AppTextField(controller: relationController, label: 'Relation (optional)'),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Add',
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  final updated = List.of(profile.emergencyContacts)
                    ..add(EmergencyContact(name: nameController.text.trim(), phone: phoneController.text.trim(), relation: relationController.text.trim()));
                  auth.firestoreService.updateEmergencyContacts(profile.uid, updated);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary), onPressed: onAdd),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onDelete;

  const _ListCard({required this.icon, required this.title, required this.subtitle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onDelete),
        ],
      ),
    );
  }
}
