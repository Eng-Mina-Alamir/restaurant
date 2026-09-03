import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/branch_entity.dart';

/// Provider for the list of branches in the restaurant chain.
final branchesControllerProvider =
    StateNotifierProvider<BranchNotifier, List<BranchEntity>>((ref) {
  return BranchNotifier();
});

/// Currently selected branch ID in the dashboard.
/// `null` means "All Branches / كل الفروع" (Chain Overview for Super Admin).
final selectedBranchIdProvider = StateProvider<String?>((ref) => null);

/// Computed provider returning the currently selected [BranchEntity], or `null` if viewing all branches.
final activeBranchProvider = Provider<BranchEntity?>((ref) {
  final selectedId = ref.watch(selectedBranchIdProvider);
  if (selectedId == null) return null;
  final branches = ref.watch(branchesControllerProvider);
  return branches.firstWhere(
    (b) => b.id == selectedId,
    orElse: () => branches.first,
  );
});

/// Total combined sales across all branches in the chain.
final totalChainSalesProvider = Provider<double>((ref) {
  final branches = ref.watch(branchesControllerProvider);
  return branches.fold(0.0, (sum, b) => sum + b.todaySales);
});

/// Total combined orders across all branches in the chain.
final totalChainOrdersProvider = Provider<int>((ref) {
  final branches = ref.watch(branchesControllerProvider);
  return branches.fold(0, (sum, b) => sum + b.totalOrdersToday);
});

/// Total active orders across all branches in the chain.
final totalChainActiveOrdersProvider = Provider<int>((ref) {
  final branches = ref.watch(branchesControllerProvider);
  return branches.fold(0, (sum, b) => sum + b.activeOrdersCount);
});

class BranchNotifier extends StateNotifier<List<BranchEntity>> {
  BranchNotifier()
      : super(const [
          BranchEntity(
            id: 'branch-1',
            name: 'فرع المعادي',
            city: 'القاهرة',
            address: 'شارع النصر، المعادي الجديدة',
            phone: '01012345678',
            managerName: 'أحمد كمال',
            isOpen: true,
            totalTables: 24,
            activeOrdersCount: 0,
            todaySales: 0.0,
            totalOrdersToday: 0,
            rating: 4.9,
            colorValue: 0xFFC2410C,
          ),
          BranchEntity(
            id: 'branch-2',
            name: 'فرع التجمع الخامس',
            city: 'القاهرة الجديدة',
            address: 'شارع التسعين الشمالي، التجمع الخامس',
            phone: '01023456789',
            managerName: 'محمود سامي',
            isOpen: true,
            totalTables: 32,
            activeOrdersCount: 0,
            todaySales: 0.0,
            totalOrdersToday: 0,
            rating: 4.8,
            colorValue: 0xFF0F766E,
          ),
          BranchEntity(
            id: 'branch-3',
            name: 'فرع الشيخ زايد',
            city: 'الجيزة',
            address: 'مجمع أركان، الشيخ زايد',
            phone: '01034567890',
            managerName: 'طارق نبيل',
            isOpen: true,
            totalTables: 28,
            activeOrdersCount: 0,
            todaySales: 0.0,
            totalOrdersToday: 0,
            rating: 4.7,
            colorValue: 0xFF7C3AED,
          ),
          BranchEntity(
            id: 'branch-4',
            name: 'فرع الإسكندرية',
            city: 'الإسكندرية',
            address: 'طريق الجيش، الكورنيش، سموحة',
            phone: '01045678901',
            managerName: 'كريم عادل',
            isOpen: false,
            totalTables: 20,
            activeOrdersCount: 0,
            todaySales: 0.0,
            totalOrdersToday: 0,
            rating: 4.6,
            colorValue: 0xFF0284C7,
          ),
        ]);

  void addBranch(BranchEntity branch) {
    state = [...state, branch];
  }

  void updateBranch(BranchEntity updated) {
    state = [
      for (final b in state)
        if (b.id == updated.id) updated else b,
    ];
  }

  void toggleBranchStatus(String branchId) {
    state = [
      for (final b in state)
        if (b.id == branchId) b.copyWith(isOpen: !b.isOpen) else b,
    ];
  }

  void deleteBranch(String branchId) {
    state = state.where((b) => b.id != branchId).toList();
  }
}
