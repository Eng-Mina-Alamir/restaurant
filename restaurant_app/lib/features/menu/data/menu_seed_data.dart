import '../domain/entities/menu.dart';
import '../domain/entities/menu_item.dart';

/// Offline seed menu used until a live backend is available.
///
/// Provides a small but representative Arabic menu with categories, items and
/// modifier groups (including paid extras) so the customer flow can be
/// exercised end-to-end without a network.
abstract final class MenuSeedData {
  MenuSeedData._();

  static const String restaurantId = 'demo-restaurant-1';

  static const List<String> categories = <String>[
    'برجر',
    'بيتزا',
    'مشروبات',
    'حلويات',
  ];

  static List<MenuItem> get items => <MenuItem>[
    // ── برجر ──────────────────────────────────────────────────────────────
    const MenuItem(
      id: 'item-burger-classic',
      categoryId: 'برجر',
      name: 'برجر كلاسيك',
      description: 'لحم بقري مشوي، جبنة شيدر، خس وطماطم مع صوص خاص',
      price: 28.0,
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
              extraPrice: 4.0,
            ),
            MenuModifierOption(
              id: 'opt-bacon',
              name: 'لحم مقدد',
              extraPrice: 6.0,
            ),
            MenuModifierOption(
              id: 'opt-fries',
              name: 'بطاطس مقلية',
              extraPrice: 5.0,
            ),
          ],
        ),
      ],
      rating: 4.7,
      orderCount: 320,
    ),
    const MenuItem(
      id: 'item-burger-spicy',
      categoryId: 'برجر',
      name: 'برجر حار',
      description: 'لحم بقري مع صوص حار وجبنة فلفل جالابينو',
      price: 32.0,
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
            MenuModifierOption(id: 'opt-hot', name: 'حار', extraPrice: 1.5),
            MenuModifierOption(
              id: 'opt-extra-hot',
              name: 'حار جداً',
              extraPrice: 3.0,
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
      name: 'برجر نباتي',
      description: 'قرص نباتي مشوي مع خضروات طازجة وصوص الثوم',
      price: 26.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 14,
      modifierGroups: [],
      rating: 4.3,
      orderCount: 95,
    ),

    // ── بيتزا ──────────────────────────────────────────────────────────────
    const MenuItem(
      id: 'item-pizza-margherita',
      categoryId: 'بيتزا',
      name: 'بيتزا مارغريتا',
      description: 'صوص طماطم، جبنة موزاريلا، ريحان طازج',
      price: 42.0,
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
            MenuModifierOption(id: 'opt-large', name: 'كبير', extraPrice: 10.0),
            MenuModifierOption(
              id: 'opt-family',
              name: 'عائلي',
              extraPrice: 18.0,
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
      name: 'بيتزا بيبروني',
      description: 'صوص طماطم، بيبروني، جبنة موزاريلا',
      price: 48.0,
      isAvailable: true,
      isVegetarian: false,
      isSpicy: true,
      preparationTime: 22,
      modifierGroups: [],
      rating: 4.8,
      orderCount: 410,
    ),

    // ── مشروبات ────────────────────────────────────────────────────────────
    const MenuItem(
      id: 'item-drink-cola',
      categoryId: 'مشروبات',
      name: 'مشروب غازي',
      description: 'كولا / دايت — وسط',
      price: 6.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 2,
      modifierGroups: [],
      rating: 4.0,
      orderCount: 800,
    ),
    const MenuItem(
      id: 'item-drink-orange',
      categoryId: 'مشروبات',
      name: 'عصير برتقال طازج',
      description: 'برتقال طازج 100% بدون سكر مضاف',
      price: 14.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 4,
      modifierGroups: [],
      rating: 4.4,
      orderCount: 150,
    ),
    const MenuItem(
      id: 'item-drink-water',
      categoryId: 'مشروبات',
      name: 'مياه معدنية',
      description: 'مياه معدنية 500 مل',
      price: 2.5,
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
      name: 'موهيتو بالنعناع',
      description: 'موهيتو منعش بالنعناع والليمون',
      price: 14.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 4,
      modifierGroups: [],
      rating: 4.6,
      orderCount: 90,
    ),

    // ── حلويات ───────────────────────────────────────────────────────────
    const MenuItem(
      id: 'item-dessert-chocolate',
      categoryId: 'حلويات',
      name: 'كيك الشوكولاتة',
      description: 'كيك شوكولاتة فاخر مع صوص الشوكولاتة',
      price: 22.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 8,
      modifierGroups: [],
      rating: 4.7,
      orderCount: 210,
    ),
    const MenuItem(
      id: 'item-dessert-cheesecake',
      categoryId: 'حلويات',
      name: 'تشيز كيك التوت',
      description: 'تشيز كيك كريمي مع صوص التوت الطازج',
      price: 26.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 9,
      modifierGroups: [],
      rating: 4.8,
      orderCount: 175,
    ),
    // Kept unavailable to exercise the "out of stock" flow end-to-end.
    const MenuItem(
      id: 'item-dessert-basbousa',
      categoryId: 'حلويات',
      name: 'بسبوسة',
      description: 'بسبوسة بالسميد مع القطر واللوز',
      price: 18.0,
      isAvailable: false,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 10,
      modifierGroups: [],
      rating: 4.5,
      orderCount: 320,
    ),

    // ── بيتزا ──────────────────────────────────────────────────────────────
    const MenuItem(
      id: 'item-pizza-spicy',
      categoryId: 'بيتزا',
      name: 'بيتزا حارة',
      description: 'بيتزا بجبنة الموزاريلا وشرائح الفلفل الحار والسجق',
      price: 32.0,
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
              extraPrice: 8,
            ),
          ],
        ),
      ],
      rating: 4.3,
      orderCount: 85,
    ),
    const MenuItem(
      id: 'item-burger-veggie',
      categoryId: 'برجر',
      name: 'برجر نباتي',
      description: 'قرص نباتي مشوي مع خس وطماطم وصوص الثوم',
      price: 30.0,
      isAvailable: true,
      isVegetarian: true,
      isSpicy: false,
      preparationTime: 14,
      modifierGroups: [],
      rating: 4.1,
      orderCount: 60,
    ),
  ];

  /// Builds the full [Menu] aggregate.
  static Menu buildMenu() =>
      Menu(restaurantId: restaurantId, categories: categories, items: items);
}
