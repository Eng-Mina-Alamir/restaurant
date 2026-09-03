import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../reservations/domain/entities/reservation_entity.dart';
import '../../../reservations/presentation/controllers/reservation_controller.dart';
import '../../../table_management/domain/entities/restaurant_table.dart';
import '../../../table_management/presentation/controllers/table_controller.dart';

/// Interactive customer table reservation page allowing customers to pick a specific
/// table, date, time slot, party size, and view their active reservations.
class CustomerReservationsPage extends ConsumerStatefulWidget {
  const CustomerReservationsPage({super.key});

  @override
  ConsumerState<CustomerReservationsPage> createState() =>
      _CustomerReservationsPageState();
}

class _CustomerReservationsPageState
    extends ConsumerState<CustomerReservationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  int _guestCount = 2;
  String _selectedZone = 'الكل';
  RestaurantTable? _selectedTable;
  bool _isSubmitting = false;

  final List<String> _zones = ['الكل', 'صالة', 'حديقة', 'تراس', 'عائلات VIP'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        if (_nameController.text.isEmpty && user.name.isNotEmpty) {
          _nameController.text = user.name;
        }
        if (_phoneController.text.isEmpty && user.phone.isNotEmpty) {
          _phoneController.text = user.phone;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار طاولة محددة أولاً')),
      );
      return;
    }
    if (_guestCount > _selectedTable!.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text(
            'سعة الطاولة المختارة (${_selectedTable!.capacity} ضيوف) أقل من عدد الضيوف المطلوب ($_guestCount ضيوف). يرجى اختيار طاولة تتسع لـ $_guestCount ضيوف أو أكثر.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(reservationControllerProvider.notifier)
        .createReservation(
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          tableId: _selectedTable!.id,
          tableNumber: _selectedTable!.tableNumber,
          guestCount: _guestCount,
          reservationTime: _combinedDateTime,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            'تم تأكيد حجز طاولة ${_selectedTable!.tableNumber} بنجاح! بانتظاركم في الموعد المحدد 🎉',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      setState(() => _selectedTable = null);
      _tabController.animateTo(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('تعذر إتمام الحجز، يرجى المحاولة مرة أخرى.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز طاولة في المطعم'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event_seat_rounded), text: 'حجز طاولة جديدة'),
            Tab(icon: Icon(Icons.bookmark_added_rounded), text: 'حجوزاتي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewReservationTab(colorScheme, theme),
          _buildMyReservationsTab(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildNewReservationTab(ColorScheme colorScheme, ThemeData theme) {
    final tablesState = ref.watch(tableControllerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tableControllerProvider);
        ref.invalidate(reservationControllerProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Restaurant Reservation Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.surfaceContainerHighest,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مطعم ليالي المحروسة 🍽️',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'اختر الطاولة المفضلة وموعد زيارتك للاستمتاع بأشهى المشويات',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Date & Time Selection ──
              Text(
                'موعد الحجز وعدد الضيوف:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                        Formatters.formatDate(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Guest Count Selector
              Row(
                children: [
                  const Text(
                    'عدد الأفراد: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: _guestCount > 1
                        ? () => setState(() => _guestCount--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      '$_guestCount ضيوف',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: _guestCount < 16
                        ? () => setState(() => _guestCount++)
                        : null,
                  ),
                ],
              ),

              const Divider(height: AppSpacing.xl),

              // ── Table Zone Filter & Selection ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اختر الطاولة المحددة:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedTable != null)
                    Chip(
                      backgroundColor: colorScheme.primaryContainer,
                      avatar: const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        'طاولة ${_selectedTable!.tableNumber} (${_selectedTable!.location})',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onDeleted: () => setState(() => _selectedTable = null),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Zone Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _zones.map((zone) {
                    final isSelected = _selectedZone == zone;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(zone),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedZone = zone);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Table Grid
              Builder(
                builder: (context) {
                  final filtered = tablesState.where((t) {
                    if (_selectedZone == 'الكل') return true;
                    return t.location.contains(_selectedZone) ||
                        _selectedZone.contains(t.location);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      alignment: Alignment.center,
                      child: const Text('لا توجد طاولات مطابقة في هذا القسم'),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final table = filtered[index];
                      final isSelected = _selectedTable?.id == table.id;
                      final isAvailable = table.status == TableStatus.available;

                      Color borderColor = Colors.grey.shade300;
                      Color cardColor = colorScheme.surface;

                      if (isSelected) {
                        borderColor = colorScheme.primary;
                        cardColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
                      } else if (!isAvailable) {
                        cardColor = Colors.grey.shade100;
                      }

                      final isCapacitySufficient = table.capacity >= _guestCount;

                      return InkWell(
                        onTap: !isAvailable
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'طاولة ${table.tableNumber} ${table.status.labelAr} حالياً، اختر طاولة أخرى متاحة.',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : (!isCapacitySufficient)
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'طاولة ${table.tableNumber} تتسع لـ ${table.capacity} أفراد فقط، بينما الحجز لـ $_guestCount ضيوف. اختر طاولة تتسع لـ $_guestCount ضيوف أو أكثر.',
                                        ),
                                        backgroundColor: Colors.orange.shade800,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                : () => setState(() => _selectedTable = table),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: borderColor,
                              width: isSelected ? 2.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAvailable
                                    ? (isCapacitySufficient ? Icons.table_restaurant_rounded : Icons.people_outline_rounded)
                                    : Icons.do_not_disturb_on_rounded,
                                size: 28,
                                color: isSelected
                                    ? colorScheme.primary
                                    : isAvailable
                                        ? (isCapacitySufficient ? const Color(0xFF10B981) : Colors.amber.shade700)
                                        : Colors.grey.shade500,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'طاولة ${table.tableNumber}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${table.capacity} أفراد • ${table.location}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isCapacitySufficient
                                      ? colorScheme.onSurfaceVariant
                                      : Colors.amber.shade800,
                                  fontWeight: isCapacitySufficient ? FontWeight.normal : FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? (isCapacitySufficient
                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                          : Colors.amber.withValues(alpha: 0.2))
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  isAvailable
                                      ? (isCapacitySufficient ? 'متاحة' : 'سعة غير كافية')
                                      : 'محجوزة',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable
                                        ? (isCapacitySufficient ? const Color(0xFF10B981) : Colors.amber.shade900)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const Divider(height: AppSpacing.xl),

              // ── Guest Contact & Notes ──
              Text(
                'بيانات التواصل والملاحظات:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم صاحب الحجز *',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'يرجى كتابة الاسم' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف للتأكيد *',
                  prefixIcon: Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'يرجى كتابة رقم الهاتف' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'مناسبة خاصة أو رغبات محددة (اختياري)',
                  hintText: 'مثال: عيد ميلاد / طاولة هادئة بجوار النافذة',
                  prefixIcon: Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitReservation,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'جاري تأكيد الحجز...'
                        : 'تأكيد حجز الطاولة الآن',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyReservationsTab(ColorScheme colorScheme, ThemeData theme) {
    final reservationsState = ref.watch(reservationControllerProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reservationControllerProvider),
      child: reservationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('تعذر تحميل الحجوزات: $err')),
        data: (reservations) {
          final phone = _phoneController.text.trim();
          final myReservations = reservations.where((r) {
            if (phone.isNotEmpty) {
              return r.customerPhone.trim() == phone ||
                  r.customerName.trim() == _nameController.text.trim();
            }
            return true;
          }).toList()
            ..sort((a, b) => b.reservationTime.compareTo(a.reservationTime));

          if (myReservations.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_seat_outlined,
                      size: 64,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'لا توجد حجوزات نشطة حالياً',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'يمكنك حجز طاولتك المفضلة مسبقاً في أي وقت بنقرة واحدة!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.add),
                      label: const Text('حجز طاولة الآن'),
                      onPressed: () => _tabController.animateTo(0),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: myReservations.length,
            separatorBuilder: (ctx, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final res = myReservations[index];
              final isPast = res.reservationTime.isBefore(DateTime.now());
              final isCancelled = res.status == ReservationStatus.cancelled;

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(
                    color: isCancelled
                        ? Colors.red.withValues(alpha: 0.3)
                        : colorScheme.outlineVariant,
                  ),
                ),
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(
                                  Icons.table_restaurant_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'طاولة رقم ${res.tableNumber}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${res.guestCount} ضيوف • ${Formatters.formatDateTime(res.reservationTime)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(res.status.labelAr),
                            backgroundColor: isCancelled
                                ? Colors.red.withValues(alpha: 0.15)
                                : isPast
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : const Color(0xFF10B981).withValues(alpha: 0.15),
                          ),
                        ],
                      ),
                      if (res.notes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            'ملاحظات: ${res.notes}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                      if (!isPast && !isCancelled) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('إلغاء هذا الحجز'),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('إلغاء حجز الطاولة'),
                                  content: Text(
                                    'هل أنت متأكد من إلغاء حجز طاولة ${res.tableNumber}؟',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('رجوع'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colorScheme.error,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('نعم، إلغاء الحجز'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref
                                    .read(reservationControllerProvider.notifier)
                                    .cancelReservation(res);
                              }
                            },
                          ),
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
    );
  }
}
