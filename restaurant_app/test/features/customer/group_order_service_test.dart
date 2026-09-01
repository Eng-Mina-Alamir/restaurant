import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/customer/domain/entities/group_order_session_entity.dart';
import 'package:restaurant_app/features/customer/domain/services/group_order_service.dart';

void main() {
  late GroupOrderService service;

  setUp(() {
    service = const GroupOrderService();
  });

  group('GroupOrderService Tests', () {
    test('createSession initializes session with host as first member', () {
      final session = service.createSession(
        hostId: 'host-1',
        hostName: 'Mina',
        restaurantId: 'rest-1',
      );

      expect(session.hostId, 'host-1');
      expect(session.hostName, 'Mina');
      expect(session.members.length, 1);
      expect(session.members.first.isHost, true);
      expect(session.status, GroupSessionStatus.active);
      expect(session.items, isEmpty);
      expect(session.subtotal, 0.0);
    });

    test('joinSession adds a new member successfully', () {
      final session = service.createSession(
        hostId: 'host-1',
        hostName: 'Mina',
        restaurantId: 'rest-1',
      );

      final updated = service.joinSession(
        session: session,
        memberId: 'member-2',
        memberName: 'Kyrolus',
      );

      expect(updated.members.length, 2);
      expect(updated.members[1].name, 'Kyrolus');
      expect(updated.members[1].isHost, false);
    });

    test('addItem and removeItem calculate subtotal and per person split correctly', () {
      final session = service.createSession(
        hostId: 'host-1',
        hostName: 'Mina',
        restaurantId: 'rest-1',
      );
      final withMember = service.joinSession(
        session: session,
        memberId: 'member-2',
        memberName: 'Kyrolus',
      );

      final item1 = GroupMemberItem(
        id: 'it-1',
        memberId: 'host-1',
        memberName: 'Mina',
        itemId: 'dish-1',
        itemName: 'Cheeseburger',
        itemPrice: 120.0,
        quantity: 2,
        addedAt: DateTime.now(),
      );

      final item2 = GroupMemberItem(
        id: 'it-2',
        memberId: 'member-2',
        memberName: 'Kyrolus',
        itemId: 'dish-2',
        itemName: 'Caesar Salad',
        itemPrice: 60.0,
        quantity: 1,
        addedAt: DateTime.now(),
      );

      var sessionWithItems = service.addItem(session: withMember, item: item1);
      sessionWithItems = service.addItem(session: sessionWithItems, item: item2);

      expect(sessionWithItems.items.length, 2);
      expect(sessionWithItems.totalItemsCount, 3);
      expect(sessionWithItems.subtotal, 300.0); // (120*2) + 60 = 300
      expect(sessionWithItems.perPersonShare, 150.0); // 300 / 2 members = 150

      expect(sessionWithItems.totalForMember('host-1'), 240.0);
      expect(sessionWithItems.totalForMember('member-2'), 60.0);

      // Remove item2
      final afterRemoval = service.removeItem(session: sessionWithItems, itemId: 'it-2');
      expect(afterRemoval.items.length, 1);
      expect(afterRemoval.subtotal, 240.0);
    });

    test('lockSession prevents new items from being added', () {
      final session = service.createSession(
        hostId: 'host-1',
        hostName: 'Mina',
        restaurantId: 'rest-1',
      );
      final locked = service.lockSession(session);

      expect(locked.status, GroupSessionStatus.locked);
      expect(
        () => service.addItem(
          session: locked,
          item: GroupMemberItem(
            id: '1',
            memberId: 'host-1',
            memberName: 'Mina',
            itemId: 'dish',
            itemName: 'Burger',
            itemPrice: 50,
            addedAt: DateTime.now(),
          ),
        ),
        throwsStateError,
      );
    });
  });
}
