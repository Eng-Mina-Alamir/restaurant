import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/l10n/app_strings.dart';

void main() {
  group('Bilingual AppStrings Tests', () {
    test('provides accurate Arabic translations', () {
      final ar = AppStrings(const Locale('ar'));
      expect(ar.isArabic, isTrue);
      expect(ar.loginTitle, 'تسجيل الدخول');
      expect(ar.menu, 'القائمة');
      expect(ar.loyalty, 'برنامج الولاء');
      expect(ar.coupons, 'الكوبونات');
      expect(ar.checkout, 'إتمام الطلب');
    });

    test('provides accurate English translations', () {
      final en = AppStrings(const Locale('en'));
      expect(en.isArabic, isFalse);
      expect(en.loginTitle, 'Sign In');
      expect(en.menu, 'Menu');
      expect(en.loyalty, 'Loyalty Rewards');
      expect(en.coupons, 'Coupons');
      expect(en.checkout, 'Checkout');
    });
  });
}
