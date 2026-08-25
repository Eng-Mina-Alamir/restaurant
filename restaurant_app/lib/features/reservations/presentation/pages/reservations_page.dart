import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/entities/reservation_entity.dart';
import '../controllers/reservation_controller.dart';
import '../../../table_management/presentation/controllers/table_controller.dart';

/// Interactive management page for restaurant table bookings and reservations.
class ReservationsPage extends ConsumerStatefulWidget {
  const ReservationsPage({super.key});

  @override
  ConsumerState<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends ConsumerState<ReservationsPage> {
  ReservationStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(reservationControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحجوزات'),
        actions: [
          IconButton(
            tooltip: 'إضافة حجز جديد',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddReservationDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReservationDialog(context),
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('حجز طاولة'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('كل الحجوزات'),
                  selected: _filterStatus == null,
                  onSelected: (_) => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: AppSpacing.xs),
                for (final status in ReservationStatus.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(status.labelAr),
                      selected: _filterStatus == status,
                      onSelected: (_) => setState(() => _filterStatus = status),
                    ),
                  ),
              ],
            ),
          ),

          // List View
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(reservationControllerProvider),
              child: reservationsAsync.when(
                loading: () => const _ReservationSkeletonList(),
                error: (err, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: ErrorState(
                        message: AppConstants.errorLoadingData,
                        errorDetail: err,
                        onRetry: () =>
                            ref.refresh(reservationControllerProvider),
                      ),
                    ),
                  ],
                ),
                data: (list) {
                  final filtered = _filterStatus == null
                      ? list
                      : list.where((r) => r.status == _filterStatus).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const EmptyState(
                            message: 'لا توجد حجوزات مسجلة',
                            icon: Icons.event_busy_outlined,
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      80,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final res = filtered[index];
                      final statusColor = _statusColor(
                        res.status,
                        theme.brightness,
                      );
                      // Accents for the confirmed-only action row below.
                      final actionDanger = StatusColors.tone(
                        SemanticTone.danger,
                        theme.brightness,
                      );
                      final actionSuccess = StatusColors.tone(
                        SemanticTone.success,
                        theme.brightness,
                      );
                      final timeFormatted = DateFormat(
                        'hh:mm a - yyyy/MM/dd',
                        'ar',
                      ).format(res.reservationTime);

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        foregroundColor:
                                            colorScheme.onPrimaryContainer,
                                        child: const Icon(Icons.person),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            res.customerName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            res.customerPhone,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.full,
                                      ),
                                    ),
                                    child: Text(
                                      res.status.labelAr,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: AppSpacing.md),
                              Row(
                                children: [
                                  const Icon(Icons.table_restaurant, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'طاولة رقم: ${res.tableNumber}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  const Icon(Icons.groups_outlined, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${res.guestCount} أفراد',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'الموعد: $timeFormatted',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              if (res.notes != null &&
                                  res.notes!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.notes, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'ملاحظات: ${res.notes}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (res.status ==
                                  ReservationStatus.confirmed) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: actionDanger,
                                        side: BorderSide(color: actionDanger),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('إلغاء الحجز'),
                                      onPressed: () {
                                        ref
                                            .read(
                                              reservationControllerProvider
                                                  .notifier,
                                            )
                                            .cancelReservation(res);
                                      },
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: actionSuccess,
                                        foregroundColor:
                                            colorScheme.onPrimary,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(Icons.chair, size: 16),
                                      label: const Text('إجلاس الضيوف'),
                                      onPressed: () {
                                        ref
                                            .read(
                                              reservationControllerProvider
                                                  .notifier,
                                            )
                                            .seatCustomer(res);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'تم إجلاس ${res.customerName} على طاولة ${res.tableNumber}',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reservation statuses resolved onto audited [SemanticTone] steps so both
  /// brightness modes keep >= 4.5:1 contrast (see [StatusColors.tone]).
  Color _statusColor(ReservationStatus status, Brightness brightness) {
    return switch (status) {
      ReservationStatus.confirmed => StatusColors.tone(
        SemanticTone.info,
        brightness,
      ),
      ReservationStatus.seated => StatusColors.tone(
        SemanticTone.success,
        brightness,
      ),
      ReservationStatus.cancelled => StatusColors.tone(
        SemanticTone.danger,
        brightness,
      ),
      ReservationStatus.pending => StatusColors.tone(
        SemanticTone.warning,
        brightness,
      ),
      ReservationStatus.completed => StatusColors.tone(
        SemanticTone.neutral,
        brightness,
      ),
    };
  }

  void _showAddReservationDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final guestsCtrl = TextEditingController(text: '2');
    final notesCtrl = TextEditingController();

    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 2));

    final tables = ref.read(tableControllerProvider);
    String selectedTableId = tables.isNotEmpty ? tables.first.id : 't1';
    int selectedTableNumber = tables.isNotEmpty ? tables.first.tableNumber : 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حجز طاولة جديد',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: guestsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'عدد الأفراد *',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedTableId,
                        items: tables
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  'طاولة ${t.tableNumber} (${t.capacity} كراسي)',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final table = tables.firstWhere((t) => t.id == val);
                            setSheetState(() {
                              selectedTableId = val;
                              selectedTableNumber = table.tableNumber;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'الطاولة *',
                          prefixIcon: Icon(Icons.table_restaurant),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  tileColor: Theme.of(
                    ctx,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('تاريخ ووقت الحجز'),
                  subtitle: Text(
                    DateFormat(
                      'yyyy/MM/dd - hh:mm a',
                      'ar',
                    ).format(selectedDateTime),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null && ctx.mounted) {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setSheetState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات خاصة (اختياري)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final guests = int.tryParse(guestsCtrl.text.trim()) ?? 2;

                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى ملء الاسم ورقم الهاتف'),
                        ),
                      );
                      return;
                    }

                    ref
                        .read(reservationControllerProvider.notifier)
                        .createReservation(
                          customerName: name,
                          customerPhone: phone,
                          tableId: selectedTableId,
                          tableNumber: selectedTableNumber,
                          guestCount: guests,
                          reservationTime: selectedDateTime,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('تأكيد وحفظ الحجز'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationSkeletonList extends StatelessWidget {
  const _ReservationSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        80,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => const Card(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SkeletonCircle(size: 40),
                      SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 120, height: 16),
                          SizedBox(height: AppSpacing.xs),
                          SkeletonBox(width: 80, height: 12),
                        ],
                      ),
                    ],
                  ),
                  SkeletonBox(
                    width: 70,
                    height: 24,
                    borderRadius: AppRadius.full,
                  ),
                ],
              ),
              Divider(height: AppSpacing.lg),
              Row(
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(width: AppSpacing.md),
                  SkeletonBox(width: 60, height: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
