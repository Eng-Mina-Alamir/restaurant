# 🍽️ تطبيق المطعم الذكي المتكامل — Smart Restaurant Multi-Role System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend%20%26%20Realtime-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-black?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-998%2F998%20Passed-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-red?style=for-the-badge)

**نظام متكامل لإدارة المطاعم وطلبات الطعام يغطي 5 أدوار مختلفة بنظام الوقت الفعلي (Real-time WebSockets) والهيكل البرمجي النظيف (Clean Architecture).**

[📱 خطة الاختبار الشاملة](MOBILE_APP_TEST_PLAN.md) • [🗄️ مخطط قاعدة البيانات](restaurant_app/supabase_schema.sql) • [🚀 مجلد التطبيق](restaurant_app/)

</div>

---

## 🌟 مميزات النظام (Key Features)

### 1. 👥 منظومة متعددة الأدوار (5 Distinct User Roles)
* 🛍️ **تجربة العميل (Customer):** تصفح القائمة مع فلاتر التصنيف، تخصيص الوجبات والمعدلات (Modifiers)، مسح كود QR للطاولة للطلب الداخلي، طلبات التوصيل والسفري، كود الخصم والكوبونات، تتبع الطلب لحظياً، نظام نقاط الولاء والمكافآت، وتقييم الخدمة.
* 👨‍🍳 **شاشة المطبخ الذكية (Kitchen Display System - KDS):** استقبال تذاكر الطهي الحية، مؤقتات تصاعدية ملونة لحالة التأخير، تنبيهات صوتية عند وصول طلب جديد، فلترة الطلبات حسب محطة الطهي (مشويات، مقبلات، مشروبات)، وطباعة بونات المطبخ الحرارية (ESC/POS).
* 🤵 **لوحة النادل / الكابتن (Waiter & Table Management):** خريطة تفاعلية للطاولات (متاحة، مشغولة، محجوزة، تحتاج تنظيف)، فتح طلبات الطاولات وتعديلها، نقل الطلب بين الطاولات، وتقسيم الفاتورة بالتساوي بين الأفراد (Split Bill).
* 🛵 **تطبيق مندوب التوصيل (Delivery Driver Flow):** استلام مهام التوصيل، حساب رسوم التوصيل الجغرافية تلقائياً، إرسال إحداثيات GPS الحية، والتقاط صور إثبات التسليم بالكاميرا (Delivery Proof).
* 📊 **لوحة تحكم المدير (Manager Dashboard):** إحصائيات المبيعات والأرباح الحية مع حساب ضريبة القيمة المضافة (VAT 14%)، إدارة القائمة والأسعار وتوفر الأصناف، إدارة المخزون وتنبيهات النواقص، مولد أكواد QR للطاولات، وإدارة الكوبونات والخصومات.

---

## 🏗️ الهيكل البرمجي والمعماري (Architecture)

تم بناء التطبيق باتباع مبادئ **Clean Architecture** و **Feature-First**:

```text
restaurant_app/lib
├── config/                  # بيئات التشغيل (Dev / Staging / Production) والثوابت
├── core/                    # النواة المشتركة
│   ├── analytics/           # تتبع الأحداث والتحليلات
│   ├── data/                # التخزين المحلي وطابور العمليات غير المتصلة (Offline Queue)
│   ├── di/                  # حقن الاعتماديات عبر Riverpod Providers
│   ├── domain/              # الكيانات العامة والقيم المشتركة
│   ├── errors/              # الفشل والاستثناءات المخصصة
│   ├── l10n/                # التعريب والقواميس (العربية والإنجليزية)
│   ├── network/             # عميل Dio ومحدد الاتصال وخدمة Realtime WebSockets
│   ├── notifications/       # إدارة الإشعارات الفورية
│   ├── payment/             # خدمات الدفع الإلكتروني والنقدي
│   ├── printing/            # مولد بونات المطبخ الحرارية ESC/POS
│   ├── routing/             # نظام التوجيه الذكي والصلاحيات عبر GoRouter
│   ├── storage/             # التخزين الآمن وتخزين Hive
│   ├── supabase/            # تكامل Supabase Client و Auth و Storage و Realtime
│   ├── theme/               # أنظمة الألوان (Light/Dark) والخطوط العربية الحديثة
│   └── utils/               # أدوات التنسيق والتحقق وسجلات التشغيل
├── features/                # الوحدات الوظيفية المستقلة (Auth, Menu, Orders, KDS, Delivery, Tables, ...)
└── shared/                  # العناصر المرئية والأنيميشن التفاعلي المشترك
```

---

## 🔒 المزامنة الحية والعمل دون اتصال (Offline Resilience & Realtime)

