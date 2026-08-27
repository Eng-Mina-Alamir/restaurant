import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/realtime_service.dart';
import '../../../../core/notifications/waiter_alert_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/table_service_request.dart';

/// Manages active in-restaurant table service requests (e.g. Call Waiter, Request Bill).
class TableServiceController extends StateNotifier<List<TableServiceRequest>> {
  TableServiceController({
    RealtimeService? realtimeService,
    WaiterAlertService? waiterAlertService,
  }) : _realtimeService = realtimeService,
       _waiterAlertService = waiterAlertService,
       super(const []) {
    _initRealtime();
  }

  final RealtimeService? _realtimeService;
  final WaiterAlertService? _waiterAlertService;
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  void _initRealtime() {
    final service = _realtimeService;
    if (service == null) return;

    _realtimeSub = service.events.listen((event) {
      if (event.type == RealtimeEventType.tableServiceRequested) {
        try {
          final request = TableServiceRequest.fromJson(event.payload);
          if (state.any((r) => r.id == request.id)) return;
          state = [request, ...state];
          _waiterAlertService?.notifyReadyForPickup();
        } catch (e, st) {
          AppLogger.warning(
            'TableServiceController: malformed tableServiceRequested payload',
            error: e,
            stackTrace: st,
          );
        }
      } else if (event.type == RealtimeEventType.tableServiceHandled) {
        try {
          final requestId = event.payload['requestId']?.toString() ??
              event.payload['id']?.toString();
          if (requestId == null) return;
          final waiterId = event.payload['waiterId']?.toString();
          final handledAtStr = event.payload['handledAt']?.toString();
          final handledAt = handledAtStr != null
              ? DateTime.tryParse(handledAtStr) ?? DateTime.now()
              : DateTime.now();

          state = state.map((r) {
            if (r.id == requestId) {
              return r.copyWith(
                isHandled: true,
                handledAt: handledAt,
                handledByWaiterId: waiterId,
              );
            }
            return r;
          }).toList();
        } catch (e, st) {
          AppLogger.warning(
            'TableServiceController: malformed tableServiceHandled payload',
            error: e,
            stackTrace: st,
          );
        }
      }
    });
  }

  /// Sends a new table service/assistance request from a customer at a dining table.
  TableServiceRequest requestService({
    required String tableId,
    required int tableNumber,
    required TableServiceType type,
    String? note,
  }) {
    final request = TableServiceRequest(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      tableId: tableId,
      tableNumber: tableNumber,
      type: type,
      note: note,
      requestedAt: DateTime.now(),
      isHandled: false,
    );

    state = [request, ...state];
    _realtimeService?.broadcastTableServiceRequested(request.toJson());
    AppLogger.info(
      'TableServiceController: Table $tableNumber requested ${type.name}',
    );
    return request;
  }

  /// Acknowledges and completes a table assistance request by a waiter.
  void acknowledgeService(String requestId, {String? waiterId}) {
    final now = DateTime.now();
    state = state.map((r) {
      if (r.id == requestId) {
        return r.copyWith(
          isHandled: true,
          handledAt: now,
          handledByWaiterId: waiterId,
        );
      }
      return r;
    }).toList();

    _realtimeService?.broadcastTableServiceHandled(
      requestId,
      waiterId: waiterId,
      handledAt: now,
    );
    AppLogger.info('TableServiceController: Request $requestId handled');
  }

  /// All active (unhandled) service requests.
  List<TableServiceRequest> get activeRequests =>
      state.where((r) => !r.isHandled).toList();

  /// Total count of active requests requiring waiter attention.
  int get activeRequestsCount => activeRequests.length;

  /// Active requests for a specific [tableId].
  List<TableServiceRequest> activeRequestsForTable(String tableId) =>
      state.where((r) => r.tableId == tableId && !r.isHandled).toList();

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

/// Provider for [TableServiceController].
final tableServiceControllerProvider =
    StateNotifierProvider<TableServiceController, List<TableServiceRequest>>(
      (ref) => TableServiceController(
        realtimeService: ref.watch(realtimeServiceProvider),
        waiterAlertService: ref.watch(waiterAlertServiceProvider),
      ),
    );
