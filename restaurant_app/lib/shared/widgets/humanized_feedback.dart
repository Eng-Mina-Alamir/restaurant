import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/haptics.dart';

/// Unified warm HUMANIZE feedback: snackbars with consistent look,
/// brightness-safe colors, floating behavior and optional action.
///
/// Replaces scattered raw `SnackBar(...)` + hardcoded hex
/// (`0xFF10B981 / 0xFFEF4444 / amber`) with audited [StatusColors] tones.
abstract final class HumanSnackBar {
  HumanSnackBar._();

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required Color foreground,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        duration: duration,
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: foreground,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Celebratory success (order placed, delivered, coupon applied).
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final brightness = Theme.of(context).brightness;
    final bg = StatusColors.tone(SemanticTone.success, brightness);
    AppHaptics.actionSuccess();
    _show(
      context,
      message: message,
      background: bg,
      foreground: Colors.white,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  /// Milestone success with heavy haptic (checkout done, delivery done).
  static void milestone(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final brightness = Theme.of(context).brightness;
    final bg = StatusColors.tone(SemanticTone.success, brightness);
    AppHaptics.milestoneSuccess();
    _show(
      context,
      message: message,
      background: bg,
      foreground: Colors.white,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: const Duration(seconds: 4),
      icon: Icons.celebration_outlined,
    );
  }

  /// Friendly info (waiter called, bill requested, copied to clipboard).
  static void info(BuildContext context, String message) {
    final brightness = Theme.of(context).brightness;
    final bg = StatusColors.tone(SemanticTone.info, brightness);
    AppHaptics.selectionTap();
    _show(
      context,
      message: message,
      background: bg,
      foreground: Colors.white,
      icon: Icons.info_outline_rounded,
    );
  }

  /// Gentle warning (pending, waiting, delay) — warm, never blaming.
  static void warning(BuildContext context, String message) {
    final brightness = Theme.of(context).brightness;
    final bg = StatusColors.tone(SemanticTone.warning, brightness);
    _show(
      context,
      message: message,
      background: bg,
      foreground: Colors.white,
      icon: Icons.schedule_rounded,
    );
  }

  /// Empathetic error (failure with reassurance + retry action).
  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final brightness = Theme.of(context).brightness;
    final bg = StatusColors.tone(SemanticTone.danger, brightness);
    _show(
      context,
      message: message,
      background: bg,
      foreground: Colors.white,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: const Duration(seconds: 4),
      icon: Icons.favorite_outline_rounded,
    );
  }
}

/// Central warm Arabic copy (فصحى دافئة مبسطة) shared across roles.
///
/// Keeps every empty/error/success line human: عنوان + شرح + طمأنة،
/// بدون لوم المستخدم أو السائق أو الشيف.
///
/// NOTE: Every key here now has a bilingual counterpart in `AppStrings`
/// (`warm*` getters, lib/core/l10n/app_strings.dart). New code must use
/// `AppStrings`; this class is frozen for backwards compatibility.
abstract final class HumanCopy {
  HumanCopy._();

  // ── Customer ──
  static const String searchHintWarm = 'دوّر على كبسة، برجر، مشويات...؟';
  static const String noItemsTitle = 'لم نجد طبقاً مطابقاً';
  static const String noItemsSubtitle =
      'جرّب كلمة مختلفة، أو امسح البحث وتصفح القائمة كاملة — أكيد ستجد ما يعجبك';
  static const String clearSearch = 'مسح البحث';
  static const String browseMenu = 'تصفح القائمة';
  static const String addedToCart = 'أضفناه إلى سلتك — بالهناء والشفاء';
  static const String viewCart = 'عرض السلة';
  static const String dineInWelcome = 'أهلاً بك على طاولتك! النادل معك، وطلبك بأيدٍ أمينة';
  static const String dineInFollowing = 'طلبك قيد المتابعة في المطبخ';
  static const String waiterCalled = 'نادينا النادل إلى طاولتك — سيكون معك خلال لحظات';
  static const String billRequested = 'طلبنا الفاتورة من النادل — لحظات وتكون عندك';
  static const String cartEmptyTitle = 'سلتك فارغة حالياً';
  static const String cartEmptySubtitle =
      'ما رأيك بتصفح أطباقنا الشهية؟ وجبتك المفضلة بانتظارك';

