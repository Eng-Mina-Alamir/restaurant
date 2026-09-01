/// Dining course classification for multi-course meal sequencing.
enum CourseType {
  beverage('مشروبات 🥤', 'beverage', 1),
  appetizer('مقبلات وشوربة 🍲', 'appetizer', 2),
  mainCourse('أطباق رئيسية 🍖', 'main_course', 3),
  dessert('حلويات 🍰', 'dessert', 4);

  const CourseType(this.labelAr, this.code, this.sortOrder);
  final String labelAr;
  final String code;
  final int sortOrder;
}

/// Status of a course in the kitchen pipeline.
enum CourseStatus {
  pending('في الانتظار (Hold)'),
  fired('تم الإرسال للمطبخ (Fired) 🔥'),
  cooking('قيد الطهي في المطبخ 👨‍🍳'),
  ready('جاهز للتقديم (Ready) ✅'),
  served('تم التقديم على الطاولة 🍽️');

  const CourseStatus(this.labelAr);
  final String labelAr;
}

/// Critical Allergen warnings flagged for the kitchen brigade.
enum AllergenType {
  nuts('مكسرات 🥜', 'nuts'),
  gluten('جلوتين / قمح 🌾', 'gluten'),
  dairy('ألبان ولاكتوز 🥛', 'dairy'),
  seafood('بحريات وقشريات 🦐', 'seafood'),
  eggs('بيض 🥚', 'eggs'),
  sesame('سمسم وطحينة 🫘', 'sesame');

  const AllergenType(this.labelAr, this.code);
  final String labelAr;
  final String code;
}

/// Quick standard kitchen cooking tags selectable with 1-tap.
class CookingTag {
  const CookingTag({
    required this.id,
    required this.labelAr,
    required this.icon,
    this.category = 'general',
  });

  final String id;
  final String labelAr;
  final String icon;
  final String category;

  static const List<CookingTag> defaultTags = [
    CookingTag(id: 'no_onion', labelAr: 'بدون بصل', icon: '🧅'),
    CookingTag(id: 'extra_spicy', labelAr: 'سبايسي زيادة 🌶️', icon: '🌶️'),
    CookingTag(id: 'mild', labelAr: 'بارد بدون شطة', icon: '🍃'),
    CookingTag(id: 'side_sauce', labelAr: 'الصوص جانبي', icon: '🥣'),
    CookingTag(id: 'well_done', labelAr: 'تسوية كاملة (Well-Done)', icon: '🔥'),
    CookingTag(id: 'medium', labelAr: 'تسوية وسط (Medium)', icon: '🥩'),
    CookingTag(id: 'low_salt', labelAr: 'ملح خفيف', icon: '🧂'),
    CookingTag(id: 'extra_crispy', labelAr: 'مقرمش زيادة', icon: '🍟'),
    CookingTag(id: 'extra_lemon', labelAr: 'زيادة ليمون', icon: '🍋'),
    CookingTag(id: 'kids_meal', labelAr: 'وجبة أطفال (بدون بهارات)', icon: '👶'),
  ];
}

/// Course timing notification / firing command record.
class CourseFireCommand {
  const CourseFireCommand({
    required this.orderId,
    required this.tableId,
    required this.tableNumber,
    required this.courseType,
    required this.firedAt,
    required this.firedByWaiterId,
    this.notes,
  });

  final String orderId;
  final String tableId;
  final int tableNumber;
  final CourseType courseType;
  final DateTime firedAt;
  final String firedByWaiterId;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'tableId': tableId,
    'tableNumber': tableNumber,
    'courseType': courseType.code,
    'firedAt': firedAt.toIso8601String(),
    'firedByWaiterId': firedByWaiterId,
    'notes': notes,
  };
}
