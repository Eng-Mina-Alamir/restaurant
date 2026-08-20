import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/ticket_printer_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../orders/domain/entities/order_entity.dart';

class TicketPrintDialog extends ConsumerStatefulWidget {
  final OrderEntity order;
  final String? tableDisplay;

  const TicketPrintDialog({
    super.key,
    required this.order,
    this.tableDisplay,
  });

  static Future<void> show(
    BuildContext context, {
    required OrderEntity order,
    String? tableDisplay,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => TicketPrintDialog(
        order: order,
        tableDisplay: tableDisplay,
      ),
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
    final ticketText = printerService.generateTicketText(
      widget.order,
      tableDisplay: widget.tableDisplay,
    );

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print_outlined, color: Colors.indigo),
          SizedBox(width: 8),
          Expanded(
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
            color: Colors.amber.shade50.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: Colors.brown.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.brown,
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  '🧾 ESC/POS Thermal 80mm',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                ticketText,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.print),
          label: const Text('طباعة التذكرة الآن'),
          onPressed: _printing
              ? null
              : () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
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
                            ? '🖨️ تم إرسال أمر الطباعة إلى طابعة المطبخ بنجاح!'
                            : 'فشل الاتصال بالطابعة الحرارية',
                      ),
                      backgroundColor:
                          success ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  );
                },
        ),
      ],
    );

  }
}
