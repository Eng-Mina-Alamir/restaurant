import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../delivery/presentation/controllers/delivery_controller.dart';
import '../../domain/entities/chat_message.dart';
import '../controllers/chat_controller.dart';
import '../controllers/unread_chat_controller.dart';

/// Order-scoped customer ↔ driver conversation.
///
/// History-first bubbles (own messages hug the directional end edge in the
/// primary color, others the start edge), skeleton bubbles while history
/// loads, and a shared [EmptyState] for fresh threads. Failures surface
/// as snack bars; the thread refreshes live through [ChatController].
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

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
    _inputFocus.dispose();
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
    final assignment = ref.watch(deliveryAssignmentForOrderProvider(widget.orderId)).valueOrNull;
    final isAssignmentPending = assignment != null && assignment.deliveryStatus == DeliveryStatus.pending;

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
              loading: () => const _ChatMessagesSkeleton(),
              error: (err, _) => ErrorState(
                message: 'تعذر تحميل المحادثة',
                errorDetail: err,
                onRetry: () => ref
                    .read(chatControllerProvider(widget.orderId).notifier)
                    .retry(),
              ),
              data: (messages) => RefreshIndicator(
                onRefresh: () async => ref
                    .read(chatControllerProvider(widget.orderId).notifier)
                    .retry(),
                child: messages.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: 350,
                          alignment: Alignment.center,
                          child: EmptyState(
                            icon: Icons.chat_bubble_outline,
                            message: 'لا توجد رسائل بعد',
                            actionLabel: 'ابدأ المحادثة',
                            onAction: _inputFocus.requestFocus,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
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
          ),
          const Divider(height: 1),

          if (isAssignmentPending)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'المحادثة مقفلة ومتاحة فقط بعد قبول السائق للمهمة 🛵',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Quick preset reply chips for instant driver ↔ customer communication
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  for (final preset in const [
                    'أنا عند الباب 🚪',
                    'وصلت لموقعك 📍',
                    'يرجى الخروج للاستلام 🛵',
                    'أنا في الطريق إليك ⚡',
                    'سأكون متواجداً خلال دقائق 👍',
                    'شكراً جزيلاً لك 🙏',
                  ])
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                      child: ActionChip(
                        label:
                            Text(preset, style: const TextStyle(fontSize: 11.5)),
                        onPressed: () {
                          _inputController.text = preset;
                          _send();
                        },
                      ),
                    ),
                ],
              ),
            ),

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
                        focusNode: _inputFocus,
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
    final isLtr = Directionality.of(context) == TextDirection.ltr;

    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
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
            // Chat-tail look: only the top corner on the sender's side is
            // tightened; everything else keeps the standard radius.
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(isMine ? AppRadius.md : AppRadius.sm),
              topEnd: Radius.circular(isMine ? AppRadius.sm : AppRadius.md),
              bottomStart: const Radius.circular(AppRadius.md),
              bottomEnd: const Radius.circular(AppRadius.md),
            ),
          ),
          child: Column(
            // CrossAxisAlignment.end/start are absolute (left/right), so map
            // "own messages hug their trailing edge" through the ambient
            // Directionality instead of hard-coding a side.
            crossAxisAlignment: isMine
                ? (isLtr ? CrossAxisAlignment.end : CrossAxisAlignment.start)
                : (isLtr ? CrossAxisAlignment.start : CrossAxisAlignment.end),
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

/// Skeleton thread shown while history loads.
///
/// Alternates bubbles between the directional start/end edges with varied
/// widths so the shimmer mirrors the geometry of a real conversation.
class _ChatMessagesSkeleton extends StatelessWidget {
  const _ChatMessagesSkeleton();

  /// Widths echo varied message lengths (kept under the 72% bubble cap).
  static const List<double> _bubbleWidths = <double>[210, 140, 250, 120, 190];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: _bubbleWidths.length,
      itemBuilder: (context, index) {
        // Odd indices sit on the "mine" side, echoing a two-party thread.
        final isMine = index.isOdd;
        return Align(
          alignment: isMine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: SkeletonBox(
              width: _bubbleWidths[index],
              height: 48,
              borderRadius: AppRadius.sm,
            ),
          ),
        );
      },
    );
  }
}
