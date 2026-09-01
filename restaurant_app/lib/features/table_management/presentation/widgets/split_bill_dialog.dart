import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../controllers/waiter_shift_controller.dart';
import '../../domain/entities/split_bill_entity.dart';
import '../../domain/services/bill_splitting_service.dart';

/// Interactive modal dialog for split bill operations (Equal Split vs Seat/Item Split).
class SplitBillDialog extends ConsumerStatefulWidget {
  const SplitBillDialog({
    super.key,
    required this.order,
    required this.tableNumber,
  });

  final OrderEntity order;
  final int tableNumber;

  static Future<SplitBillResult?> show(
    BuildContext context, {
    required OrderEntity order,
    required int tableNumber,
  }) {
    return showDialog<SplitBillResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SplitBillDialog(order: order, tableNumber: tableNumber),
    );
  }

  @override
  ConsumerState<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends ConsumerState<SplitBillDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _guestCount = 2;
  final double _tipAmount = 0.0;
  final TextEditingController _tipController = TextEditingController();

  late SplitBillResult _equalSplitResult;
  late SplitBillResult _seatSplitResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recalculateSplits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _recalculateSplits() {
    _equalSplitResult = BillSplittingService.calculateEqualSplit(
      orderId: widget.order.id,
      totalBill: widget.order.totalAmount,
      guestCount: _guestCount,
      tipAmount: _tipAmount,
    );

    _seatSplitResult = BillSplittingService.calculateSeatOrItemSplit(
      orderId: widget.order.id,
      orderItems: widget.order.items,
      totalGuests: _guestCount,
    );
  }

  void _updateEqualSharePayment(int index, PaymentMethod method, bool paid) {
    setState(() {
      final updatedShares = List<SplitBillShare>.from(_equalSplitResult.shares);
      updatedShares[index] = updatedShares[index].copyWith(
        paymentMethod: method,
        isPaid: paid,
        paidAt: paid ? DateTime.now() : null,
      );
      _equalSplitResult = SplitBillResult(
        orderId: widget.order.id,
        originalTotal: _equalSplitResult.originalTotal,
        splitType: SplitBillType.equal,
        shares: updatedShares,
      );
    });
  }

  void _updateSeatSharePayment(int index, PaymentMethod method, bool paid) {
    setState(() {
      final updatedShares = List<SplitBillShare>.from(_seatSplitResult.shares);
      updatedShares[index] = updatedShares[index].copyWith(
        paymentMethod: method,
        isPaid: paid,
        paidAt: paid ? DateTime.now() : null,
      );
      _seatSplitResult = SplitBillResult(
        orderId: widget.order.id,
        originalTotal: _seatSplitResult.originalTotal,
        splitType: SplitBillType.bySeat,
        shares: updatedShares,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeResult =
        _tabController.index == 0 ? _equalSplitResult : _seatSplitResult;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.call_split_rounded,
                color: Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تقسيم شيك طاولة ${widget.tableNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'إغلاق',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إجمالي الفاتورة الأصلية:',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                Formatters.formatCurrency(widget.order.totalAmount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(
                icon: Icon(Icons.people_outline, size: 18),
                text: 'تقسيم متساوي',
              ),
              Tab(
                icon: Icon(Icons.event_seat_outlined, size: 18),
                text: 'حسب المقاعد والأصناف',
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Guest Count Stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('عدد الضيوف:', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  IconButton.filledTonal(
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed:
                        _guestCount > 2
                            ? () {
                              setState(() {
                                _guestCount--;
                                _recalculateSplits();
                              });
                            }
                            : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_guestCount أفراد',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    onPressed:
                        _guestCount < 12
                            ? () {
                              setState(() {
                                _guestCount++;
                                _recalculateSplits();
                              });
                            }
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab Views for Split Breakdown
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Equal Split Shares
                  ListView.separated(
                    itemCount: _equalSplitResult.shares.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (ctx, index) {
                      final share = _equalSplitResult.shares[index];
                      return _buildShareCard(
                        share: share,
                        onPaymentChanged:
                            (paid, method) => _updateEqualSharePayment(
                              index,
                              method,
                              paid,
                            ),
                      );
                    },
                  ),

                  // Tab 2: Seat Split Shares
                  ListView.separated(
                    itemCount: _seatSplitResult.shares.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (ctx, index) {
                      final share = _seatSplitResult.shares[index];
                      return _buildShareCard(
                        share: share,
                        showItems: true,
                        onPaymentChanged:
                            (paid, method) =>
                                _updateSeatSharePayment(index, method, paid),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: () {
            // Update waiter tip & stats
            ref
                .read(waiterShiftControllerProvider.notifier)
                .recordTableCheckout(
                  tableBill: activeResult.originalTotal,
                  tipAmount: _tipAmount,
                  isCashTip: true,
                  guestCount: _guestCount,
                );

            Navigator.pop(context, activeResult);
          },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: Text(
            activeResult.isFullySettled
                ? 'تأكيد السداد الكامل (${Formatters.formatCurrency(activeResult.originalTotal)})'
                : 'حفظ وتأكيد التقسيم',
          ),
        ),
      ],
    );
  }

  Widget _buildShareCard({
    required SplitBillShare share,
    required void Function(bool isPaid, PaymentMethod method) onPaymentChanged,
    bool showItems = false,
  }) {
    final isPaid = share.isPaid;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            isPaid
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isPaid
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                share.guestLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.formatCurrency(share.totalAmount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color:
                      isPaid
                          ? const Color(0xFF10B981)
                          : const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          if (showItems && share.itemNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              share.itemNames.join(' • '),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              // Payment method choice
              DropdownButton<PaymentMethod>(
                value: share.paymentMethod,
                isDense: true,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: const [
                  DropdownMenuItem(
                    value: PaymentMethod.cash,
                    child: Text('💵 كاش'),
                  ),
                  DropdownMenuItem(
                    value: PaymentMethod.card,
                    child: Text('💳 بطاقة / فيزا'),
                  ),
                ],
                onChanged: (method) {
                  if (method != null) {
                    onPaymentChanged(share.isPaid, method);
                  }
                },
              ),
              const Spacer(),
              ChoiceChip(
                label: Text(
                  isPaid ? 'تم الدفع ✅' : 'سداد الحصة',
                  style: TextStyle(
                    fontSize: 11,
                    color: isPaid ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selectedColor: const Color(0xFF10B981),
                selected: isPaid,
                onSelected: (val) {
                  onPaymentChanged(val, share.paymentMethod);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
