import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mhj_maps/mhj_maps.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

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

  // Default Riyadh coordinates
  static const MhjMapsLatLng _restaurantLatLng = MhjMapsLatLng(lat: 24.7136, lng: 46.6753);
  static const MhjMapsLatLng _customerLatLng = MhjMapsLatLng(lat: 24.7236, lng: 46.6953);
  MhjMapsLatLng _driverLatLng = const MhjMapsLatLng(lat: 24.7180, lng: 46.6850);

  @override
  void initState() {
    super.initState();
    _initRealtime();
  }

  void _initRealtime() {
    final realtime = ref.read(realtimeServiceProvider);
    _realtimeSub = realtime.events.listen((event) {
      if (event.type == RealtimeEventType.driverLocationUpdated) {
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

          // ── Map View with MhjMaps ─────────────────────────────────────
          Expanded(
            flex: 3,
            child: ClipRRect(
              child: MhjMapsMap(
                center: _driverLatLng,
                zoom: 14,
                theme: isDark ? MhjMapsMapThemes.darkElegant : MhjMapsMapThemes.voyager,
                showZoomControls: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _updateMapMarkers();
                },
              ),
            ),
          ),

          // ── Driver Info & Order Summary ────────────────────────────────
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Driver Info Card
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
                                  'الكابتن خالد العتيبي',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.9 (120 توصيلة)',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                Text(
                                  'دراجة نارية • لوحة: ٤١٢٥ أ ب',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.phone),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('جارٍ الاتصال بالسائق 0501234567...'),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stages[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        i <= currentStep ? FontWeight.bold : FontWeight.normal,
                    color: i <= currentStep
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87),
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
      child: const Icon(
        Icons.delivery_dining,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
