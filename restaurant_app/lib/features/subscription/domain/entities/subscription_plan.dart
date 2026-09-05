/// Available SaaS subscription tiers for restaurants.
enum SubscriptionTier {
  trial(
    id: 'trial',
    nameAr: 'الفترة التجريبية',
    nameEn: 'Free Trial',
    priceSar: 0,
    priceEgp: 0,
    priceUsd: 0,
    maxBranches: 1,
    maxTables: 25,
    maxStaff: 10,
  ),
  starter(
    id: 'starter',
    nameAr: 'باقة المبتدئين (Starter)',
    nameEn: 'Starter Plan',
    priceSar: 249,
    priceEgp: 3200,
    priceUsd: 69,
    maxBranches: 1,
    maxTables: 15,
    maxStaff: 5,
  ),
  pro(
    id: 'pro',
    nameAr: 'باقة المحترفين (Pro)',
    nameEn: 'Pro Plan',
    priceSar: 499,
    priceEgp: 6500,
    priceUsd: 139,
    maxBranches: 3,
    maxTables: 50,
    maxStaff: 25,
  ),
  enterprise(
    id: 'enterprise',
    nameAr: 'باقة سلاسل المطاعم (Enterprise)',
    nameEn: 'Enterprise Plan',
    priceSar: 1299,
    priceEgp: 18000,
    priceUsd: 349,
    maxBranches: 999,
    maxTables: 999,
    maxStaff: 999,
  );

  const SubscriptionTier({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.priceSar,
    required this.priceEgp,
    required this.priceUsd,
    required this.maxBranches,
    required this.maxTables,
    required this.maxStaff,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double priceSar;
  final double priceEgp;
  final double priceUsd;
  final int maxBranches;
  final int maxTables;
  final int maxStaff;

  static SubscriptionTier fromString(String? value) {
    if (value == null) return SubscriptionTier.pro;
    return SubscriptionTier.values.firstWhere(
      (t) => t.id.toLowerCase() == value.toLowerCase(),
      orElse: () => SubscriptionTier.pro,
    );
  }
}

/// Granular functional capabilities that can be enabled or restricted based on subscription tier.
enum SaaSFeature {
  posCheckout('نقطة البيع السريعة والكاشير'),
  kdsKitchen('شاشة عرض المطبخ الرقمية KDS'),
  waiterTableManagement('تطبيق الويتر وإدارة الطاولات'),
  customerQrDineIn('قائمة الطعام وطلب الـ QR للصالة'),
  liveDriverGpsTracking('تطبيق السائقين والتتبع المباشر بالـ GPS'),
  driverDispatchBoard('لوحة التوزيع الذكي لطلبات التوصيل'),
  inAppCustomerChat('الشات المباشر مع العميل والسائق'),
  loyaltyAndCoupons('برنامج الولاء ونقاط المكافآت والكوبونات'),
  menuEngineeringMatrix('مصفوفة هندسة المنيو وتحليل الربحية (BCG)'),
  purchaseOrdersAndSuppliers('أوامر الشراء وإدارة الموردين'),
  multiBranchManagement('إدارة سلاسل الفروع المتعددة مركزيّاً'),
  thermalPrintingHardware('الطباعة الحرارية المباشرة (ESC/POS) عبر الشبكة'),
  customDomainWhiteLabel('نطاق مخصص وهوية بيضاء (White-Label)');

  const SaaSFeature(this.labelAr);
  final String labelAr;
}

/// Evaluator that determines whether a specific SaaS feature is unlocked in a tier.
class SubscriptionEntitlements {
  const SubscriptionEntitlements._();

  static bool isFeatureAllowed(SubscriptionTier tier, SaaSFeature feature) {
    switch (tier) {
      case SubscriptionTier.trial:
      case SubscriptionTier.enterprise:
        // Trial and Enterprise unlock all features for full evaluation
        return true;

      case SubscriptionTier.pro:
        // Pro includes everything except multi-branch enterprise & custom domain
        return feature != SaaSFeature.multiBranchManagement &&
            feature != SaaSFeature.customDomainWhiteLabel;

      case SubscriptionTier.starter:
        // Starter is single branch dine-in & takeaway only
        switch (feature) {
          case SaaSFeature.posCheckout:
          case SaaSFeature.kdsKitchen:
          case SaaSFeature.waiterTableManagement:
          case SaaSFeature.customerQrDineIn:
          case SaaSFeature.thermalPrintingHardware:
            return true;
          default:
            return false;
        }
    }
  }

  /// List of feature bullet points to present in pricing comparisons.
  static List<String> getTierHighlights(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return [
          'كاشير ونقطة بيع سريعة (Fast POS)',
          'شاشة مطبخ KDS ذكية',
          'منيو إلكتروني برمز QR للطاولات',
          'إدارة حتى 15 طاولة و5 موظفين',
          'طباعة فواتير حرارية بشبكة LAN وبلوتوث',
        ];
      case SubscriptionTier.pro:
        return [
          'جميع مميزات باقة Starter',
          'تطبيق السائقين وتتبع GPS مباشر على الخريطة',
          'غرفة توجيه الأسطول الذكي (Dispatch Board)',
          'شات فوري بين العميل والكاشير والمندوب',
          'برنامج ولاء ومكافآت وكوبونات حصرية',
          'إدارة حتى 50 طاولة و25 موظفاً',
        ];
      case SubscriptionTier.enterprise:
        return [
          'جميع مميزات باقة Pro بالكامل',
          'إدارة فروع وسلاسل غير محدودة (Multi-Branch)',
          'مصفوفة هندسة المنيو والربحية (BCG Matrix)',
          'إدارة أوامر الشراء والموردين وسلاسل الإمداد',
          'ربط برمجي Open API مع جاهز وهنقرستيشن',
          'دعم فني مخصص 24/7 مع مدير حساب خاص',
        ];
      case SubscriptionTier.trial:
        return [
          'تجربة مجانية غير محدودة لمدة 14 يوماً',
          'استكشاف جميع المزايا المتقدمة بدون بطاقة ائتمان',
        ];
    }
  }
}
