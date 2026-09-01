enum MenuEngineeringCategory {
  star('🌟 نجم (Star)', 'ربح مرتفع + مبيعات مرتفعة', 'حافظ على الجودة والموقع المميز في المنيو'),
  plowhorse('🐎 جواد عمل (Plowhorse)', 'ربح منخفض + مبيعات مرتفعة', 'ارفع السعر قليلاً أو قلل تكلفة المكونات'),
  puzzle('🧩 لغز (Puzzle)', 'ربح مرتفع + مبيعات منخفضة', 'كثف التسويق وقدمه في عروض مميزة'),
  dog('🐕 غير مجدي (Dog)', 'ربح منخفض + مبيعات منخفضة', 'أعد تقييم الصنف أو احذفه من المنيو واستبدله');

  final String titleAr;
  final String descriptionAr;
  final String strategyAr;
  const MenuEngineeringCategory(this.titleAr, this.descriptionAr, this.strategyAr);
}

/// Represents an analysis row for Menu Engineering matrix.
class MenuEngineeringItem {
  const MenuEngineeringItem({
    required this.menuItemId,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.foodCost,
    required this.salesCount,
    required this.grossMargin,
    required this.foodCostPercentage,
    required this.classification,
  });

  final String menuItemId;
  final String name;
  final String category;
  final double sellingPrice;
  final double foodCost;
  final int salesCount;
  final double grossMargin;
  final double foodCostPercentage;
  final MenuEngineeringCategory classification;

  double get totalRevenue => sellingPrice * salesCount;
  double get totalProfit => grossMargin * salesCount;
}
