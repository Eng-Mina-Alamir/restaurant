import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:mhj_maps/mhj_maps.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../delivery/domain/entities/delivery_assignment.dart';
import '../../../delivery/domain/services/delivery_pin_service.dart';
import '../../../delivery/presentation/controllers/delivery_controller.dart';
import '../../../delivery/presentation/controllers/delivery_pin_controller.dart';
import '../../../delivery/presentation/widgets/live_tracking_map.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/network/realtime_event.dart';
import '../../../../core/supabase/supabase_realtime_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/curbside_controller.dart';
import '../controllers/customer_wallet_controller.dart';

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
  final payloadOrderId = (payload['order_id'] ?? payload['orderId'])?.toString();
  if (payloadOrderId != null && payloadOrderId.isNotEmpty) {
    return payloadOrderId == orderId;
  }
  final payloadDriverId = (payload['driver_id'] ?? payload['driverId'])?.toString();
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

  /// Whether a delivery-assignment event payload belongs to THIS order.
  ///
  /// Server rows key assignments by the numeric `orders.id`, while the app
  /// also uses `order_number` text (e.g. `ORD-0042`) pre-persistence — accept
  /// either shape so the "driver assigned" flip works on both paths.
  bool _assignmentTargetsOrder(Map<String, dynamic> payload) {
    final candidates = <String?>[
      payload['order_id']?.toString(),
      payload['orderId']?.toString(),
      payload['order_number']?.toString(),
      payload['orderNumber']?.toString(),
    ];
    return candidates.any(
      (c) => c != null && c.isNotEmpty && c == widget.orderId,
    );
  }

  void _onDriverAssigned() {
    // Re-fetch the enriched assignment (driver name/rating/phone via the
    // profiles join) so the card flips from "searching" to the driver live.
    ref.invalidate(deliveryAssignmentForOrderProvider(widget.orderId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تعيين مندوب التوصيل لطلبك ✅'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _initRealtime() {
    final realtime = ref.read(supabaseRealtimeServiceProvider);
    _realtimeSub = realtime.events.listen((event) {
      if (event.type == RealtimeEventType.deliveryAssignmentCreated ||
          event.type == RealtimeEventType.deliveryAssignmentUpdated) {
        if (_assignmentTargetsOrder(event.payload)) _onDriverAssigned();
        return;
      }
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
    final brightness = Theme.of(context).brightness;

    ctrl.clearMarkers();

    // 1. Restaurant Pin
    ctrl.addCustomMarker(
      position: _restaurantLatLng,
      child: _PinMarker(
        icon: Icons.restaurant,
        color: StatusColors.tone(SemanticTone.warning, brightness),
        label: 'المطعم',
      ),
    );

    // 2. Customer Pin
    ctrl.addCustomMarker(
      position: _customerLatLng,
      child: _PinMarker(
        icon: Icons.home,
        color: StatusColors.tone(SemanticTone.success, brightness),
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

    // Per-order RANDOM verification code (stable per order, random across
    // orders). Minted on first view, shared with the driver's dialog.
    final pinAsync = ref.watch(deliveryPinProvider(widget.orderId));

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

    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('تتبع الطلب ${Formatters.formatOrderId(widget.orderId)}'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'جارٍ تحديث بيانات الطلب…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final assignment = assignmentAsync.valueOrNull;
    final isDelivery = order.orderType == OrderType.delivery;
    final isDineIn = order.orderType == OrderType.dineIn;
    final isTakeaway = order.orderType == OrderType.takeaway;

    final isDriverConfirmed = assignment != null &&
        assignment.deliveryStatus != DeliveryStatus.pending &&
        assignment.deliveryStatus != DeliveryStatus.failed;

    final currentStep = _getStepIndex(
      order.status,
      assignment: assignment,
      isDelivery: isDelivery,
    );

    final List<String> stages;
    if (isDineIn) {
      stages = const ['تم الطلب', 'تأكيد المطبخ', 'جاري الطهي', 'جاهز للتقديم', 'تم التقديم'];
    } else if (isTakeaway) {
      stages = const ['تم الطلب', 'تأكيد المطبخ', 'جاري التجهيز', 'جاهز للاستلام', 'تم الاستلام'];
    } else {
      stages = const ['تم الطلب', 'قيد الإعداد', 'جاهز بالمطعم', 'في الطريق', 'تم التسليم'];
    }

    final canCancel = (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed) &&
        (order.assignedKitchenId == null || order.assignedKitchenId!.isEmpty) &&
        order.status != OrderStatus.preparing &&
        order.status != OrderStatus.ready &&
        !order.status.isTerminal;

    // Driver identity comes exclusively from the fetched assignment
    final String driverTitle;
    final Widget driverSubtitle;
    if (assignmentAsync.isLoading || assignment == null || !isDriverConfirmed) {
      driverTitle = assignment != null && assignment.deliveryStatus == DeliveryStatus.pending
          ? 'بانتظار تأكيد الكابتن ⏳'
          : 'جارٍ البحث عن مندوب…';
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
              assignment != null && assignment.deliveryStatus == DeliveryStatus.pending
                  ? 'تم إرسال الطلب للمندوب وبانتظار موافقته'
                  : 'لم يتم تعيين مندوب لهذا الطلب بعد',
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
                Icon(
                  Icons.star,
                  size: 16,
                  color: StatusColors.starRating(theme.brightness),
                ),
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
                        color: StatusColors.order(order.status, theme.brightness),
                      ),
                    ),
                    Text(
                      isDineIn
                          ? 'طلب صالة'
                          : isTakeaway
                              ? 'استلام فرع'
                              : 'وقت الوصول: 20 دقيقة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (order.status != OrderStatus.cancelled) ...[
                  const SizedBox(height: AppSpacing.md),
                  _OrderStepper(currentStep: currentStep, stages: stages),
                ],
              ],
            ),
          ),

          // ── Cancelled Order State ──────────────────────────────────────
          if (order.status == OrderStatus.cancelled) ...[
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Card(
                    elevation: 1,
                    color: colorScheme.errorContainer.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 64,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'تم إلغاء هذا الطلب',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            order.paymentMethod == PaymentMethod.wallet
                                ? 'تم استرداد قيمة الطلب بالكامل إلى رصيد محفظتك.'
                                : 'تم إلغاء الطلب بنجاح ولن يتم تحضيره أو إرساله.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('رجوع للرئيسية'),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else if (isDelivery) ...[
            // ── Map View with Comprehensive LiveTrackingMap ─────────────
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  LiveTrackingMap(
                    pickupLatLng: LatLng(
                      _restaurantLatLng.lat,
                      _restaurantLatLng.lng,
                    ),
                    deliveryLatLng: LatLng(_customerLatLng.lat, _customerLatLng.lng),
                    driverLatLng: (isDriverConfirmed && (assignment.latitude != 0 || assignment.longitude != 0))
                        ? LatLng(assignment.latitude, assignment.longitude)
                        : null,
                    trackDeviceGps: false,
                    pickupLabel: 'المطعم',
                    deliveryLabel: 'عنوانك',
                    initialTheme: isDark
                        ? AppMapThemeOption.dark
                        : AppMapThemeOption.standard,
                    showControls: true,
                    showNavigationHud: true,
                    showDeliveryRadius: true,
                  ),
                  // Prominent Google Maps External Launch Action
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        elevation: 3,
                        backgroundColor: colorScheme.surface,
                      ),
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('فتح في خرائط Google', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final lat = assignment != null && assignment.latitude != 0
                            ? assignment.latitude
                            : _customerLatLng.lat;
                        final lng = assignment != null && assignment.longitude != 0
                            ? assignment.longitude
                            : _customerLatLng.lng;
                        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Driver Info, OTP PIN & Order Summary ─────────────────────
            Expanded(
              flex: 3,
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ordersControllerProvider);
                  ref.invalidate(
                    deliveryAssignmentForOrderProvider(widget.orderId),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                  children: [
                    // Delivery Confirmation PIN Card (per-order RANDOM code).
                    if (isDelivery)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primaryContainer.withValues(alpha: 0.7),
                              colorScheme.surfaceContainerHighest,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: pinAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, _) => Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('تعذر تجهيز كود الاستلام'),
                              ),
                              TextButton(
                                onPressed: () => ref.invalidate(
                                  deliveryPinProvider(widget.orderId),
                                ),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                          data: (pin) {
                            if (pin == null || pin.isEmpty) {
                              return Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('تعذر تجهيز كود الاستلام'),
                                  ),
                                  TextButton(
                                    onPressed: () => ref.invalidate(
                                      deliveryPinProvider(widget.orderId),
                                    ),
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              );
                            }
                            final qrData =
                                DeliveryPinService.qrPayloadFor(
                                  orderId: order.id,
                                  code: pin,
                                );
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.pin_outlined,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'رمز تأكيد الاستلام (OTP):',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      tooltip: 'نسخ الكود',
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: pin),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'تم نسخ كود الاستلام بنجاح ✅',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                        border: Border.all(
                                          color: colorScheme.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        pin,
                                        style: theme
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 6,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.sm,
                                        ),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: QrImageView(
                                        data: qrData,
                                        version: QrVersions.auto,
                                        size: 58,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'أعطِ هذا الرمز للمندوب أو دعه يمسح رمز الـ QR لتأكيد التسليم بنجاح.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          },
                        ),
                      ),

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
                              onPressed: () async {
                                final phone = assignment?.driverPhone;
                                if (phone != null && phone.isNotEmpty) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('جارٍ الاتصال بالمندوب $phone...'),
                                      ),
                                    );
                                  }
                                  final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
                                  final uri = Uri.parse('tel:$clean');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('لا يوجد رقم للمندوب حتى الآن')),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.chat_bubble_outline_rounded),
                              tooltip: 'محادثة المندوب',
                              onPressed: () => context.push('/chat/${widget.orderId}'),
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

                    if (isDriverConfirmed) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => context.push('/chat/${widget.orderId}'),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('محادثة السائق'),
                        ),
                      ),
                    ],

                    if (canCancel) ...[
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
          ),
        ] else if (isDineIn) ...[
          // ── Dine-in Dedicated View ────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                  ref.invalidate(ordersControllerProvider);
                  ref.invalidate(
                    deliveryAssignmentForOrderProvider(widget.orderId),
                  );
                },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.table_restaurant_rounded, size: 56, color: colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'طاولة رقم #${order.tableId ?? "1"}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'طلبك قيد التحضير في المطبخ وسيقدم طازجاً على طاولتك فور جهوزيته 🍽️',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'إجمالي الحساب: ${Formatters.formatCurrency(order.totalAmount)}',
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
                    if (canCancel) ...[
                      const SizedBox(height: AppSpacing.md),
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
          ),
        ] else ...[
          // ── Takeaway Dedicated View ───────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                  ref.invalidate(ordersControllerProvider);
                  ref.invalidate(
                    deliveryAssignmentForOrderProvider(widget.orderId),
                  );
                },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_bag_rounded, size: 56, color: colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'طلب استلام من الفرع (سفري)',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'يجري تجهيز وجبتك وتغليفها حرارياً لتكون جاهزة للاستلام من كاونتر المطعم 🛍️',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Curbside arrival button if configured
                    Builder(
                      builder: (context) {
                        final curbside = ref.watch(curbsideControllerProvider);
                        final isArrived = curbside?.isArrived ?? false;
                        return Container(
                          margin: const EdgeInsets.only(top: AppSpacing.xs),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isArrived
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : const Color(0xFFC2410C).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isArrived ? const Color(0xFF10B981) : const Color(0xFFC2410C),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car_filled_rounded,
                                    color: isArrived ? const Color(0xFF10B981) : const Color(0xFFC2410C),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isArrived
                                          ? '✅ تم إرسال إشعار وصولك لطاقم المطعم!'
                                          : '🚗 استلام من السيارة (Curbside Pickup)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isArrived ? const Color(0xFF047857) : const Color(0xFFC2410C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isArrived
                                    ? 'الموظف في طريقه إليك الآن لتسليم الطلب لسيارتك: ${curbside?.carModel ?? ""} (${curbside?.carColor ?? ""})'
                                    : 'عند وصولك وتوقفك بالخارج أمام الفرع، اضغط الزر أدناه ليخرج الموظف فوراً لتسليمك الطلب.',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (!isArrived) ...[
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC2410C),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () {
                                      ref.read(curbsideControllerProvider.notifier).signalArrival();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم إرسال إشارة وصولك بنجاح! كابتن الصالة في طريقه لسيارتك.'),
                                          backgroundColor: Color(0xFF10B981),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.touch_app_rounded),
                                    label: const Text(
                                      'أنا وصلت بالخارج (إرسال إشارة للمطعم)',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                    if (canCancel) ...[
                      const SizedBox(height: AppSpacing.md),
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
          ),
        ],
      ],
    ),
  );
  }

  /// Asks for confirmation, then cancels the order through the orders
  /// controller (persisted + broadcast), shows success feedback and leaves
  /// the tracking page.
  Future<void> _confirmCancellation() async {
    final colorScheme = Theme.of(context).colorScheme;
    final errorColor = colorScheme.error;
    final onErrorColor = colorScheme.onError;
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
              foregroundColor: onErrorColor,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final order = ref
        .read(ordersControllerProvider)
        .where((o) => o.id == widget.orderId)
        .firstOrNull;

    await ref
        .read(ordersControllerProvider.notifier)
        .updateStatus(widget.orderId, OrderStatus.cancelled);
    if (!mounted) return;

    if (order != null &&
        order.paymentMethod == PaymentMethod.wallet &&
        order.totalAmount > 0) {
      ref.read(customerWalletProvider.notifier).addFunds(
            order.totalAmount,
            title:
                'استرداد قيمة الطلب الملغي #${order.id.length > 6 ? order.id.substring(order.id.length - 4) : order.id}',
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إلغاء الطلب واسترداد ${order.totalAmount.toStringAsFixed(2)} ج.م إلى محفظتك بنجاح ✅',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب بنجاح')));
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  int _getStepIndex(
    OrderStatus status, {
    DeliveryAssignment? assignment,
    bool isDelivery = false,
  }) {
    if (isDelivery) {
      if (status == OrderStatus.completed) return 4;
      if (status == OrderStatus.cancelled) return 0;
      if (assignment != null &&
          (assignment.deliveryStatus == DeliveryStatus.inTransit ||
              assignment.deliveryStatus == DeliveryStatus.pickedUp)) {
        return 3;
      }
      if (status == OrderStatus.ready || status == OrderStatus.served) {
        return 2;
      }
      if (status == OrderStatus.preparing) {
        return 1;
      }
      return 0;
    }

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
}

