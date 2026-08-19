import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mhj_maps/mhj_maps.dart';

import '../../../../core/theme/spacing.dart';

/// Displays a live-tracking map for the delivery driver powered by [mhj_maps].
///
/// Shows:
/// - The driver's current location (pulsing animated dot)
/// - The pickup location (restaurant marker)
/// - The delivery destination (customer pin marker)
/// - Live turn-by-turn route
class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({
    super.key,
    required this.pickupLatLng,
    required this.deliveryLatLng,
    this.pickupLabel = 'المطعم',
    this.deliveryLabel = 'العميل',
    this.onLocationUpdate,
  });

  final LatLng pickupLatLng;
  final LatLng deliveryLatLng;
  final String pickupLabel;
  final String deliveryLabel;
  final ValueChanged<LatLng>? onLocationUpdate;

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  MhjMapsMapController? _mapController;
  LatLng? _driverPosition;
  StreamSubscription<Position>? _locationSub;
  bool _locationPermitted = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final permission = await Geolocator.requestPermission();
    final permitted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!mounted) return;
    setState(() => _locationPermitted = permitted);

    if (!permitted) return;

    final current = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    if (!mounted) return;
    final pos = LatLng(current.latitude, current.longitude);
    setState(() => _driverPosition = pos);
    widget.onLocationUpdate?.call(pos);
    _updateMapMarkers();

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((p) {
      if (!mounted) return;
      final latlng = LatLng(p.latitude, p.longitude);
      setState(() => _driverPosition = latlng);
      widget.onLocationUpdate?.call(latlng);
      _updateMapMarkers();
    });
  }

  void _updateMapMarkers() {
    final ctrl = _mapController;
    if (ctrl == null) return;

    ctrl.clearMarkers();

    // 1. Pickup Restaurant Marker
    ctrl.addCustomMarker(
      position: MhjMapsLatLng(
        lat: widget.pickupLatLng.latitude,
        lng: widget.pickupLatLng.longitude,
      ),
      child: _MapMarker(
        icon: Icons.store_rounded,
        label: widget.pickupLabel,
        color: Colors.orange.shade800,
      ),
    );

    // 2. Customer Destination Marker
    ctrl.addCustomMarker(
      position: MhjMapsLatLng(
        lat: widget.deliveryLatLng.latitude,
        lng: widget.deliveryLatLng.longitude,
      ),
      child: _MapMarker(
        icon: Icons.location_pin,
        label: widget.deliveryLabel,
        color: Colors.red.shade700,
      ),
    );

    // 3. Live Driver Marker
    if (_driverPosition != null) {
      ctrl.addCustomMarker(
        position: MhjMapsLatLng(
          lat: _driverPosition!.latitude,
          lng: _driverPosition!.longitude,
        ),
        child: _DriverDot(color: Theme.of(context).colorScheme.primary),
      );
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  MhjMapsLatLng get _center => MhjMapsLatLng(
        lat: _driverPosition?.latitude ??
            (widget.pickupLatLng.latitude + widget.deliveryLatLng.latitude) / 2,
        lng: _driverPosition?.longitude ??
            (widget.pickupLatLng.longitude + widget.deliveryLatLng.longitude) / 2,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Stack(
        children: [
          // ── MhjMaps Map Widget ──────────────────────────────────────────
          MhjMapsMap(
            center: _center,
            zoom: 13,
            theme: isDark ? MhjMapsMapThemes.darkElegant : MhjMapsMapThemes.voyager,
            showZoomControls: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMapMarkers();
            },
          ),

          // ── Location denied overlay ──────────────────────────────────────
          if (!_locationPermitted)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off, color: Colors.white, size: 48),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'يرجى السماح بالوصول إلى الموقع',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: _initLocation,
                      child: const Text('منح الإذن'),
                    ),
                  ],
                ),
              ),
            ),

          // ── Recenter My Location Floating Button ─────────────────────────
          Positioned(
            bottom: AppSpacing.md,
            right: AppSpacing.md,
            child: FloatingActionButton.small(
              heroTag: 'locate_driver_mhj',
              onPressed: () {
                if (_driverPosition != null && _mapController != null) {
                  _mapController!.moveTo(
                    MhjMapsLatLng(
                      lat: _driverPosition!.latitude,
                      lng: _driverPosition!.longitude,
                    ),
                    zoom: 15,
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _DriverDot extends StatefulWidget {
  const _DriverDot({required this.color});
  final Color color;

  @override
  State<_DriverDot> createState() => _DriverDotState();
}

class _DriverDotState extends State<_DriverDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.7, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5 * _anim.value),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
      ),
    );
  }
}
