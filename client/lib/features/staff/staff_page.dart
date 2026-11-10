import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../l10n/l10n.dart';
import '../shops/shops_page.dart';

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.shopIds,
    required this.active,
  });

  final String id;
  final String name;
  final String username;
  final AppRole role;
  final List<String> shopIds;
  final bool active;

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
        id: j['_id'] as String,
        name: j['name'] as String,
        username: j['username'] as String,
        role: AppRole.parse(j['role'] as String),
        shopIds: (j['shopIds'] as List).cast<String>(),
        active: j['active'] as bool? ?? true,
      );
}

final staffProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) async {
  final j = await ref.watch(apiClientProvider).get('/users') as List;
  // The franchise admin account itself is managed by the platform, not listed here.
  return [
    for (final u in j.cast<Map<String, dynamic>>())
      if (u['role'] != 'owner') StaffMember.fromJson(u),
  ];
});

/// Franchise admin: create and manage store-owner / employee credentials.
class StaffPage extends ConsumerWidget {
  const StaffPage({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [StaffMember? staff]) async {
    final l10n = context.l10n;
    final shops = await ref.read(shopsProvider.future).catchError((_) => <Shop>[]);
    if (!context.mounted) return;
    if (shops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.staffNeedShop)));
      return;
    }

    final name = TextEditingController(text: staff?.name);
    final username = TextEditingController(text: staff?.username);
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var role = staff?.role ?? AppRole.manager;
    var shopId = staff != null && staff.shopIds.isNotEmpty ? staff.shopIds.first : shops.first.id;
    if (!shops.any((s) => s.id == shopId)) shopId = shops.first.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(staff == null ? l10n.staffAdd : l10n.staffEdit),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: InputDecoration(labelText: l10n.staffName),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.authFieldRequired : null,
                  ),
                  TextFormField(
                    controller: username,
                    enabled: staff == null, // usernames are fixed after creation
                    autocorrect: false,
                    decoration: InputDecoration(labelText: l10n.authUsername),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? l10n.authFieldRequired
                        : null,
                  ),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: staff == null ? l10n.authPassword : l10n.staffNewPassword,
                    ),
                    validator: (v) {
                      final empty = v == null || v.isEmpty;
                      if (empty) return staff == null ? l10n.authFieldRequired : null;
                      return v.length < 8 ? l10n.staffPasswordMin : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppRole>(
                    initialValue: role,
                    decoration: InputDecoration(labelText: l10n.staffRole),
                    items: [
                      for (final r in const [AppRole.manager, AppRole.employee])
                        DropdownMenuItem(value: r, child: Text(r.label(l10n))),
                    ],
                    onChanged: (v) => setState(() => role = v ?? role),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: shopId,
                    decoration: InputDecoration(labelText: l10n.staffShop),
                    items: [
                      for (final s in shops) DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ],
                    onChanged: (v) => setState(() => shopId = v ?? shopId),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;

    final api = ref.read(apiClientProvider);
    try {
      if (staff == null) {
        await api.post('/users', body: {
          'name': name.text.trim(),
          'username': username.text.trim(),
          'password': password.text,
          'role': role.name,
          'shopIds': [shopId],
        });
      } else {
        await api.patch('/users/${staff.id}', body: {
          'name': name.text.trim(),
          'role': role.name,
          'shopIds': [shopId],
          if (password.text.isNotEmpty) 'password': password.text,
        });
      }
      ref.invalidate(staffProvider);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, StaffMember s) async {
    try {
      await ref.read(apiClientProvider).patch('/users/${s.id}', body: {'active': !s.active});
      ref.invalidate(staffProvider);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final staff = ref.watch(staffProvider);
    final shopNames = {
      for (final s in ref.watch(shopsProvider).valueOrNull ?? const <Shop>[]) s.id: s.name,
    };

    return AdminScaffold(
      title: l10n.navStaff,
      addLabel: l10n.staffAdd,
      onAdd: () => _edit(context, ref),
      body: staff.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(staffProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.staffEmpty))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = list[i];
                  final shop = s.shopIds.map((id) => shopNames[id]).whereType<String>().join(', ');
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(child: Text(s.name.characters.first.toUpperCase())),
                      title: Text(s.name),
                      subtitle: Text([
                        '@${s.username}',
                        s.role.label(l10n),
                        if (shop.isNotEmpty) shop,
                        if (!s.active) l10n.statusDisabled,
                      ].join(' · ')),
                      onTap: () => _edit(context, ref, s),
                      trailing: Switch(value: s.active, onChanged: (_) => _toggle(context, ref, s)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
