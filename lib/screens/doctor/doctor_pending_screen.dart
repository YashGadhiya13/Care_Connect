import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

/// Shown instead of the doctor home shell while `doctorStatus` is
/// pending/rejected — a doctor cannot use the app until an Admin approves.
class DoctorPendingScreen extends StatelessWidget {
  const DoctorPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final rejected = auth.profile?.doctorStatus.name == 'rejected';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rejected ? Icons.block_rounded : Icons.hourglass_top_rounded,
                  size: 56,
                  color: rejected ? AppColors.danger : AppColors.warning,
                ),
                const SizedBox(height: 20),
                Text(
                  rejected ? 'Registration not approved' : 'Awaiting Admin approval',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  rejected
                      ? 'Your doctor registration was not approved. Please contact CareConnect support for details.'
                      : 'Your doctor account is under review. You\'ll be able to manage appointments once an Admin approves your registration.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Log Out',
                  outlined: true,
                  icon: Icons.logout,
                  onPressed: () => auth.authService.signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