  // ── Waiter ──
  static const String tableCallingTitle = 'تناديك بكل ود';
  static const String imComing = 'أنا قادم إليها';
  static const String callAcknowledged = 'أحسنت! سجلنا أنك في الطريق إلى الطاولة';
  static const String noTablesTitle = 'لا توجد طاولات مطابقة';
  static const String noTablesSubtitle =
      'جرّب مسح الفلتر الحالي لعرض جميع الطاولات';
  static const String clearFilter = 'مسح الفلتر';
  static const String tableReleased = 'تم تجهيز الطاولة لاستقبال ضيوف جدد — شكراً لك';
  static const String tableReserved = 'تم حجز الطاولة بنجاح — أهلاً بضيوفنا';

  // ── Kitchen ──
  static const String kitchenCalmTitle = 'المطبخ هادئ الآن';
  static const String kitchenCalmSubtitle =
      'أحسنتم العمل! خذ نفساً عميقاً — الطلبات الجديدة ستظهر هنا فور وصولها';
  static const String startCooking = 'بدأت تحضيرها';
  static const String readyToServe = 'أصبحت جاهزة للتقديم';
  static const String claimedWarm = 'أصبح الطلب بين يديك — بالتوفيق يا شيف';
  static const String advancedWarm = 'انتقل الطلب للمرحلة التالية — عمل رائع';
  static const String alertsReviewed = 'راجعت تنبيهات الطلبات الجديدة — يوم موفق';
  static const String delayedEmpathy = 'هذا الطلب تأخر قليلاً — شكراً لصبركم وإتقانكم';

  // ── Manager ──
  static const String managerGreetingMorning = 'صباح الخير! يوم جديد مليء بالفرص';
  static const String managerGreetingEvening = 'مساء الخير! لنلقِ نظرة على يومك';
  static const String noSalesTitle = 'لا توجد مبيعات بعد اليوم';
  static const String noSalesSubtitle =
      'أول طلب سيبدأ من هنا — الأمور طيبة وفريقك جاهز';
  static const String branchSwitched = 'انتقلنا إلى الفرع الجديد — بالتوفيق';

  // ── Driver ──
  static const String noJobsTitle = 'لا توجد مهام حالياً';
  static const String noJobsSubtitle =
      'استرح قليلاً — المهمات الجديدة ستصلك فور توفرها';
  static const String deliveredCelebration =
      'تم التوصيل بنجاح! سُجّل المبلغ في محفظتك — شكراً لجهدك';
  static const String deliveryFailedWarm =
      'لا تقلق — سجّلنا المحاولة وأبلغنا المطبخ، شكراً لحرصك';
  static const String newAssignmentWarm = 'مهمة توصيل جديدة بانتظارك — بالتوفيق في الطريق';
  static const String acceptedWarm = 'قبلت المهمة — العميل بانتظارك بكل شوق';
  static const String startedWarm = 'انطلقت في الطريق — درب السلامة';
  static const String copiedWarm = 'نسخناها لك — شكراً لصبرك';
  static const String mapsFallback = 'تعذّر فتح الخرائط — نسخنا لك رابط الاتجاهات';
  static const String callFallback = 'تعذّر فتح الاتصال — نسخنا لك الرقم';
  static const String whatsappFallback = 'تعذّر فتح واتساب — نسخنا لك الرسالة';

  // ── Generic ──
  static const String loadingWarm = 'لحظات ونجهز لك كل شيء';
  static const String errorWarmTitle = 'حدث تعثر بسيط';
  static const String errorWarmSubtitle =
      'تحقق من الاتصال وحاول مجدداً — نحن معك خطوة بخطوة';
  static const String retryWarm = 'لنحاول مجدداً';
}
