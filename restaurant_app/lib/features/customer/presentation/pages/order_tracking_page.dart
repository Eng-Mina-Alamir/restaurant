import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mhj_maps/mhj_maps.dart';

import '../../../delivery/domain/entities/delivery_assignment.dart';
import '../../../delivery/presentation/controllers/delivery_controller.dart';
import '../../../delivery/presentation/widgets/live_tracking_map.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

/// Whether a [RealtimeEventType.driverLocationUpdated] payload targets
/// tracking of [orderId].
///
/// New broadcasts carry an explicit `orderId`; legacy payloads (sent before
/// order scoping existed) are accepted only when their `driverId` matches the
/// driver assigned to this order.
bool driverLocationTargetsOrder({
  required Map<String, dynamic> payload,
  required String orderId,
  String? assignedDriverId,
}) {
  final payloadOrderId = payload['orderId']?.toString();
  if (payloadOrderId != null && payloadOrderId.isNotEmpty) {
    return payloadOrderId == orderId;
  }
  final payloadDriverId = payload['driverId']?.toString();
  if (payloadDriverId == null ||
      payloadDriverId.isEmpty ||
      assignedDriverId == null) {
    return false;
  }
  return payloadDriverId == assignedDriverId;
}

/// Live order tracking page for customer with visual stage progress and live map powered by [mhj_maps].
class OrderTrackingPage extends ConsumerStatefulWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  MhjMapsMapController? _mapController;
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  // Driver id of the assignment resolved for this order — used as the legacy
  // (orderId-less) fallback key for driver location events.
  String? _assignedDriverId;

  // Cairo Coordinates (Downtown, Nile, Zamalek)
  static const MhjMapsLatLng _restaurantLatLng = MhjMapsLatLng(
    lat: 30.0444,
    lng: 31.2357,
  );
  static const MhjMapsLatLng _customerLatLng = MhjMapsLatLng(
    lat: 30.0626,
    lng: 31.2497,
  );
  MhjMapsLatLng _driverLatLng = const MhjMapsLatLng(lat: 30.0510, lng: 31.2410);

  @override
  void initState() {
    super.initState();
    _initRealtime();
  }

  void _initRealtime() {
    final realtime = ref.read(realtimeServiceProvider);
    _realtimeSub = realtime.events.listen((event) {
      if (event.type == RealtimeEventType.driverLocationUpdated) {
        // Only react to updates belonging to THIS order; events carrying an
        // explicit orderId must match it, legacy events must come from this
        // order's assigned driver.
        if (!driverLocationTargetsOrder(
          payload: event.payload,
          orderId: widget.orderId,
          assignedDriverId: _assignedDriverId,
        )) {
          return;
        }
        try {
          final lat = (event.payload['latitude'] as num?)?.toDouble();
          final lng = (event.payload['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null && mounted) {
            setState(() {
              _driverLatLng = MhjMapsLatLng(lat: lat, lng: lng);
            });
            _updateMapMarkers();
          }
        } catch (_) {}
      }
    });
  }

  void _updateMapMarkers() {
    final ctrl = _mapController;
    if (ctrl == null) return;

    ctrl.clearMarkers();

    // 1. Restaurant Pin
    ctrl.addCustomMarker(
      position: _restaurantLatLng,
      child: const _PinMarker(
        icon: Icons.restaurant,
        color: Colors.orange,
        label: 'المطعم',
      ),
    );

    // 2. Customer Pin
    ctrl.addCustomMarker(
      position: _customerLatLng,
      child: const _PinMarker(
        icon: Icons.home,
        color: Colors.green,
        label: 'موقعك',
      ),
    );

    // 3. Driver Moving Pin
    ctrl.addCustomMarker(
      position: _driverLatLng,
      child: _DriverMarker(color: Theme.of(context).colorScheme.primary),
    );
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Live delivery assignment for this order (driver identity + position).
    final assignmentAsync = ref.watch(
      deliveryAssignmentForOrderProvider(widget.orderId),
    );

    ref.listen<AsyncValue<DeliveryAssignment?>>(
      deliveryAssignmentForOrderProvider(widget.orderId),
      (previous, next) {
        final assignment = next.valueOrNull;
        if (assignment == null) return;
        _assignedDriverId = assignment.driverId;
        if (assignment.latitude != 0 || assignment.longitude != 0) {
          setState(() {
            _driverLatLng = MhjMapsLatLng(
              lat: assignment.latitude,
              lng: assignment.longitude,
            );
          });
          _updateMapMarkers();
        }
      },
    );

    final order = orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => OrderEntity(
        id: widget.orderId,
        restaurantId: 'demo-rest',
        items: const [],
        status: OrderStatus.preparing,
        orderType: OrderType.delivery,
        subtotal: 75.0,
        taxAmount: 11.25,
        discountAmount: 0.0,
        totalAmount: 86.25,
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    );

    final currentStep = _getStepIndex(order.status);

    // Driver identity comes exclusively from the fetched assignment — no
    // fabricated drivers. While searching / unassigned we show placeholders.
    final assignment = assignmentAsync.valueOrNull;
    final String driverTitle;
    final Widget driverSubtitle;
    if (assignmentAsync.isLoading || assignment == null) {
      driverTitle = 'جارٍ البحث عن مندوب…';
      driverSubtitle = assignmentAsync.isLoading
          ? SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Text(
              'لم يتم تعيين مندوب لهذا الطلب بعد',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            );
    } else {
      driverTitle = assignment.driverName ?? 'مندوب التوصيل';
      driverSubtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (assignment.driverRating != null)
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  'تقييم المندوب: ${assignment.driverRating!.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          if (assignment.vehicleInfo != null)
            Text(
              assignment.vehicleInfo!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('تتبع الطلب ${Formatters.formatOrderId(order.id)}'),
      ),
      body: Column(
        children: [
          // ── Real-time Status Stepper Header ────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حالة الطلب: ${order.status.labelAr}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _statusColor(order.status),
                      ),
                    ),
                    Text(
                      'وقت الوصول المتوقع: 20 دقيقة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _OrderStepper(currentStep: currentStep),
              ],
            ),
          ),

          // ── Map View with Comprehensive LiveTrackingMap ─────────────
          Expanded(
            flex: 3,
            child: LiveTrackingMap(
              pickupLatLng: LatLng(
                _restaurantLatLng.lat,
                _restaurantLatLng.lng,
              ),
              deliveryLatLng: LatLng(_customerLatLng.lat, _customerLatLng.lng),
              pickupLabel: 'المطعم',
              deliveryLabel: 'عنوانك',
              initialTheme: isDark
                  ? AppMapThemeOption.dark
                  : AppMapThemeOption.voyager,
              showControls: true,
              showNavigationHud: true,
              showDeliveryRadius: true,
            ),
          ),

          // ── Driver Info & Order Summary ────────────────────────────────
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Driver Info Card — live data from the order's assignment
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.delivery_dining, size: 28),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                driverSubtitle,
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.phone),
                            tooltip: 'اتصال بالمندوب',
                            onPressed: () {
                              final phone = assignment?.driverPhone;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    phone != null && phone.isNotEmpty
                                        ? 'جارٍ الاتصال بالمندوب $phone...'
                                        : 'لا يوجد رقم للمندوب حتى الآن',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Order Total & Item Count
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الإجمالي: ${Formatters.formatCurrency(order.totalAmount)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${order.items.fold<int>(0, (sum, i) => sum + i.quantity)} أصناف',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Chat with the assigned driver — offered only once an
                  // assignment actually exists (no driver → no thread).
                  if (assignment != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () =>
                            context.push('/chat/${widget.orderId}'),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('محادثة السائق'),
                      ),
                    ),
                  ],

                  // Cancel — offered ONLY while the order is still pending;
                  // once preparation starts it can no longer be undone.
                  if (order.status == OrderStatus.pending) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        onPressed: _confirmCancellation,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('إلغاء الطلب'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Asks for confirmation, then cancels the order through the orders
  /// controller (persisted + broadcast), shows success feedback and leaves
  /// the tracking page.
  Future<void> _confirmCancellation() async {
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text(
          'هل أنت متأكد من إلغاء الطلب؟ لا يمكن التراجع بعد بدء التحضير',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref
        .read(ordersControllerProvider.notifier)
        .updateStatus(widget.orderId, OrderStatus.cancelled);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب بنجاح')));
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  int _getStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
      case OrderStatus.served:
        return 3;
      case OrderStatus.completed:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.amber.shade800;
      case OrderStatus.ready:
      case OrderStatus.served:
        return Colors.teal;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

class _OrderStepper extends StatelessWidget {
  const _OrderStepper({required this.currentStep});

  final int currentStep;

  static const List<String> _stages = [
    'تم الطلب',
    'مؤكد',
    'قيد الإعداد',
    'في الطريق',
    'تم التسليم',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (int i = 0; i < _stages.length; i++) ...[
          Expanded(
            // Completion state is conveyed visually by fill color and bold
            // weight; spell the state out for screen readers.
            child: Semantics(
              label: i < currentStep
                  ? '${_stages[i]} — مكتملة'
                  : i == currentStep
                  ? '${_stages[i]} — المرحلة الحالية'
                  : '${_stages[i]} — لم تُكتمل بعد',
              excludeSemantics: true,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: i <= currentStep
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    foregroundColor: Colors.white,
                    child: i < currentStep
                        ? const Icon(Icons.check, size: 14)
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stages[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: i <= currentStep
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i <= currentStep
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i < _stages.length - 1)
            Container(
              height: 2,
              width: 16,
              margin: const EdgeInsets.only(bottom: 14),
              color: i < currentStep
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverMarker extends StatelessWidget {
  const _DriverMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
    );
  }
}