class _OrderStepper extends StatelessWidget {
  const _OrderStepper({required this.currentStep, this.stages});

  final int currentStep;
  final List<String>? stages;

  static const List<String> _defaultStages = [
    'تم الطلب',
    'مؤكد',
    'قيد الإعداد',
    'في الطريق',
    'تم التسليم',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveStages = stages ?? _defaultStages;

    return Row(
      children: [
        for (int i = 0; i < effectiveStages.length; i++) ...[
          Expanded(
            child: Semantics(
              label: i < currentStep
                  ? '${effectiveStages[i]} — مكتملة'
                  : i == currentStep
                  ? '${effectiveStages[i]} — المرحلة الحالية'
                  : '${effectiveStages[i]} — لم تُكتمل بعد',
              excludeSemantics: true,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: i <= currentStep
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    foregroundColor: i <= currentStep
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    child: i < currentStep
                        ? const Icon(Icons.check, size: 14)
                        : Text(
                            '${i + 1}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    effectiveStages[i],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
          if (i < effectiveStages.length - 1)
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

// ── Map-marker chrome ─────────────────────────────────────────────────────────
// Custom pins float above arbitrary map imagery instead of themed app
// surfaces, so their chrome keeps fixed high-contrast values rather than
// theme-derived colors (same rationale as the QR scanner viewfinder staying
// pure black). Only the pin FILL colors come from [StatusColors].
const Color _markerChrome = Color(0xFFFFFFFF); // white plate/border/halo ink
const Color _markerInk = Color(0xDD000000); // black87 label text
const Color _markerHalo = Color(0x42000000); // black26 drop shadow
const Color _markerHairline = Color(0x1A000000); // black12 soft shadow

/// Readable icon ink for a marker fill: light ink on deep audited tone steps
/// (light mode), dark ink on pale dark-mode tone steps.
Color _iconInkFor(Color fill) =>
    ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? _markerChrome
        : _markerInk;

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
            boxShadow: const [
              BoxShadow(color: _markerHalo, blurRadius: 4),
            ],
          ),
          child: Icon(icon, color: _iconInkFor(color), size: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _markerChrome,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            boxShadow: const [BoxShadow(color: _markerHairline, blurRadius: 2)],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: _markerInk,
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
        border: Border.all(color: _markerChrome, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(Icons.delivery_dining, color: _iconInkFor(color), size: 24),
    );
  }
}
