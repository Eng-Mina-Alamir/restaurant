import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/printing/ticket_printer_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/zatca_qr_codec.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../data/services/report_export_service.dart';

/// Manager & Cashier page that lists completed orders as printable invoices.
class InvoicesPage extends ConsumerWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final orders = ref.watch(ordersControllerProvider);
    final completedOrders =
        orders.where((o) => o.status == OrderStatus.completed).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.invoicesTitle),
        actions: [
          const LanguageSwitcherButton(compact: true),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: strings.exportCsv,
            onPressed: () {
              if (completedOrders.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.noInvoicesFound),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final exportService = ref.read(reportExportServiceProvider);
              final _ = exportService.generateInvoicesCsv(completedOrders);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${strings.exportCsvSuccess} (${completedOrders.length})',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ConstrainedContentView(
        child: completedOrders.isEmpty
          ? EmptyState(
              message: strings.noInvoicesFound,
              icon: Icons.receipt_long_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: completedOrders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _InvoiceCard(
                order: completedOrders[i],
                isArabic: strings.isArabic,
                onTap: () => _showInvoiceDetail(context, completedOrders[i]),
              ),
            ),
      ),
    );
  }

  void _showInvoiceDetail(BuildContext context, OrderEntity order) {
    showDialog<void>(
      context: context,
      builder: (_) => _InvoiceDialog(order: order),
    );
  }
}

// ── Invoice card ──────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.order,
    required this.isArabic,
    required this.onTap,
  });

  final OrderEntity order;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  Icons.receipt,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${Formatters.formatOrderId(order.id)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatters.formatDateTime(order.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${order.items.length} ${isArabic ? "أصناف" : "Items"} · ${order.orderType.localizedLabel(isArabic)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(order.totalAmount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: StatusColors.tone(
                        SemanticTone.success,
                        theme.brightness,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Text(
                      order.status.localizedLabel(isArabic),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: StatusColors.tone(
                          SemanticTone.success,
                          theme.brightness,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Invoice detail dialog ─────────────────────────────────────────────────────

class _InvoiceDialog extends ConsumerWidget {
  const _InvoiceDialog({required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.receipt_long, color: colorScheme.primary, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.invoices} #${Formatters.formatOrderId(order.id)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          Formatters.formatDateTime(order.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: strings.close,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Divider(height: AppSpacing.lg),

              // Items
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Text('${item.quantity}x '),
                      Expanded(child: Text(item.menuItem.name)),
                      Text(Formatters.formatCurrency(item.lineTotal)),
                    ],
                  ),
                ),
              ),

              const Divider(height: AppSpacing.lg),

              // Totals
              _TotalRow(
                label: strings.subtotal,
                value: Formatters.formatCurrency(order.subtotal),
              ),
              _TotalRow(
                label: strings.tax,
                value: Formatters.formatCurrency(order.taxAmount),
              ),
              if (order.discountAmount > 0)
                _TotalRow(
                  label: strings.discount,
                  value: '- ${Formatters.formatCurrency(order.discountAmount)}',
                  color: StatusColors.tone(
                    SemanticTone.success,
                    theme.brightness,
                  ),
                ),

              const Divider(),
              _TotalRow(
                label: strings.total,
                value: Formatters.formatCurrency(order.totalAmount),
                bold: true,
              ),

              const SizedBox(height: AppSpacing.md),

              // ZATCA e-Invoicing QR Code
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: QrImageView(
                        data: ZatcaQrCodec.generateBase64Qr(
                          sellerName: 'مطعم الأصالة والنكهة',
                          vatNumber: '300123456700003',
                          invoiceTimestamp: order.createdAt,
                          totalWithVat: order.totalAmount,
                          vatAmount: order.taxAmount,
                        ),
                        version: QrVersions.auto,
                        size: 130,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.taxInvoice,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: Text(strings.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.print_outlined),
                      label: Text(strings.printReceipt),
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(ticketPrinterServiceProvider)
                            .printCustomerInvoice(order);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${strings.receiptSentToPrinter} 🖨️'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.primary,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(color: color);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
