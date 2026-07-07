import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/chat_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// Professional 1-to-1 chat: text + image bubbles, online status,
/// optimistic sending and a lightweight typing indicator.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  final String conversationId;
  final UserModel otherUser;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _showTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<ChatProvider>().loadMessages(widget.conversationId, userId);
    });
    // Placeholder for a real-time "typing" signal (WebSocket/FCM data msg):
    // the UI hook is ready — flip [_showTyping] when the event arrives.
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    final userId = context.read<AuthProvider>().user?.id ?? '';
    await context
        .read<ChatProvider>()
        .sendText(widget.conversationId, userId, text);
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              name: widget.otherUser.name,
              imageUrl: widget.otherUser.avatarUrl,
              radius: 19,
              showOnlineDot: true,
              isOnline: widget.otherUser.isOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _showTyping
                        ? 'a escrever…'
                        : widget.otherUser.isOnline
                            ? 'online'
                            : 'offline',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.otherUser.isOnline || _showTyping
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: switch (chat.messagesStatus) {
              ViewStatus.loading || ViewStatus.initial =>
                const Center(child: CircularProgressIndicator()),
              ViewStatus.error => ErrorStateView(
                  message: chat.error ?? '',
                  onRetry: () {
                    final userId =
                        context.read<AuthProvider>().user?.id ?? '';
                    chat.loadMessages(widget.conversationId, userId);
                  },
                ),
              _ => chat.messages.isEmpty
                  ? EmptyStateView(
                      icon: Icons.waving_hand_rounded,
                      title: 'Diga olá 👋',
                      message:
                          'Envie a primeira mensagem a ${widget.otherUser.name.split(' ').first}.',
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: chat.messages.length,
                      itemBuilder: (_, i) {
                        final m = chat.messages[i];
                        final bool showTail = i == chat.messages.length - 1 ||
                            chat.messages[i + 1].isMine != m.isMine;
                        return _MessageBubble(message: m, showTail: showTail);
                      },
                    ),
            },
          ),
          // ── Composer ─────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Enviar imagem',
                    onPressed: () {
                      // Hook ready: plug an image_picker call here and pass
                      // the file path to ChatProvider/MessageRepository.sendImage.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ligue o selector de imagens ao endpoint de envio (sendImage).',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.photo_outlined),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Escreva uma mensagem…',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed:
                        _input.text.trim().isEmpty || chat.isSending
                            ? null
                            : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.showTail});

  final MessageModel message;
  final bool showTail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool mine = message.isMine;

    final Color bg = mine ? scheme.primary : scheme.surfaceContainerHighest;
    final Color fg = mine ? Colors.white : scheme.onSurface;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: showTail ? 12 : 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .74,
        ),
        padding: message.isImage
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine || !showTail ? 18 : 4),
            bottomRight: Radius.circular(mine && showTail ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isImage)
              AppNetworkImage(
                url: message.imageUrl,
                height: 200,
                borderRadius: BorderRadius.circular(14),
              )
            else
              Text(message.text ?? '',
                  style: TextStyle(color: fg, height: 1.35)),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.sentAt != null)
                  Text(
                    Formatters.chatTime(message.sentAt!),
                    style: TextStyle(
                      fontSize: 10,
                      color: mine
                          ? Colors.white.withOpacity(.75)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isSending
                        ? Icons.schedule_rounded
                        : message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                    size: 13,
                    color: Colors.white.withOpacity(.85),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
