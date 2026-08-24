import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/restaurant/domain/entities/restaurant_entity.dart';

void main() {
  group('BusinessHours Entity Tests', () {
    test('default business hours open at 10:00 and close at 23:00', () {
      const hours = BusinessHours();
      expect(hours.openTime, equals('10:00'));
      expect(hours.closeTime, equals('23:00'));
    });

    test('serializes and deserializes JSON properly', () {
      final json = <String, dynamic>{'openTime': '08:30', 'closeTime': '01:00'};
      final hours = BusinessHours.fromJson(json);
      expect(hours.openTime, equals('08:30'));
      expect(hours.closeTime, equals('01:00'));
      expect(hours.toJson(), equals(json));
    });
  });

  group('RestaurantEntity Tests', () {
    test('creates entity with default and custom values', () {
      const restaurant = RestaurantEntity(
        id: 'rest-001',
        name: 'مطعم الأصالة والذوق',
        address: 'شارع الملك فهد، الرياض',
        phone: '+966500000000',
        latitude: 24.7136,
        longitude: 46.6753,
        totalTables: 25,
        categories: ['مشويات', 'مقبلات', 'مشروبات'],
      );

      expect(restaurant.id, equals('rest-001'));
      expect(restaurant.name, equals('مطعم الأصالة والذوق'));
      expect(restaurant.latitude, equals(24.7136));
      expect(restaurant.longitude, equals(46.6753));
      expect(restaurant.totalTables, equals(25));
      expect(restaurant.categories.length, equals(3));
      expect(restaurant.hours.openTime, equals('10:00'));
    });

    test('JSON serialization round-trip retains all nested fields', () {
      final json = <String, dynamic>{
        'id': 'rest-002',
        'name': 'Gourmet Burger',
        'address': 'Main St 123',
        'phone': '12345678',
        'latitude': 21.5433,
        'longitude': 39.1728,
        'logoUrl': 'https://example.com/logo.png',
        'hours': {'openTime': '11:00', 'closeTime': '02:00'},
        'totalTables': 18,
        'categories': ['Burgers', 'Sides', 'Drinks'],
      };

      final entity = RestaurantEntity.fromJson(json);
      expect(entity.id, equals('rest-002'));
      expect(entity.logoUrl, equals('https://example.com/logo.png'));
      expect(entity.hours.openTime, equals('11:00'));
      expect(entity.hours.closeTime, equals('02:00'));
      expect(entity.totalTables, equals(18));
      expect(entity.categories, contains('Burgers'));

      final outJson = entity.toJson();
      expect(outJson['id'], equals('rest-002'));
      expect(outJson['logoUrl'], equals('https://example.com/logo.png'));
      expect(
        (outJson['hours'] as Map<String, dynamic>)['openTime'],
        equals('11:00'),
      );
    });
  });
}
