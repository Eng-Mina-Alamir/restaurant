import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/table_management/domain/entities/course_and_allergen_entity.dart';

void main() {
  group('Course, Allergen & Cooking Tags Tests', () {
    test('CourseType enum properties are configured correctly', () {
      expect(CourseType.appetizer.code, 'appetizer');
      expect(CourseType.mainCourse.code, 'main_course');
      expect(CourseType.dessert.code, 'dessert');
      expect(CourseType.beverage.code, 'beverage');

      expect(CourseType.appetizer.sortOrder, lessThan(CourseType.mainCourse.sortOrder));
    });

    test('AllergenType flags have distinct codes and labels', () {
      expect(AllergenType.nuts.code, 'nuts');
      expect(AllergenType.gluten.code, 'gluten');
      expect(AllergenType.dairy.code, 'dairy');
      expect(AllergenType.seafood.code, 'seafood');

      expect(AllergenType.values.length, greaterThanOrEqualTo(5));
    });

    test('CookingTag default preset list provides essential restaurant notes', () {
      const tags = CookingTag.defaultTags;
      expect(tags.any((t) => t.id == 'no_onion'), isTrue);
      expect(tags.any((t) => t.id == 'extra_spicy'), isTrue);
      expect(tags.any((t) => t.id == 'well_done'), isTrue);
      expect(tags.any((t) => t.id == 'side_sauce'), isTrue);
    });

    test('CourseFireCommand serializes to JSON properly for KDS integration', () {
      final now = DateTime.now();
      final cmd = CourseFireCommand(
        orderId: 'ORD-999',
        tableId: 't-5',
        tableNumber: 5,
        courseType: CourseType.mainCourse,
        firedAt: now,
        firedByWaiterId: 'waiter-1',
      );

      final json = cmd.toJson();
      expect(json['orderId'], 'ORD-999');
      expect(json['tableNumber'], 5);
      expect(json['courseType'], 'main_course');
      expect(json['firedByWaiterId'], 'waiter-1');
    });
  });
}
