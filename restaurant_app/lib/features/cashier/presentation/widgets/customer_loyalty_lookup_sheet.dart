import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/loyalty_customer_entity.dart';

/// Modal bottom sheet for searching customer loyalty accounts and redeeming points for discounts.
class CustomerLoyaltyLookupSheet extends ConsumerStatefulWidget {
  const CustomerLoyaltyLookupSheet({
    super.key,
    required this.orderTotal,
    this.currentCustomer,
  });

  final double orderTotal;
  final LoyaltyCustomer? currentCustomer;

  static Future<(LoyaltyCustomer?, int)> show(
    BuildContext context, {
    required double orderTotal,
    LoyaltyCustomer? currentCustomer,
  }) async {
    final result = await showModalBottomSheet<(LoyaltyCustomer?, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomerLoyaltyLookupSheet(
        orderTotal: orderTotal,
        currentCustomer: currentCustomer,
      ),
    );
    return result ?? (null, 0);
  }

  @override
  ConsumerState<CustomerLoyaltyLookupSheet> createState() =>
      _CustomerLoyaltyLookupSheetState();
}

class _CustomerLoyaltyLookupSheetState
    extends ConsumerState<CustomerLoyaltyLookupSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  LoyaltyCustomer? _foundCustomer;
  int _pointsToRedeem = 0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _foundCustomer = widget.currentCustomer;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCustomer(String query) async {
    final clean = query.trim();
    if (clean.length < 3) return;

    setState(() => _isSearching = true);
    final repo = ref.read(supabaseCashierRepositoryProvider);
    final result = await repo.searchLoyaltyCustomers(clean);
    if (!mounted) return;

    setState(() {
      _isSearching = false;
      result.when(
        onLeft: (_) {},
        onRight: (matches) {
          if (matches.isNotEmpty) {
            _foundCustomer = matches.first;
            _pointsToRedeem = 0;
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final customer = _foundCustomer;
    final discountVal = _pointsToRedeem * LoyaltyCustomer.kPointsToEgpRate;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFCA8A04),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'برنامج الولاء ونقاط العملاء (Loyalty POS)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'البحث برقم الهاتف واستبدال النقاط بخصم مباشر',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Phone Search Field
          TextField(
            controller: _searchCtrl,
            keyboardType: TextInputType.phone,
            onChanged: _searchCustomer,
            decoration: InputDecoration(
              hintText: 'اكتب رقم هاتف العميل (مثال: 01012345678)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _foundCustomer = null);
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              filled: true,
              fillColor: isDark ? colorScheme.surfaceContainerLow : Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Customer Profile Card (if found)
          if (customer != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: const Color(0xFFFACC15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFCA8A04),
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF713F12),
                                ),
                              ),
                              Text(
                                '${customer.phoneNumber} • ${customer.tier.labelAr}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF854D0E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCA8A04),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${customer.pointsBalance} نقطة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFFDE047)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'القيمة المالية للنقاط: ${Formatters.formatCurrency(customer.pointsValueInEgp)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF713F12),
                        ),
                      ),
                      Text(
                        'إجمالي الزيارات: ${customer.totalOrdersCount}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF854D0E)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Points Redemption Control
            if (customer.pointsBalance > 0) ...[
              Text(
                'استبدال النقاط بخصم (الحد الأقصى: ${customer.pointsBalance} نقطة):',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _pointsToRedeem.toDouble(),
                      min: 0,
                      max: customer.pointsBalance.toDouble(),
                      divisions: (customer.pointsBalance / 10).clamp(1, 100).toInt(),
                      label: '$_pointsToRedeem نقطة',
                      onChanged: (val) => setState(() => _pointsToRedeem = val.toInt()),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      '- ${Formatters.formatCurrency(discountVal)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerLow : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اكتب رقم هاتف العميل للبحث عن حسابه وعرض رصيد نقاطه',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Confirm Action
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFCA8A04),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: customer != null
                ? () => Navigator.of(context).pop((customer, _pointsToRedeem))
                : null,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(
              _pointsToRedeem > 0
                  ? 'ربط العميل وتطبيق خصم النقاط (-${Formatters.formatCurrency(discountVal)})'
                  : 'ربط العميل بالفاتورة لتجميع النقاط ✅',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
