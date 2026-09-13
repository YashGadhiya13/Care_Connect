import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/empty_state.dart';

/// Shared in-app notification list — used by both Patient and Doctor.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<NotificationItem>>(
        stream: auth.firestoreService.watchNotifications(uid),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              message: 'Updates about your appointments will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              final card = Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.read ? AppColors.surface : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                      color: item.read ? AppColors.textSecondary : AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(item.body, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 6),
                          Text(timeAgo(item.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (item.read) return card;
              return InkWell(
                onTap: () => auth.firestoreService.markNotificationRead(uid, item.id),
                borderRadius: BorderRadius.circular(14),
                child: card,
              );
            },
          );
        },
      ),
    );
  }
}
