import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../profile_providers.dart';

class ProfileDesktopView extends ConsumerStatefulWidget {
  const ProfileDesktopView({super.key});

  @override
  ConsumerState<ProfileDesktopView> createState() => _ProfileDesktopViewState();
}

class _ProfileDesktopViewState extends ConsumerState<ProfileDesktopView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _pwdCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _shopNameCtrl;
  late TextEditingController _shopAddressCtrl;

  static const _navItems = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    (icon: Icons.store_outlined, selectedIcon: Icons.store, label: 'Shop', route: AppRoutes.shop),
    (icon: Icons.restaurant_menu_outlined, selectedIcon: Icons.restaurant_menu, label: 'Menu', route: AppRoutes.menu),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', route: AppRoutes.orders),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: AppRoutes.settings),
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileViewModelProvider);
    _nameCtrl = TextEditingController(text: state.name);
    _pwdCtrl = TextEditingController(text: state.password);
    _phoneCtrl = TextEditingController(text: state.phone);
    _shopNameCtrl = TextEditingController(text: state.shopName);
    _shopAddressCtrl = TextEditingController(text: state.shopAddress);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pwdCtrl.dispose();
    _phoneCtrl.dispose();
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    super.dispose();
  }

  void _syncControllersWithState() {
    final state = ref.read(profileViewModelProvider);
    if (_nameCtrl.text != state.name) _nameCtrl.text = state.name;
    if (_pwdCtrl.text != state.password) _pwdCtrl.text = state.password;
    if (_phoneCtrl.text != state.phone) _phoneCtrl.text = state.phone;
    if (_shopNameCtrl.text != state.shopName) _shopNameCtrl.text = state.shopName;
    if (_shopAddressCtrl.text != state.shopAddress) _shopAddressCtrl.text = state.shopAddress;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileViewModelProvider, (prev, next) {
      if (next.saveSuccess && !(prev?.saveSuccess ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile settings updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    _syncControllersWithState();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(profileViewModelProvider);
    final vm = ref.read(profileViewModelProvider.notifier);

    return Scaffold(
      body: Row(
        children: [
          // Navigation Drawer
          NavigationDrawer(
            selectedIndex: 4, // Profile selected
            onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 10),
                child: Text(
                  'मिठाई वाले',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text('MANAGEMENT', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
              ),
              ..._navItems.map(
                (item) => NavigationDrawerDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ),
              ),
              const Divider(indent: 28, endIndent: 28),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                leading: const Icon(Icons.logout_outlined),
                title: const Text('Sign out'),
                onTap: () => AppNav.push(AppRoutes.confirmLogout),
              ),
            ],
          ),
          const VerticalDivider(width: 1),

          // Main Content Body
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Profile Settings',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: state.isSaving
                            ? null
                            : () async {
                                await vm.saveProfile();
                              },
                        icon: state.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),

                // Main Form Body
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Profile Banner Card
                                  Card(
                                    elevation: 0,
                                    color: cs.primaryContainer.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: cs.outlineVariant),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 36,
                                            backgroundColor: cs.primary,
                                            child: Text(
                                              state.name.isNotEmpty ? state.name[0].toUpperCase() : 'U',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: cs.onPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  state.name,
                                                  style: theme.textTheme.headlineSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  state.shopName,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Personal Information Section
                                  Text(
                                    'Personal Details',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: cs.outlineVariant),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        children: [
                                          // 1. Name
                                          TextFormField(
                                            controller: _nameCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Full Name',
                                              prefixIcon: Icon(Icons.person_outlined),
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: vm.updateName,
                                          ),
                                          const SizedBox(height: 20),
                                          // 2. Password (pwd)
                                          TextFormField(
                                            controller: _pwdCtrl,
                                            obscureText: !state.isPasswordVisible,
                                            decoration: InputDecoration(
                                              labelText: 'Password',
                                              prefixIcon: const Icon(Icons.lock_outlined),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  state.isPasswordVisible
                                                      ? Icons.visibility_off_outlined
                                                      : Icons.visibility_outlined,
                                                ),
                                                onPressed: vm.togglePasswordVisibility,
                                              ),
                                              border: const OutlineInputBorder(),
                                            ),
                                            onChanged: vm.updatePassword,
                                          ),
                                          const SizedBox(height: 20),
                                          // 3. Phone
                                          TextFormField(
                                            controller: _phoneCtrl,
                                            keyboardType: TextInputType.phone,
                                            decoration: const InputDecoration(
                                              labelText: 'Phone Number',
                                              prefixIcon: Icon(Icons.phone_outlined),
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: vm.updatePhone,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Shop Details Section
                                  Text(
                                    'Shop Details',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: cs.outlineVariant),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        children: [
                                          // 4. Shop Name
                                          TextFormField(
                                            controller: _shopNameCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Shop Name',
                                              prefixIcon: Icon(Icons.store_outlined),
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: vm.updateShopName,
                                          ),
                                          const SizedBox(height: 20),
                                          // 5. Shop Address
                                          TextFormField(
                                            controller: _shopAddressCtrl,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              labelText: 'Shop Address',
                                              prefixIcon: Icon(Icons.location_on_outlined),
                                              border: OutlineInputBorder(),
                                              alignLabelWithHint: true,
                                            ),
                                            onChanged: vm.updateShopAddress,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: FilledButton.icon(
                                      onPressed: state.isSaving
                                          ? null
                                          : () async {
                                              await vm.saveProfile();
                                            },
                                      icon: state.isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save),
                                      label: const Text('Save Profile Settings', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
