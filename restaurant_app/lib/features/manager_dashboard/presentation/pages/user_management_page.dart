import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../restaurant/domain/entities/branch_entity.dart';
import '../../../restaurant/presentation/controllers/branch_controller.dart';

/// State notifier managing employee and user list for the restaurant chain.
class UserManagementController extends StateNotifier<List<UserEntity>> {
  final SupabaseClient? _supabase;

  UserManagementController(this._supabase) : super([]) {
    _init();
  }

  Future<void> _init() async {
    if (AppConfig.useSupabase && _supabase != null) {
      try {
        final res = await _supabase.from('profiles').select().order('created_at');
        if (res.isNotEmpty) {
          final users = (res as List).map((row) {
            final map = Map<String, dynamic>.from(row as Map);
            return UserEntity(
              id: map['id']?.toString() ?? '',
              name: map['name']?.toString() ?? '',
              email: map['email']?.toString() ?? '',
              phone: map['phone']?.toString() ?? '',
              role: UserRole.fromName(map['role']?.toString()),
              restaurantId: map['restaurant_id']?.toString() ?? 'branch-1',
              createdAt:
                  DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              isActive: true,
            );
          }).toList();
          state = users;
          return;
        }
      } catch (e, st) {
        AppLogger.warning(
          'UserManagementController load fallback: $e',
          error: e,
          stackTrace: st,
        );
      }
    }
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    state = [
      UserEntity(
        id: 'usr-1',
        name: 'سالم الشمري',
        email: 'salem@restaurant.com',
        phone: '0501112233',
        role: UserRole.waiter,
        restaurantId: 'branch-1',
        createdAt: now.subtract(const Duration(days: 90)),
        isActive: true,
      ),
      UserEntity(
        id: 'usr-2',
        name: 'شيف مصطفى كمال',
        email: 'mustafa@restaurant.com',
        phone: '0502223344',
        role: UserRole.kitchen,
        restaurantId: 'branch-1',
        createdAt: now.subtract(const Duration(days: 120)),
        isActive: true,
      ),
      UserEntity(
        id: 'usr-3',
        name: 'خالد العتيبي',
        email: 'khaled@restaurant.com',
        phone: '0503334455',
        role: UserRole.driver,
        restaurantId: 'branch-2',
        createdAt: now.subtract(const Duration(days: 45)),
        isActive: true,
      ),
      UserEntity(
        id: 'usr-4',
        name: 'فاطمة الدوسري',
        email: 'fatima@restaurant.com',
        phone: '0504445566',
        role: UserRole.manager,
        restaurantId: 'branch-1',
        createdAt: now.subtract(const Duration(days: 200)),
        isActive: true,
      ),
      UserEntity(
        id: 'usr-5',
        name: 'محمود سامي',
        email: 'mahmoud@restaurant.com',
        phone: '0505556677',
        role: UserRole.manager,
        restaurantId: 'branch-2',
        createdAt: now.subtract(const Duration(days: 110)),
        isActive: true,
      ),
      UserEntity(
        id: 'usr-6',
        name: 'عمر ياسين',
        email: 'omar@restaurant.com',
        phone: '0506667788',
        role: UserRole.waiter,
        restaurantId: 'branch-3',
        createdAt: now.subtract(const Duration(days: 15)),
        isActive: true,
      ),
    ];
  }

  Future<void> addUser({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String restaurantId = 'branch-1',
  }) async {
    final newUser = UserEntity(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      restaurantId: restaurantId,
      createdAt: DateTime.now(),
      isActive: true,
    );
    state = [...state, newUser];

    if (AppConfig.useSupabase && _supabase != null) {
      try {
        await _supabase.from('profiles').insert({
          'name': name,
          'email': email,
          'phone': phone,
          'role': role.name,
          'restaurant_id': restaurantId,
        });
      } catch (e, st) {
        AppLogger.warning('addUser persistence error: $e', error: e, stackTrace: st);
      }
    }
  }

