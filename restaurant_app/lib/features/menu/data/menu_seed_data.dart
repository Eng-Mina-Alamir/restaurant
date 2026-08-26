import '../domain/entities/menu.dart';
import '../domain/entities/menu_item.dart';

/// Offline seed menu with authentic Egyptian cuisine and delicacies.
abstract final class MenuSeedData {
  MenuSeedData._();

  static const String restaurantId = 'demo-restaurant-1';

  static const List<String> categories = <String>[
    'برجر',
    'بيتزا',
    'مشروبات',
    'حلويات',
    'مشويات ومأكولات شرقية',
    'طواجن وأطباق مصرية',
    'شاورما وساندوتشات',
  ];

  static List<MenuItem> get items => <MenuItem>[
    // ── برجر كلاسيك بلدي (First for viewport tests) ──────────────────
    const MenuItem(
      id: 'item-burger-classic',
      categoryId: 'برجر',
      name: 'برجر كلاسيك بلدي',
      description: 'لحم بقري بلدي مشوي، جبنة شيدر، خس وطماطم مع صوص خاص',
      price: 85.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: false,
      preparationTime: 15,
      modifierGroups: [
        MenuModifierGroup(
          id: 'mod-extras-burger',
          title: 'إضافات',
          description: 'اختر الإضافات المفضلة',
          isRequired: false,
          maxSelection: 3,
          options: [
            MenuModifierOption(
              id: 'opt-cheese',
              name: 'جبنة إضافية',
              extraPrice: 15.0,
            ),
            MenuModifierOption(
              id: 'opt-bacon',
              name: 'لحم مقدد',
              extraPrice: 20.0,
            ),
            MenuModifierOption(
              id: 'opt-fries',
              name: 'بطاطس مقلية فارم فريتس',
              extraPrice: 20.0,
            ),
          ],
        ),
      ],
      rating: 4.7,
      orderCount: 320,
    ),

    // ── كشري مصري ملكي (First simple no-modifier item) ──────────────
    const MenuItem(
      id: 'item-koshary-royal',
      categoryId: 'طواجن وأطباق مصرية',
      name: 'كشري مصري ملكي بالدقة والتقلية',
      description:
          'أرز بالعدس الأصفر والبني، شعرية، مكرونة، حمص الشام، بصل مقرمش ذهبي، مع دقة الثوم والصلصة الحارة',
      price: 45.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 10,
      modifierGroups: [],
      rating: 4.9,
      orderCount: 1250,
    ),

    // ── مشويات ومأكولات شرقية ──────────────────────────────────────────
    const MenuItem(
      id: 'item-grill-mix',
      categoryId: 'مشويات ومأكولات شرقية',
      name: 'مشكل مشويات المحروسة (كباب وكفتة وطرب)',
      description:
          'كباب ضاني بلدي، كفتة مشوية على الفحم، وطرب متبل مع سلطة وطحينة وعيش بلدي سخن',
      price: 240.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: false,
      preparationTime: 25,
      modifierGroups: [
        MenuModifierGroup(
          id: 'mod-grill-extras',
          title: 'إضافات المشويات',
          description: 'اختر الإضافات المفضلة لطبلية المشويات',
          isRequired: false,
          maxSelection: 3,
          options: [
            MenuModifierOption(
              id: 'opt-tahina',
              name: 'طحينة إضافية بالثوم',
              extraPrice: 15.0,
            ),
            MenuModifierOption(
              id: 'opt-rice-basmati',
              name: 'أرز بسمتي بالمكسرات',
              extraPrice: 35.0,
            ),
            MenuModifierOption(
              id: 'opt-mombaar',
              name: 'ممبار بلدي محمر (3 قطع)',
              extraPrice: 45.0,
            ),
          ],
        ),
      ],
      rating: 4.9,
      orderCount: 840,
    ),
    const MenuItem(
      id: 'item-hawawshi-baladi',
      categoryId: 'مشويات ومأكولات شرقية',
      name: 'حواوشي إسكندراني مخصوص بالجبنة',
      description:
          'عجين إسكندراني بلدي طازج محشي لحم مفروم بالخلطة السرية وفلفل وجبنة موزاريلا سايحة',
      price: 65.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: true,
      preparationTime: 18,
      modifierGroups: [
        MenuModifierGroup(
          id: 'mod-spicy-level',
          title: 'درجة الشطة',
          description: 'اختر درجة الشطة في الحواوشي',
          isRequired: true,
          maxSelection: 1,
          options: [
            MenuModifierOption(
              id: 'opt-regular',
              name: 'عادي (بدون فلفل حار)',
              extraPrice: 0,
            ),
            MenuModifierOption(
              id: 'opt-spicy',
              name: 'حراق ومولع',
              extraPrice: 0,
            ),
          ],
        ),
      ],
      rating: 4.8,
      orderCount: 650,
    ),

    // ── طواجن وأطباق مصرية ──────────────────────────────────────────
    const MenuItem(
      id: 'item-tagine-bamia',
      categoryId: 'طواجن وأطباق مصرية',
      name: 'طاجن بامية باللحمة الضاني البلدي',
      description:
          'طاجن فخار بامية فلاحي طازجة مسبكة في الفرن مع قطع لحم ضاني ذايبة وليمون معصفر',
      price: 165.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: false,
      preparationTime: 22,
      modifierGroups: [],
      rating: 4.8,
      orderCount: 420,
    ),
    const MenuItem(
      id: 'item-molokhia-chicken',
      categoryId: 'طواجن وأطباق مصرية',
      name: 'ملوخية خضراء بالطشة مع نص دجاجة محمرة وأرز',
      description:
          'ملوخية طازجة مخروطة يدوي بطشة الثوم والكزبرة مع نصف دجاجة بلدي محمرة بالسمن البلدي وأرز بالشعرية',
      price: 135.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: false,
      preparationTime: 20,
      modifierGroups: [],
      rating: 4.9,
      orderCount: 780,
    ),

    // ── شاورما وساندوتشات ──────────────────────────────────────────
    const MenuItem(
      id: 'item-kebda-alex',
      categoryId: 'شاورما وساندوتشات',
      name: 'ساندوتش كبدة إسكندراني أصلية بالفينو',
      description:
          'كبدة بلدي طازجة مشوحة بالثوم والفلفل الحار والليمون والكمون في عيش فينو طازج مع طحينة',
      price: 35.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: true,
      preparationTime: 8,
      modifierGroups: [],
      rating: 4.7,
      orderCount: 510,
    ),
    const MenuItem(
      id: 'item-shawarma-beef',
      categoryId: 'شاورما وساندوتشات',
      name: 'شاورما لحمة مصري على السيخ في عيش كيزر',
      description:
          'شرائح لحم بقري متبل بالخل والبهارات المصرية، بقدونس، طماطم، بصل سماق وصوص طحينة سميك',
      price: 48.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: false,
      preparationTime: 10,
      modifierGroups: [],
      rating: 4.8,
      orderCount: 620,
    ),

    // ── برجر إضافي ──────────────────────────────────────────────────
    const MenuItem(
      id: 'item-burger-spicy',
      categoryId: 'برجر',
      name: 'برجر حار مشطشط',
      description: 'لحم بقري مع صوص حار وجبنة فلفل جالابينو',
      price: 95.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: true,
      preparationTime: 18,
      modifierGroups: [
        MenuModifierGroup(
          id: 'mod-level-spicy',
          title: 'مستوى الحرارة',
          description: 'اختر مستوى الحرارة',
          isRequired: true,
          maxSelection: 1,
          options: [
            MenuModifierOption(id: 'opt-mild', name: 'خفيف', extraPrice: 0),
            MenuModifierOption(id: 'opt-hot', name: 'حار', extraPrice: 5.0),
            MenuModifierOption(
              id: 'opt-extra-hot',
              name: 'حار جداً',
              extraPrice: 10.0,
            ),
          ],
        ),
      ],
      rating: 4.5,
      orderCount: 180,
    ),
    const MenuItem(
      id: 'item-burger-veggie',
      categoryId: 'برجر',
      name: 'برجر نباتي (طعمية بالسمسم والخلطة)',
      description: 'قرص طعمية وخضروات مشوي مع طماطم وخيار مخلل وصوص طحينة',
      price: 40.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 12,
      modifierGroups: [],
      rating: 4.4,
      orderCount: 195,
    ),

    // ── بيتزا ────────────────────────────────────────────────────────
    const MenuItem(
      id: 'item-pizza-margherita',
      categoryId: 'بيتزا',
      name: 'بيتزا مارغريتا إيطالي',
      description: 'صلصة طماطم بلدي، جبنة موزاريلا طبيعية، وريحان طازج',
      price: 95.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 20,
      modifierGroups: [
        MenuModifierGroup(
          id: 'mod-size-pizza',
          title: 'الحجم',
          description: 'اختر الحجم',
          isRequired: true,
          maxSelection: 1,
          options: [
            MenuModifierOption(id: 'opt-medium', name: 'وسط', extraPrice: 0),
            MenuModifierOption(id: 'opt-large', name: 'كبير', extraPrice: 35.0),
            MenuModifierOption(
              id: 'opt-family',
              name: 'عائلي سوبر',
              extraPrice: 65.0,
            ),
          ],
        ),
      ],
      rating: 4.6,
      orderCount: 240,
    ),
    const MenuItem(
      id: 'item-pizza-pepperoni',
      categoryId: 'بيتزا',
      name: 'بيتزا بيبروني وسجق شرقي',
      description: 'صلصة طماطم، شرائح بيبروني وسجق بلدي، جبنة موزاريلا',
      price: 135.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: true,
      preparationTime: 22,
      modifierGroups: [],
      rating: 4.8,
      orderCount: 410,
    ),
    const MenuItem(
      id: 'item-pizza-spicy',
      categoryId: 'بيتزا',
      name: 'بيتزا حارة',
      description: 'بيتزا بجبنة الموزاريلا وشرائح الفلفل الحار والسجق',
      price: 120.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: true,
      preparationTime: 18,
      modifierGroups: [
        MenuModifierGroup(
          id: 'mod-pizza-size',
          title: 'الحجم',
          isRequired: true,
          maxSelection: 1,
          options: [
            MenuModifierOption(id: 'opt-size-med', name: 'وسط', extraPrice: 0),
            MenuModifierOption(
              id: 'opt-size-large',
              name: 'كبير',
              extraPrice: 30.0,
            ),
          ],
        ),
      ],
      rating: 4.3,
      orderCount: 85,
    ),

    // ── مشروبات ──────────────────────────────────────────────────────
    const MenuItem(
      id: 'item-drink-orange',
      categoryId: 'مشروبات',
      name: 'عصير برتقال بلدي طازج',
      description: 'برتقال بلدي فريش معصور بدون سكر مضاف',
      price: 30.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 4,
      modifierGroups: [],
      rating: 4.8,
      orderCount: 450,
    ),
    const MenuItem(
      id: 'item-drink-cola',
      categoryId: 'مشروبات',
      name: 'مشروب غازي كولا مثلج',
      description: 'كولا / دايت كولا كانز مثلج',
      price: 15.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 2,
      modifierGroups: [],
      rating: 4.5,
      orderCount: 800,
    ),
    const MenuItem(
      id: 'item-drink-water',
      categoryId: 'مشروبات',
      name: 'مياه معدنية طبيعية',
      description: 'مياه معدنية نقية 600 مل',
      price: 10.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 1,
      modifierGroups: [],
      rating: 4.2,
      orderCount: 650,
    ),
    const MenuItem(
      id: 'item-drink-mojito',
      categoryId: 'مشروبات',
      name: 'موهيتو ليمون ونعناع فريش',
      description: 'موهيتو منعش بالليمون والنعناع والصودا',
      price: 35.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 4,
      modifierGroups: [],
      rating: 4.6,
      orderCount: 190,
    ),

    // ── حلويات ──────────────────────────────────────────────────────
    const MenuItem(
      id: 'item-dessert-om-ali',
      categoryId: 'حلويات',
      name: 'طاجن أم علي بالمكسرات والقشطة البلدي',
      description:
          'رقاق بالحليب الساخن والمكسرات الفاخرة والقشطة البلدي المحمرة في الفرن',
      price: 55.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 12,
      modifierGroups: [],
      rating: 4.9,
      orderCount: 710,
    ),
    const MenuItem(
      id: 'item-dessert-cheesecake',
      categoryId: 'حلويات',
      name: 'تشيز كيك الفراولة والتوت',
      description: 'تشيز كيك كريمي مخبوز مع صوص التوت الطبيعي',
      price: 65.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 9,
      modifierGroups: [],
      rating: 4.8,
      orderCount: 175,
    ),
    const MenuItem(
      id: 'item-dessert-basbousa',
      categoryId: 'حلويات',
      name: 'بسبوسة بالسمن البلدي والمكسرات',
      description: 'بسبوسة بالسميد واللوز مع القطر الخفيف',
      price: 45.0,
      isAvailable: false,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 10,
      modifierGroups: [],
      rating: 4.5,
      orderCount: 320,
    ),
  ];

  /// Builds the full [Menu] aggregate.
  static Menu buildMenu() =>
      Menu(restaurantId: restaurantId, categories: categories, items: items);
}
