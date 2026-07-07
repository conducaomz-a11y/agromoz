import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/notification_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/state_views.dart';

/// Notification centre — FCM-ready: when Firebase Messaging is added,
/// incoming pushes simply call NotificationProvider.load(refresh: true).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<NotificationProvider>();
      if (p.status == ViewStatus.initial) p.load();
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'order':
        return Icons.receipt_long_outlined;
      case 'product':
        return Icons.storefront_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllRead,
              child: const Text('Marcar tudo como lido'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(refresh: true),
        child: switch (provider.status) {
          ViewStatus.loading || ViewStatus.initial =>
            const Center(child: CircularProgressIndicator()),
          ViewStatus.error => ErrorStateView(
              message: provider.error ?? '',
              onRetry: () => provider.load(),
            ),
          ViewStatus.empty => const EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: 'Sem notificações',
              message:
                  'Novidades sobre mensagens, anúncios e promoções aparecem aqui.',
            ),
          _ => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final n = provider.notifications[i];
                return ListTile(
                  tileColor: n.isRead
                      ? null
                      : theme.colorScheme.primaryContainer.withValues(alpha: .25),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(_iconFor(n.type),
                        color: theme.colorScheme.primary,),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight:
                          n.isRead ? FontWeight.w500 : FontWeight.w800,
                    ),
                  ),
                  subtitle: n.body == null
                      ? null
                      : Text(n.body!,
                          maxLines: 2, overflow: TextOverflow.ellipsis,),
                  trailing: n.createdAt == null
                      ? null
                      : Text(Formatters.timeAgo(n.createdAt!),
                          style: theme.textTheme.bodySmall,),
                  onTap: () {
                    if (n.type == 'product' && n.targetId != null) {
                      Navigator.pushNamed(
                        context,
                        AppRouter.productDetail,
                        arguments: n.targetId,
                      );
                    }
                  },
                );
              },
            ),
        },
      ),
    );
  }
}
