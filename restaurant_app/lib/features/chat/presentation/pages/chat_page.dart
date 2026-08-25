import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/entities/chat_message.dart';
import '../controllers/chat_controller.dart';
import '../controllers/unread_chat_controller.dart';

/// Order-scoped customer ↔ driver conversation.
///
/// Minimal slice: history-first bubbles (own messages right-aligned in the
/// primary color, others left) plus a validated send field. Failures surface
/// as snack bars; the thread refreshes live through [ChatController].
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _inputController = TextEditingController();

  /// Badge counter for this order, resolved once so [dispose] can clear it
  /// without touching `ref` (Riverpod forbids ref reads after unmount).
  late final UnreadChatController _unreadBadge = ref.read(
    unreadChatCountProvider(widget.orderId).notifier,
  );

  bool get _canSend => _inputController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Entering the thread clears its unread badge. Deferred post-frame: the
    // driver cards below may be listening to the counter, and mutating a
    // listened-to provider mid-build is rejected by Riverpod (and would give
    // them an inconsistent rebuild).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _unreadBadge.markRead();
    });
    ref
        .read(chatControllerProvider(widget.orderId).notifier)
        .init(widget.orderId, ref.read(chatCurrentUserIdProvider));
    _inputController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // Leaving the thread clears any messages that landed while it was open,
    // so returning to the driver cards shows no stale badge. Deferred via
    // microtask because unmount runs mid-frame, where mutating a listened-to
    // provider is forbidden.
    scheduleMicrotask(_unreadBadge.markRead);
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_canSend) return;
    final text = _inputController.text;
    _inputController.clear();
    setState(() {});
    final error = await ref
        .read(chatControllerProvider(widget.orderId).notifier)
        .send(text);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messagesAsync = ref.watch(chatControllerProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('محادثة الطلب'),
            Text(
              Formatters.formatOrderId(widget.orderId),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorState(
                message: 'تعذر تحميل المحادثة',
                errorDetail: err,
                onRetry: () => ref
                    .read(chatControllerProvider(widget.orderId).notifier)
                    .retry(),
              ),
              data: (messages) => messages.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد رسائل بعد — ابدأ المحادثة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) => _MessageBubble(
                        key: ValueKey<String>(messages[index].id),
                        message: messages[index],
                        isMine:
                            messages[index].senderId ==
                            ref.watch(chatCurrentUserIdProvider),
                      ),
                    ),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _canSend ? _send : null,
                    icon: const Icon(Icons.send),
                    tooltip: 'إرسال',
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
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  /// Screen-reader name for the sender side of this bubble.
  ///
  /// The conversation is strictly two-party (customer ↔ driver), but the
  /// `/chat/:orderId` route carries no viewer-role signal and no role
  /// provider exists (roles live only in Supabase profiles) — the page only
  /// knows `chatCurrentUserIdProvider`, i.e. whether a message is its own.
  /// Asserting a fixed counterpart role ('المندوب') would mislabel threads
  /// opened from DriverHomePage, where the counterpart is the customer, so
  /// the always-correct neutral pair below is used.
  String get _senderRoleLabel => isMine ? 'أنت' : 'الطرف الآخر';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      // One complete announcement per bubble; excludeSemantics stops the
      // body/timestamp Texts from being read again as separate nodes.
      child: Semantics(
        label: 'رسالة من $_senderRoleLabel: ${message.body}',
        excludeSemantics: true,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: isMine
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMine ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message.createdAt == null
                    ? ''
                    : Formatters.formatTime(message.createdAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isMine
                      ? colorScheme.onPrimary.withValues(alpha: 0.7)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
