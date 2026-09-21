import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routing/router_key.dart';
import '../../../core/routing/routes.dart';
import '../profile_providers.dart';

class ProfileMobileView extends ConsumerStatefulWidget {
  const ProfileMobileView({super.key});

  @override
  ConsumerState<ProfileMobileView> createState() => _ProfileMobileViewState();
}

class _ProfileMobileViewState extends ConsumerState<ProfileMobileView> {
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
            content: Text('Profile updated!'),
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
      appBar: AppBar(
        title: const Text('Profile Settings'),
        actions: [
          IconButton(
            icon: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: state.isSaving
                ? null
                : () async {
                    await vm.saveProfile();
                  },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
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
                  const SizedBox(height: 12),
                  Text(
                    state.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    state.shopName,
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields (Only Name, Password, Phone, Shop Name, Shop Address)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Details',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 1. Name
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: vm.updateName,
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          // 3. Phone
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: vm.updatePhone,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Shop Details',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 16),
                          // 5. Shop Address
                          TextFormField(
                            controller: _shopAddressCtrl,
                            maxLines: 2,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: state.isSaving
                          ? null
                          : () async {
                              await vm.saveProfile();
                            },
                      child: state.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4,
        onDestinationSelected: (i) => AppNav.go(_navItems[i].route),
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