  Future<void> updateUser(UserEntity user) async {
    state = state.map((u) => u.id == user.id ? user : u).toList();

    if (AppConfig.useSupabase && _supabase != null) {
      try {
        await _supabase.from('profiles').update({
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'role': user.role.name,
          'restaurant_id': user.restaurantId,
        }).eq('id', user.id);
      } catch (e, st) {
        AppLogger.warning('updateUser persistence error: $e', error: e, stackTrace: st);
      }
    }
  }

  void toggleStatus(String userId) {
    state = state.map((u) {
      if (u.id == userId) {
        return u.copyWith(isActive: !u.isActive);
      }
      return u;
    }).toList();
  }

  Future<void> deleteUser(String userId) async {
    state = state.where((u) => u.id != userId).toList();
    if (AppConfig.useSupabase && _supabase != null) {
      try {
        await _supabase.from('profiles').delete().eq('id', userId);
      } catch (e, st) {
        AppLogger.warning('deleteUser persistence error: $e', error: e, stackTrace: st);
      }
    }
  }
}

final userManagementControllerProvider =
    StateNotifierProvider<UserManagementController, List<UserEntity>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return UserManagementController(supabase);
});

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  UserRole? _filterRole;
  String? _filterBranchId;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(userManagementControllerProvider);
    final branches = ref.watch(branchesControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredUsers = users.where((u) {
      final matchesRole = _filterRole == null || u.role == _filterRole;
      final matchesBranch =
          _filterBranchId == null || u.restaurantId == _filterBranchId;
      final q = _search.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.contains(q);
      return matchesRole && matchesBranch && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين وتعيين الفروع'),
        actions: [
          IconButton(
            tooltip: 'إضافة موظف',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _showAddUserDialog(context, branches),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, branches),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة موظف'),
      ),
      body: ConstrainedContentView(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: TextField(
                onChanged: (val) => setState(() => _search = val),
                decoration: InputDecoration(
                  hintText: 'البحث بالاسم أو البريد أو الهاتف...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Branch Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('كل الفروع'),
                    selected: _filterBranchId == null,
                    onSelected: (_) => setState(() => _filterBranchId = null),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  for (final branch in branches)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: branch.color,
                          radius: 5,
                        ),
                        label: Text(branch.name),
                        selected: _filterBranchId == branch.id,
                        onSelected: (_) =>
                            setState(() => _filterBranchId = branch.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Role Chips Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('جميع الأدوار (${users.length})'),
                    selected: _filterRole == null,
                    onSelected: (_) => setState(() => _filterRole = null),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  for (final role in UserRole.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(
                          '${role.labelAr} (${users.where((u) => u.role == role).length})',
                        ),
                        selected: _filterRole == role,
                        onSelected: (_) => setState(() => _filterRole = role),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // List of Users
            Expanded(
              child: filteredUsers.isEmpty
                  ? const EmptyState(
                      message: 'لا يوجد موظفون بهذه المعايير',
                      icon: Icons.people_outline,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        80,
                      ),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final roleColor = _roleColor(user.role, colorScheme);
                        final branchName = _branchNameOf(user.restaurantId, branches);

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: roleColor.withValues(alpha: 0.15),
                              foregroundColor: roleColor,
                              child: Icon(_roleIcon(user.role)),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                if (!user.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.error.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.xs),
                                    ),
                                    child: Text(
                                      'معطل',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      branchName,
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('• ${user.role.labelAr} • ${user.phone}'),
                                  ],
                                ),
                                Text(
                                  user.email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) {
                                if (val == 'toggle') {
                                  ref
                                      .read(
                                        userManagementControllerProvider.notifier,
                                      )
                                      .toggleStatus(user.id);
                                } else if (val == 'edit') {
                                  _showEditUserDialog(context, user, branches);
                                } else if (val == 'delete') {
                                  _confirmDelete(context, user);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        user.isActive
                                            ? Icons.block
                                            : Icons.check_circle_outline,
                                        size: 18,
                                        color: user.isActive
                                            ? StatusColors.tone(
                                                SemanticTone.warning,
                                                theme.brightness,
                                              )
                                            : StatusColors.tone(
                                                SemanticTone.success,
                                                theme.brightness,
                                              ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        user.isActive
                                            ? 'تعطيل الحساب'
                                            : 'تفعيل الحساب',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('تعديل البيانات والفرع'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: colorScheme.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'حذف الحساب',
                                        style: TextStyle(color: colorScheme.error),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _branchNameOf(String? branchId, List<BranchEntity> branches) {
    if (branchId == null || branchId.isEmpty) return 'فرع رئيسي';
    final found = branches.where((b) => b.id == branchId);
    return found.isNotEmpty ? found.first.name : 'فرع $branchId';
  }

  Color _roleColor(UserRole role, ColorScheme colorScheme) {
    switch (role) {
      case UserRole.customer:
        return colorScheme.outline;
      case UserRole.waiter:
        return const Color(0xFF0284C7);
      case UserRole.kitchen:
        return const Color(0xFFD97706);
      case UserRole.manager:
        return colorScheme.primary;
      case UserRole.admin:
        return const Color(0xFF7C3AED);
      case UserRole.driver:
        return const Color(0xFF10B981);
      case UserRole.cashier:
        return const Color(0xFF0F766E);
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return Icons.person_outline;
      case UserRole.waiter:
        return Icons.room_service_outlined;
      case UserRole.kitchen:
        return Icons.soup_kitchen_outlined;
      case UserRole.manager:
        return Icons.manage_accounts_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.driver:
        return Icons.delivery_dining_outlined;
      case UserRole.cashier:
        return Icons.point_of_sale_outlined;
    }
  }

  void _showAddUserDialog(BuildContext context, List<BranchEntity> branches) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    UserRole role = UserRole.waiter;
    String selectedBranch = branches.isNotEmpty ? branches.first.id : 'branch-1';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إضافة موظف جديد وتعيين الفرع',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالكامل *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedBranch,
                  items: branches
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text('📍 ${b.name} (${b.city})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedBranch = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'الفرع التابع له *',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  items: UserRole.values
                      .map(
                        (r) =>
                            DropdownMenuItem(value: r, child: Text(r.labelAr)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => role = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'الدور والوظيفة *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                      );
                      return;
                    }

                    ref
                        .read(userManagementControllerProvider.notifier)
                        .addUser(
                          name: name,
                          email: email,
                          phone: phone,
                          role: role,
                          restaurantId: selectedBranch,
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('إضافة الموظف للفرع'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(
    BuildContext context,
    UserEntity user,
    List<BranchEntity> branches,
  ) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);
    UserRole role = user.role;
    String selectedBranch = user.restaurantId ??
        (branches.isNotEmpty ? branches.first.id : 'branch-1');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تعديل بيانات: ${user.name}',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالكامل *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedBranch,
                  items: branches
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text('📍 ${b.name} (${b.city})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedBranch = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'الفرع التابع له *',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  items: UserRole.values
                      .map(
                        (r) =>
                            DropdownMenuItem(value: r, child: Text(r.labelAr)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => role = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'الدور والوظيفة *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (name.isEmpty || email.isEmpty || phone.isEmpty) return;

                    final updated = user.copyWith(
                      name: name,
                      email: email,
                      phone: phone,
                      role: role,
                      restaurantId: selectedBranch,
                    );
                    ref
                        .read(userManagementControllerProvider.notifier)
                        .updateUser(updated);
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ التعديلات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserEntity user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الموظف'),
        content: Text('هل أنت متأكد من رغبتك في حذف حساب "${user.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              ref
                  .read(userManagementControllerProvider.notifier)
                  .deleteUser(user.id);
              Navigator.pop(ctx);
            },
            child: const Text(AppConstants.delete),
          ),
        ],
      ),
    );
  }
}
