import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity Serialization & Construction Tests', () {
    test('round-trip JSON serialization', () {
      final now = DateTime(2026, 8, 19, 14, 30);
      final user = UserEntity(
        id: 'usr-100',
        name: 'كريم محمود',
        email: 'karim@example.com',
        phone: '0551234567',
        role: UserRole.driver,
        restaurantId: 'rest-1',
        token: 'jwt-mock-token',
        createdAt: now,
        isActive: true,
      );

      final json = user.toJson();
      expect(json['id'], 'usr-100');
      expect(json['name'], 'كريم محمود');
      expect(json['role'], 'driver');
      expect(json['token'], 'jwt-mock-token');

      final deserialized = UserEntity.fromJson(json);
      expect(deserialized.id, user.id);
      expect(deserialized.name, user.name);
      expect(deserialized.role, UserRole.driver);
      expect(deserialized.email, user.email);
      expect(deserialized.isActive, isTrue);
    });

    test('defaults and tolerant role deserialization', () {
      final json = {
        'id': 'usr-default',
        'name': 'Test User',
        'email': 'test@test.com',
        'phone': '0500000000',
        'role': 'unknown_role', // should fallback to customer
        'createdAt': '2026-08-19T10:00:00.000Z',
      };

      final user = UserEntity.fromJson(json);
      expect(user.role, UserRole.customer);
      expect(user.isActive, isTrue);
      expect(user.token, isNull);
    });
  });
}
