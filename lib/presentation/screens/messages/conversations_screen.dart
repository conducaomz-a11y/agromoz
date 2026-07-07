import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/chat_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      if (chat.conversationsStatus == ViewStatus.initial) {
        chat.loadConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: RefreshIndicator(
        onRefresh: () => chat.loadConversations(refresh: true),
        child: switch (chat.conversationsStatus) {
          ViewStatus.loading || ViewStatus.initial =>
            const Center(child: CircularProgressIndicator()),
          ViewStatus.error => ErrorStateView(
              message: chat.error ?? '',
              onRetry: () => chat.loadConversations(),
            ),
          ViewStatus.empty => const EmptyStateView(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Ainda sem conversas',
              message:
                  'Quando contactar um vendedor, a conversa aparecerá aqui.',
            ),
          _ => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: chat.conversations.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) {
                final c = chat.conversations[i];
                final bool hasUnread = c.unreadCount > 0;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: UserAvatar(
                    name: c.otherUser.name,
                    imageUrl: c.otherUser.avatarUrl,
                    radius: 26,
                    showOnlineDot: true,
                    isOnline: c.otherUser.isOnline,
                  ),
                  title: Text(
                    c.otherUser.name,
                    style: TextStyle(
                      fontWeight:
                          hasUnread ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    c.lastMessage ?? 'Iniciar conversa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          hasUnread ? FontWeight.w600 : FontWeight.normal,
                      color: hasUnread
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (c.lastMessageAt != null)
                        Text(
                          Formatters.timeAgo(c.lastMessageAt!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (hasUnread) ...[
                        const SizedBox(height: 6),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            '${c.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.chat,
                    arguments: ChatArgs(
                      conversationId: c.id,
                      otherUser: c.otherUser,
                    ),
                  ),
                );
              },
            ),
        },
      ),
    );
  }
}
