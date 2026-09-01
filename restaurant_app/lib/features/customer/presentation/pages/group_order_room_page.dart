import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../domain/entities/group_order_session_entity.dart';
import '../controllers/group_order_controller.dart';

/// Interactive Group Ordering Room & Shared Cart Hub for Friends & Coworkers.
class GroupOrderRoomPage extends ConsumerStatefulWidget {
  const GroupOrderRoomPage({super.key});

  @override
  ConsumerState<GroupOrderRoomPage> createState() => _GroupOrderRoomPageState();
}

class _GroupOrderRoomPageState extends ConsumerState<GroupOrderRoomPage> {
  final _joinNameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _customItemNameController = TextEditingController();
  final _customItemPriceController = TextEditingController(text: '85');

  @override
  void dispose() {
    _joinNameController.dispose();
    _joinCodeController.dispose();
    _customItemNameController.dispose();
    _customItemPriceController.dispose();
    super.dispose();
  }

  void _showCreateRoomDialog() {
    final nameCtrl = TextEditingController(text: 'كيرلس سمير');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_add_rounded, color: Color(0xFFC2410C)),
            SizedBox(width: 8),
            Text('إنشاء غرفة طلب جماعي جديدة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ستقوم بإنشاء غرفة وتوليد كود مشاركة لزملائك ليتمكن الجميع من إضافة وجباتهم في سلة واحدة.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'اسمك (المضيف) *',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC2410C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              ref.read(groupOrderControllerProvider.notifier).createRoom(
                    hostId: 'usr-host',
                    hostName: name,
                    restaurantId: 'rest-1',
                  );
              Navigator.pop(ctx);
            },
            child: const Text('إنشاء الغرفة الآن'),
          ),
        ],
      ),
    );
  }

  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('الانضمام لغرفة طلب جماعي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _joinCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'كود الغرفة (6 أحرف) *',
                hintText: 'مثال: GRP88X',
                prefixIcon: const Icon(Icons.qr_code_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _joinNameController,
              decoration: InputDecoration(
                labelText: 'اسمك المستعار *',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = _joinNameController.text.trim();
              if (name.isEmpty) return;
              ref.read(groupOrderControllerProvider.notifier).joinRoom(
                    memberId: 'usr-${DateTime.now().millisecondsSinceEpoch}',
                    memberName: name,
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('أهلاً بك يا $name، تم الانضمام للغرفة بنجاح!')),
              );
            },
            child: const Text('انضم للغرفة'),
          ),
        ],
      ),
    );
  }

  void _showAddDishDialog(GroupOrderSession session) {
    String selectedMember = session.members.first.name;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('إضافة وجبة للسلة الجماعية'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedMember,
                decoration: InputDecoration(
                  labelText: 'اختر العضو صاحب الوجبة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                items: session.members
                    .map((m) => DropdownMenuItem(value: m.name, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedMember = v ?? selectedMember),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _customItemNameController,
                decoration: InputDecoration(
                  labelText: 'اسم الوجبة *',
                  hintText: 'مثال: تريبل تشيز برجر كومبو',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _customItemPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'السعر (ج.م) *',
                  prefixText: 'ج.م ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final itemName = _customItemNameController.text.trim();
                final price = double.tryParse(_customItemPriceController.text) ?? 85.0;
                if (itemName.isEmpty) return;

                final member = session.members.firstWhere(
                  (m) => m.name == selectedMember,
                  orElse: () => session.members.first,
                );

                ref.read(groupOrderControllerProvider.notifier).addMemberItem(
                      GroupMemberItem(
                        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
                        memberId: member.id,
                        memberName: member.name,
                        itemId: 'custom-item',
                        itemName: itemName,
                        itemPrice: price,
                        addedAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                _customItemNameController.clear();
              },
              child: const Text('إضافة للسلة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(groupOrderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('غرفة الطلب الجماعي (Group Order)'),
        actions: [
          if (session != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
              tooltip: 'مغادرة الغرفة',
              onPressed: () {
                ref.read(groupOrderControllerProvider.notifier).leaveSession();
              },
            ),
        ],
      ),
      body: ConstrainedContentView(
        child: session == null
            ? _buildNoSessionState(theme)
            : _buildActiveSessionView(theme, session),
      ),
    );
  }

  Widget _buildNoSessionState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'اطلبوا معاً بسلة واحدة وفاتورة مقسمة!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'أنشئ غرفة طلب وشارك الرابط مع زملائك في العمل أو أصدقائك ليضيف الجميع وجباتهم بسهولة مع خيارات دفع فردية أو جماعية.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _showCreateRoomDialog,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('إنشاء غرفة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _showJoinRoomDialog,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('الانضمام بكود الغرفة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionView(ThemeData theme, GroupOrderSession session) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Room Code Header ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC2410C), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wifi_tethering_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'غرفة الطلب الجماعي نشطة',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      session.status.labelAr,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'كود مشاركة الغرفة مع الأصدقاء:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.roomCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFC2410C),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: session.roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ كود الغرفة إلى الحافظة!')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('نسخ الكود'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Payment Mode Selector ──────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text('طريقة سداد الفاتورة الجماعية:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: GroupPaymentMode.values.map((mode) {
                  final isSelected = session.paymentMode == mode;
                  return ChoiceChip(
                    label: Text(mode.labelAr),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(groupOrderControllerProvider.notifier).updatePaymentMode(mode);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),

        // ── Active Members & Items ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أصناف الأعضاء (${session.members.length} مشاركين):',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showAddDishDialog(session),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('إضافة وجبة'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        if (session.members.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Text('لم ينضم أي عضو بعد. شارك كود الغرفة لتبدأ!'),
          )
        else
          ...session.members.map((member) {
            final memberItems = session.itemsForMember(member.id);
            final memberTotal = session.totalForMember(member.id);

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: member.isHost ? const Color(0xFFC2410C) : const Color(0xFF0284C7),
                              child: Text(
                                member.name.isNotEmpty ? member.name[0] : 'U',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              member.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (member.isHost) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('المضيف', style: TextStyle(fontSize: 10, color: Colors.orange)),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          Formatters.formatCurrency(memberTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (memberItems.isEmpty)
                      const Text('لم يختر وجبته بعد', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      ...memberItems.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(item.itemName),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(Formatters.formatCurrency(item.totalPrice)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                      onPressed: () {
                                        ref.read(groupOrderControllerProvider.notifier).removeMemberItem(item.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: AppSpacing.md),

        // ── Grand Total & Checkout Bar ─────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي الطلب الجماعي:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    Formatters.formatCurrency(session.subtotal),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFC2410C)),
                  ),
                ],
              ),
              if (session.paymentMode == GroupPaymentMode.splitEvenly && session.members.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('نصيب الفرد بالتساوي:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      Formatters.formatCurrency(session.perPersonShare),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    ref.read(groupOrderControllerProvider.notifier).lockRoom();
                    context.push('/cart');
                  },
                  icon: const Icon(Icons.shopping_cart_checkout_rounded),
                  label: const Text('اعتماد السلة والانتقال للدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
