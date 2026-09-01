import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group_order_session_entity.dart';
import '../../domain/services/group_order_service.dart';

final groupOrderServiceProvider = Provider<GroupOrderService>((ref) {
  return const GroupOrderService();
});

/// Controller managing active group order session state.
class GroupOrderController extends StateNotifier<GroupOrderSession?> {
  GroupOrderController(this._service) : super(null);

  final GroupOrderService _service;

  /// Creates and starts a new group ordering room.
  void createRoom({
    required String hostId,
    required String hostName,
    required String restaurantId,
    String? customCode,
  }) {
    state = _service.createSession(
      hostId: hostId,
      hostName: hostName,
      restaurantId: restaurantId,
      customRoomCode: customCode,
    );
  }

  /// Joins an existing session by adding the member.
  void joinRoom({
    required String memberId,
    required String memberName,
  }) {
    if (state == null) return;
    state = _service.joinSession(
      session: state!,
      memberId: memberId,
      memberName: memberName,
    );
  }

  /// Adds a dish for a specific member into the shared cart.
  void addMemberItem(GroupMemberItem item) {
    if (state == null) return;
    state = _service.addItem(
      session: state!,
      item: item,
    );
  }

  /// Removes an item from the shared cart.
  void removeMemberItem(String itemId) {
    if (state == null) return;
    state = _service.removeItem(
      session: state!,
      itemId: itemId,
    );
  }

  /// Locks the room before placing the order.
  void lockRoom() {
    if (state == null) return;
    state = _service.lockSession(state!);
  }

  /// Updates the payment mode for the group order.
  void updatePaymentMode(GroupPaymentMode mode) {
    if (state == null) return;
    state = _service.updatePaymentMode(
      session: state!,
      paymentMode: mode,
    );
  }

  /// Leaves or dismisses the active session.
  void leaveSession() {
    state = null;
  }
}

final groupOrderControllerProvider =
    StateNotifierProvider<GroupOrderController, GroupOrderSession?>((ref) {
  final service = ref.watch(groupOrderServiceProvider);
  return GroupOrderController(service);
});
