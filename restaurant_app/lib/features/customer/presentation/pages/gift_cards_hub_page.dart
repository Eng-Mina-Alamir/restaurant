import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../domain/entities/gift_card_entity.dart';
import '../controllers/customer_wallet_controller.dart';
import '../controllers/gift_card_controller.dart';

/// Hub for digital gift cards, voucher e-gifting, and wallet redemption.
class GiftCardsHubPage extends ConsumerStatefulWidget {
  const GiftCardsHubPage({super.key});

  @override
  ConsumerState<GiftCardsHubPage> createState() => _GiftCardsHubPageState();
}

class _GiftCardsHubPageState extends ConsumerState<GiftCardsHubPage> {
  final _redeemCodeController = TextEditingController();

  @override
  void dispose() {
    _redeemCodeController.dispose();
    super.dispose();
  }

  void _showRedeemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.redeem_rounded, color: Color(0xFFC2410C)),
            SizedBox(width: 8),
            Text('شحن كود بطاقة هدية'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل كود البطاقة المكون من 16 خانة لإضافة رصيدها فوراً إلى محفظة طلباتك.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _redeemCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'كود الهدية *',
                hintText: 'GIFT-XXXX-XXXX-XXXX',
                prefixIcon: const Icon(Icons.card_giftcard_rounded),
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
              final code = _redeemCodeController.text.trim();
              if (code.isEmpty) return;

              final redeemedAmount = ref.read(giftCardControllerProvider.notifier).redeemCode(
                    code: code,
                  );
              Navigator.pop(ctx);
              _redeemCodeController.clear();

              if (redeemedAmount != null && redeemedAmount > 0) {
                ref.read(customerWalletProvider.notifier).addFunds(
                      redeemedAmount,
                      title: 'شحن بطاقة هدية ($code)',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🎉 تم شحن ${Formatters.formatCurrency(redeemedAmount)} إلى محفظتك بنجاح!\nالرصيد متاح للاستخدام في طلباتك الآن.',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 4),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'عذراً، كود البطاقة غير صالح أو تم استهلاك رصيده بالكامل مسبقاً.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('شحن الكود للمحفظة'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseGiftCardDialog() {
    double selectedAmount = 250.0;
    GiftCardTheme selectedTheme = GiftCardTheme.gourmetGold;
    final senderCtrl = TextEditingController(text: 'أنا');
    final recipientCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.celebration_rounded, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text('إرسال بطاقة هدية لصديق'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر قيمة الهدية (ج.م):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [100.0, 250.0, 500.0, 1000.0].map((amt) {
                    final isSel = selectedAmount == amt;
                    return ChoiceChip(
                      label: Text('${amt.toInt()} ج.م'),
                      selected: isSel,
                      onSelected: (val) => setDialogState(() => selectedAmount = amt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('اختر ثيم وتصميم البطاقة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: GiftCardTheme.values.map((th) {
                    final isSel = selectedTheme == th;
                    return ChoiceChip(
                      label: Text(th.labelAr),
                      selected: isSel,
                      onSelected: (val) => setDialogState(() => selectedTheme = th),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: recipientCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسم الصديق (المستلم) *',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم هاتف المستلم *',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: messageCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'رسالة إهداء شخصية',
                    hintText: 'كل سنة وأنت طيب يا غالي! أشهى وجبة على حسابي 🎉',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final recName = recipientCtrl.text.trim();
                final recPhone = phoneCtrl.text.trim();
                if (recName.isEmpty || recPhone.isEmpty) return;

                final newCard = ref.read(giftCardControllerProvider.notifier).purchaseCard(
                      amount: selectedAmount,
                      senderName: senderCtrl.text.trim(),
                      recipientName: recName,
                      recipientPhone: recPhone,
                      personalMessage: messageCtrl.text.trim(),
                      theme: selectedTheme,
                    );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم إنشاء بطاقة الهدية بنجاح! كود الهدية: ${newCard.code}'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              child: Text('شراء وإرسال (${selectedAmount.toInt()} ج.م)'),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getCardGradient(GiftCardTheme theme) {
    switch (theme) {
      case GiftCardTheme.gourmetGold:
        return const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF78350F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GiftCardTheme.birthdayParty:
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GiftCardTheme.celebrationRed:
        return const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFF991B1B), Color(0xFF450A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GiftCardTheme.emeraldLuxury:
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = ref.watch(giftCardControllerProvider);
    final walletState = ref.watch(customerWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بطاقات الهدايا الرقمية (Gift Cards)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'شحن كود',
            onPressed: _showRedeemDialog,
          ),
        ],
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Customer Wallet Balance Card ──────────────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF134E4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF5EEAD4),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رصيد محفظتك الرقمية المتاح للطلبات:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatCurrency(walletState.balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5EEAD4),
                      foregroundColor: const Color(0xFF134E4A),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: _showRedeemDialog,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('شحن كود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            // ── Top Promo Banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.card_giftcard_rounded, color: Color(0xFFF59E0B), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'أهدِ أحباءك أشهى اللحظات!',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'أرسل بطاقة شحن رقمية فورية إلى أصدقائك أو عائلتك بتصاميم ورسائل تهنئة مميزة لاستخدامها في جميع فروعنا.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: _showPurchaseGiftCardDialog,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('إرسال بطاقة هدية جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: _showRedeemDialog,
                        icon: const Icon(Icons.redeem_rounded, size: 16),
                        label: const Text('شحن كود'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── My Gift Cards ─────────────────────────────────────────────
            Text(
              'بطاقات الهدايا والمحفظة (${cards.length}):',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (cards.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Text('لا توجد بطاقات هدايا حالياً. اضغط "إرسال بطاقة" لتبدأ!'),
              )
            else
              ...cards.map((card) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: _getCardGradient(card.theme),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card.theme.labelAr,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: card.isUsable ? Colors.green.shade700 : Colors.red.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                card.isUsable ? 'صالحة للاستخدام' : 'تم استهلاك الرصيد',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الرصيد المتاح:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(
                                  Formatters.formatCurrency(card.remainingBalance),
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const Icon(Icons.restaurant_rounded, color: Colors.white38, size: 36),
                          ],
                        ),
                        if (card.personalMessage != null && card.personalMessage!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '« ${card.personalMessage} »',
                              style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('كود البطاقة:', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                Text(
                                  card.code,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: Colors.white),
                              tooltip: 'نسخ الكود',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: card.code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ كود الهدية!')),
                                );
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
  }
}
