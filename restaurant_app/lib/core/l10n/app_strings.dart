import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_localizations.dart';

/// Comprehensive bilingual translation lookup dictionary.
class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  bool get isArabic => locale.languageCode == 'ar';

  // Auth
  String get loginTitle => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get loginSubtitle => isArabic
      ? 'مرحباً بعودتك! سجّل للوصول إلى حسابك'
      : 'Welcome back! Sign in to continue';
  String get emailLabel => isArabic ? 'البريد الإلكتروني' : 'Email Address';
  String get passwordLabel => isArabic ? 'كلمة المرور' : 'Password';
  String get loginButton => isArabic ? 'دخول' : 'Login';
  String get registerTitle => isArabic ? 'إنشاء حساب جديد' : 'Create Account';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';

  // Navigation & Sections
  String get menu => isArabic ? 'القائمة' : 'Menu';
  String get cart => isArabic ? 'السلة' : 'Cart';
  String get orders => isArabic ? 'الطلبات' : 'Orders';
  String get tables => isArabic ? 'الطاولات' : 'Tables';
  String get reservations => isArabic ? 'الحجوزات' : 'Reservations';
  String get kds => isArabic ? 'المطبخ' : 'Kitchen KDS';
  String get delivery => isArabic ? 'التوصيل' : 'Delivery';
  String get manager => isArabic ? 'المدير' : 'Manager';
  String get loyalty => isArabic ? 'برنامج الولاء' : 'Loyalty Rewards';
  String get coupons => isArabic ? 'الكوبونات' : 'Coupons';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';

  // Common Actions
  String get save => isArabic ? 'حفظ' : 'Save';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get add => isArabic ? 'إضافة' : 'Add';
  String get apply => isArabic ? 'تطبيق' : 'Apply';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get checkout => isArabic ? 'إتمام الطلب' : 'Checkout';
  String get clear => isArabic ? 'إفراغ' : 'Clear';
  String get search => isArabic ? 'بحث...' : 'Search...';
  String get subtotal => isArabic ? 'المجموع الفرعي' : 'Subtotal';
  String get tax => isArabic ? 'الضريبة (15%)' : 'Tax (15%)';
  String get total => isArabic ? 'الإجمالي' : 'Total';
  String get discount => isArabic ? 'الخصم' : 'Discount';
  String get printTicket => isArabic ? 'طباعة التذكرة' : 'Print Ticket';
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return AppStrings(locale);
});
