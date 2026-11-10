import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';

/// Role names match the server ([server/src/types/models.ts]).
enum AppRole {
  /// Franchise admin: whole franchise, all shops, staff.
  owner,

  /// Store owner: own shop(s) only, no staff management.
  manager,

  /// Cashier: own shop(s), billing/orders only.
  employee;

  static AppRole parse(String v) =>
      AppRole.values.firstWhere((r) => r.name == v, orElse: () => AppRole.employee);

  String label(AppLocalizations l) => switch (this) {
        AppRole.owner => l.roleFranchiseAdmin,
        AppRole.manager => l.roleStoreOwner,
        AppRole.employee => l.roleEmployee,
      };
}

/// Feature areas. Names match the server's `Permission` type; the server is the
/// source of truth and sends the list with the session.
enum Permission {
  home,
  shop,
  menu,
  orders,
  ledger,
  inventory,
  shops,
  staff,
  profile,
  settings;

  static Permission? tryParse(String v) {
    for (final p in Permission.values) {
      if (p.name == v) return p;
    }
    return null;
  }
}

@immutable
class ShopRef {
  const ShopRef({required this.id, required this.name, required this.active});

  final String id;
  final String name;
  final bool active;

  factory ShopRef.fromJson(Map<String, dynamic> j) => ShopRef(
        id: j['id'] as String,
        name: j['name'] as String,
        active: j['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'active': active};
}

/// Signed-in user, their franchise, permissions and shops.
@immutable
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.name,
    required this.username,
    required this.role,
    required this.tenantName,
    required this.permissions,
    required this.shops,
  });

  final String userId;
  final String name;
  final String username;
  final AppRole role;
  final String tenantName;
  final Set<Permission> permissions;

  /// Franchise admin: every shop. Store owner/employee: only their own.
  final List<ShopRef> shops;

  bool can(Permission p) => permissions.contains(p);

  bool get isFranchiseAdmin => role == AppRole.owner;

  /// Store-scoped users are permanently limited to their shop; the UI must not
  /// show shop pickers, shop columns or the shop name redundantly.
  bool get isStoreScoped => !isFranchiseAdmin;

  /// The fixed shop for store-scoped users (their first assigned shop).
  ShopRef? get ownShop => isStoreScoped && shops.isNotEmpty ? shops.first : null;

  factory AuthSession.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>;
    return AuthSession(
      userId: user['_id'] as String,
      name: user['name'] as String,
      username: user['username'] as String,
      role: AppRole.parse(user['role'] as String),
      tenantName: (j['tenant'] as Map<String, dynamic>)['name'] as String,
      permissions: {
        for (final p in (j['permissions'] as List).cast<String>())
          if (Permission.tryParse(p) != null) Permission.tryParse(p)!,
      },
      shops: [
        for (final s in (j['shops'] as List).cast<Map<String, dynamic>>()) ShopRef.fromJson(s),
      ],
    );
  }
}
