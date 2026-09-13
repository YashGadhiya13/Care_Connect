import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class AdminSendNotificationScreen extends StatefulWidget {
  const AdminSendNotificationScreen({super.key});

  @override
  State<AdminSendNotificationScreen> createState() => _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState extends State<AdminSendNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in a title and message')));
      return;
    }
    final auth = context.read<AppAuthProvider>();
    setState(() => _sending = true);
    try {
      await auth.firestoreService.sendBroadcastNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        audience: _audience,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent')));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Audience', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Everyone'), selected: _audience == 'all', onSelected: (_) => setState(() => _audience = 'all')),
                ChoiceChip(label: const Text('Patients'), selected: _audience == 'patients', onSelected: (_) => setState(() => _audience = 'patients')),
                ChoiceChip(label: const Text('Doctors'), selected: _audience == 'doctors', onSelected: (_) => setState(() => _audience = 'doctors')),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(controller: _titleController, label: 'Title'),
            const SizedBox(height: 16),
            AppTextField(controller: _bodyController, label: 'Message', maxLines: 4),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Send', icon: Icons.send_rounded, loading: _sending, onPressed: _send),
            const SizedBox(height: 12),
            const Text(
              'Delivered as an in-app notification to everyone in the selected group.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