* **Realtime WebSockets:** تحديث لحظي لحالات الطلبات والطاولات وتتبع المندوب باستخدام قنوات Supabase Realtime دون الحاجة لتحديث الصفحة.
* **Offline Queue Service:** حفظ الطلبات محلياً عبر Hive في حال انقطاع الشبكة مع التحقق من معرّف عدم التكرار (Idempotency Key)، وتفريغ الطابور تلقائياً فور استعادة الاتصال.
* **Fallback Caching:** التراجع التلقائي للبيانات المخزنة محلياً عند عدم توفر اتصال بالإنترنت لضمان استمرارية عمل المطعم دون توقف.

---

## 🗄️ إعداد قاعدة البيانات (Supabase Backend Setup)

ملفات الـ SQL الجاهزة للإنتاج موجودة في مسار المشروع:
1. [supabase_schema.sql](restaurant_app/supabase_schema.sql): المخطط الكامل للجداول، المفاتيح الخارجية، الدوال، والمشغلات (Triggers)، وتفعيل الـ RLS وحاويات التخزين (Storage Buckets).
2. [seed_staff_users.sql](seed_staff_users.sql): بيانات تجريبية لحسابات الموظفين ومستخدمي الأدوار.

### الجداول الأساسية:
- `profiles`: الحسابات المرتبطة بنظام المصادقة مع تحديد الدور (`customer`, `waiter`, `kitchen`, `driver`, `manager`, `admin`).
- `categories` & `menu_items`: قائمة الطعام والتصنيفات.
- `menu_modifier_groups` & `menu_modifier_options`: الإضافات والخيارات والمعدلات.
- `tables`: طاولات الصالة والتراس والحديقة وحالاتها.
- `orders` & `order_items`: تفاصيل الطلبات وسجل الحالات.
- `driver_locations`: الإحداثيات الجغرافية الحية للمناديب.
- `reservations`, `coupons`, `ratings`, `inventory`: الحجوزات، الكوبونات، التقييمات، وإدارة المخزون.

---

## 🧪 نتائج الاختبارات وجودة الكود (Quality Assurance & Tests)

| نوع الاختبار | عدد الاختبارات | النتيجة |
| :--- | :---: | :---: |
| **QA Master Suites (10 مجموعات فحص شاملة)** | 49 | ✅ 100% ناجح |
| **Unit & Entity Tests (اختبارات الوحدات والمنطق الحسابي)** | 450+ | ✅ 100% ناجح |
| **Widget & UI Interaction Tests (اختبارات واجهات المستخدم)** | 220+ | ✅ 100% ناجح |
| **End-to-End Timeline Journeys (رحلات المستخدمين الكاملة)** | 96 | ✅ 100% ناجح |
| **الإجمالي العام (Total Test Suite)** | **998** | **✅ 998/998 Passed** |
| **التحليل الساكن (Static Analysis - `flutter analyze`)** | - | **✅ 0 Issues / 0 Warnings** |

---

## 🚀 التشغيل والتثبيت (Getting Started)

### المتطلبات المسبقة:
- Flutter SDK (الإصدار 3.22+ أو أحدث)
- Dart SDK (الإصدار 3.4+ أو أحدث)

### خطوات التشغيل:
```bash
# 1. الدخول إلى مجلد التطبيق
cd restaurant_app

# 2. تحميل الحزم والاعتماديات
flutter pub get

# 3. فحص الكود والتأكد من خلوه من الأخطاء
flutter analyze

# 4. تشغيل كافة الاختبارات المؤتمتة (الاختبارات كاملة خضراء — شغّل flutter test)
flutter test

# 5. تشغيل التطبيق في وضع التطوير
flutter run
```

---

## 🔑 الحسابات التجريبية الافتراضية (Demo Accounts)

| الحساب | كلمة المرور | الدور الوظيفي | المسار الافتراضي |
| :--- | :---: | :---: | :---: |
| `customer@demo.com` | `123456` | عميل (Customer) | `/customer` |
| `waiter@demo.com` | `123456` | نادل / كابتن (Waiter) | `/waiter` |
| `kitchen@demo.com` | `123456` | شيف المطبخ (Kitchen / KDS) | `/kds` |
| `driver@demo.com` | `123456` | مندوب توصيل (Driver) | `/driver` |
| `manager@demo.com` | `123456` | مدير المطعم (Manager) | `/manager` |

---

## 📄 حقوق الملكية والترخيص (License)
**جميع الحقوق محفوظة © 2026 م. مينا الأمير (All Rights Reserved).**

هذا المشروع ملكية خاصة ومحمية بموجب قوانين الملكية الفكرية، ولا يُسمح بالنسخ أو التعديل أو إعادة التوزيع أو الاستخدام التجاري دون إذن خطي مسبق من صاحب العمل.

