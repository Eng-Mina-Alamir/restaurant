import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/ticket_printer_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../orders/domain/entities/order_entity.dart';

class TicketPrintDialog extends ConsumerStatefulWidget {
  final OrderEntity order;
  final String? tableDisplay;

  const TicketPrintDialog({super.key, required this.order, this.tableDisplay});

  static Future<void> show(
    BuildContext context, {
    required OrderEntity order,
    String? tableDisplay,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          TicketPrintDialog(order: order, tableDisplay: tableDisplay),
    );
  }

  @override
  ConsumerState<TicketPrintDialog> createState() => _TicketPrintDialogState();
}

class _TicketPrintDialogState extends ConsumerState<TicketPrintDialog> {
  bool _printing = false;

  @override
  Widget build(BuildContext context) {
    final printerService = ref.watch(ticketPrinterServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final ticketText = printerService.generateTicketText(
      widget.order,
      tableDisplay: widget.tableDisplay,
    );

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.print_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'معاينة تذكرة الطباعة الحرارية',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            // Receipt "paper" look built from neutral surface roles so the
            // metaphor holds in both themes without amber/brown hues.
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant,
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'ESC/POS Thermal 80mm',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                ticketText,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFamily: 'Courier',
                  height: 1.4,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          icon: _printing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.print),
          label: const Text('طباعة التذكرة الآن'),
          onPressed: _printing
              ? null
              : () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  // Captured before the async gap so the snackbar tone matches
                  // the brightness active when printing started.
                  final brightness = Theme.of(context).brightness;
                  setState(() => _printing = true);
                  final success = await printerService.printKitchenTicket(
                    widget.order,
                    tableDisplay: widget.tableDisplay,
                  );
                  if (!mounted) return;
                  setState(() => _printing = false);
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'تم إرسال أمر الطباعة إلى طابعة المطبخ بنجاح!'
                            : 'فشل الاتصال بالطابعة الحرارية',
                      ),
                      backgroundColor: success
                          ? StatusColors.tone(
                              SemanticTone.success,
                              brightness,
                            )
                          : StatusColors.tone(SemanticTone.danger, brightness),
                    ),
                  );
                },
        ),
      ],
    );
  }
}
