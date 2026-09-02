import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/repositories/supabase_branch_repository.dart';
import '../../domain/entities/branch_entity.dart';

/// Provider for the list of branches in the restaurant chain.
final branchesControllerProvider =
    StateNotifierProvider<BranchNotifier, List<BranchEntity>>((ref) {
  final repo = ref.watch(supabaseBranchRepositoryProvider);
  return BranchNotifier(repo);
});

/// Currently selected branch ID in the dashboard.
/// `null` means "All Branches / كل الفروع" (Chain Overview for Super Admin).
final selectedBranchIdProvider = StateProvider<String?>((ref) => null);

/// Computed provider returning the currently selected [BranchEntity], or `null` if viewing all branches.
final activeBranchProvider = Provider<BranchEntity?>((ref) {
  final selectedId = ref.watch(selectedBranchIdProvider);
  if (selectedId == null) return null;
  final branches = ref.watch(branchesControllerProvider);
  if (branches.isEmpty) return null;
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
  BranchNotifier([this._repository]) : super(const []) {
    loadBranches();
  }

  final SupabaseBranchRepository? _repository;

  Future<void> loadBranches() async {
    if (_repository == null) return;
    final result = await _repository.getBranches();
    result.when(
      onLeft: (_) {},
      onRight: (branches) {
        if (mounted) state = branches;
      },
    );
  }

  /// Toggles open/closed status for a branch in the chain.
  void toggleBranchStatus(String branchId) {
    state = state.map((b) {
      if (b.id == branchId) {
        return b.copyWith(isOpen: !b.isOpen);
      }
      return b;
    }).toList();
  }

  /// Adds a new branch to the chain.
  void addBranch(BranchEntity branch) {
    state = [...state, branch];
  }

  /// Updates existing branch settings.
  void updateBranch(BranchEntity branch) {
    state = state.map((b) => b.id == branch.id ? branch : b).toList();
  }
}
