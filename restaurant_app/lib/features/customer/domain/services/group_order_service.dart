import 'dart:math';
import '../entities/group_order_session_entity.dart';

/// Domain service handling group ordering operations and logic.
class GroupOrderService {
  const GroupOrderService();

  /// Generates a random 6-character alphanumeric room PIN code.
  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Creates a new group order session initiated by the host.
  GroupOrderSession createSession({
    required String hostId,
    required String hostName,
    required String restaurantId,
    String? customRoomCode,
  }) {
    final now = DateTime.now();
    final hostMember = GroupMember(
      id: hostId,
      name: hostName,
      isHost: true,
      joinedAt: now,
    );

    return GroupOrderSession(
      id: 'GRP-${now.millisecondsSinceEpoch}',
      roomCode: customRoomCode ?? generateRoomCode(),
      hostId: hostId,
      hostName: hostName,
      restaurantId: restaurantId,
      members: [hostMember],
      items: const [],
      status: GroupSessionStatus.active,
      paymentMode: GroupPaymentMode.hostPaysAll,
      createdAt: now,
    );
  }

  /// Adds a new member to an active session.
  GroupOrderSession joinSession({
    required GroupOrderSession session,
    required String memberId,
    required String memberName,
  }) {
    if (session.status != GroupSessionStatus.active) {
      throw StateError('لا يمكن الانضمام، جلسة الطلب مغلقة أو مكتملة.');
    }

    // Check if already in room
    if (session.members.any((m) => m.id == memberId)) {
      return session;
    }

    final newMember = GroupMember(
      id: memberId,
      name: memberName,
      isHost: false,
      joinedAt: DateTime.now(),
    );

    return session.copyWith(
      members: [...session.members, newMember],
    );
  }

  /// Adds an item to the group order session.
  GroupOrderSession addItem({
    required GroupOrderSession session,
    required GroupMemberItem item,
  }) {
    if (session.status != GroupSessionStatus.active) {
      throw StateError('الغرفة مغلقة حالياً، لا يمكن إضافة أصناف جديدة.');
    }

    return session.copyWith(
      items: [...session.items, item],
    );
  }

  /// Removes an item from the session by its unique ID.
  GroupOrderSession removeItem({
    required GroupOrderSession session,
    required String itemId,
  }) {
    if (session.status != GroupSessionStatus.active) {
      throw StateError('الغرفة مغلقة حالياً، لا يمكن تعديل الأصناف.');
    }

    return session.copyWith(
      items: session.items.where((it) => it.id != itemId).toList(),
    );
  }

  /// Locks the room so no more modifications can be made before checkout.
  GroupOrderSession lockSession(GroupOrderSession session) {
    return session.copyWith(
      status: GroupSessionStatus.locked,
      lockedAt: DateTime.now(),
    );
  }

  /// Changes the payment mode (Host pays, Split evenly, Pay by item).
  GroupOrderSession updatePaymentMode({
    required GroupOrderSession session,
    required GroupPaymentMode paymentMode,
  }) {
    return session.copyWith(paymentMode: paymentMode);
  }
}
