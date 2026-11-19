import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../core/database/repositories/settings_repository.dart';
import 'profile_state.dart';

/// ViewModel managing state and persistence for the Profile screen.
class ProfileViewModel extends Notifier<ProfileState> {
  late final ISettingsRepository _settingsRepo = sl<ISettingsRepository>();

  @override
  ProfileState build() {
    _loadProfileSettings();
    return const ProfileState(isLoading: true);
  }

  Future<void> _loadProfileSettings() async {
    try {
      final name = await _settingsRepo.get('profile_name') ?? '';
      final password = await _settingsRepo.get('profile_password') ?? '';
      final phone = await _settingsRepo.get('profile_phone') ?? '';
      final shopName = await _settingsRepo.get('profile_shop_name') ?? '';
      final shopAddress = await _settingsRepo.get('profile_shop_address') ?? '';

      state = state.copyWith(
        name: name,
        password: password,
        phone: phone,
        shopName: shopName,
        shopAddress: shopAddress,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to load profile: $e',
      );
    }
  }

  void updateName(String value) {
    state = state.copyWith(name: value, saveSuccess: false);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, saveSuccess: false);
  }

  void updatePhone(String value) {
    state = state.copyWith(phone: value, saveSuccess: false);
  }

  void updateShopName(String value) {
    state = state.copyWith(shopName: value, saveSuccess: false);
  }

  void updateShopAddress(String value) {
    state = state.copyWith(shopAddress: value, saveSuccess: false);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<bool> saveProfile() async {
    if (state.name.trim().isEmpty ||
        state.phone.trim().isEmpty ||
        state.shopName.trim().isEmpty ||
        state.shopAddress.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: () => 'Please fill in all required fields.',
        saveSuccess: false,
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: () => null, saveSuccess: false);

    try {
      await _settingsRepo.set('profile_name', state.name.trim());
      await _settingsRepo.set('profile_password', state.password);
      await _settingsRepo.set('profile_phone', state.phone.trim());
      await _settingsRepo.set('profile_shop_name', state.shopName.trim());
      await _settingsRepo.set('profile_shop_address', state.shopAddress.trim());

      state = state.copyWith(
        isSaving: false,
        saveSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        saveSuccess: false,
        errorMessage: () => 'Failed to save profile: $e',
      );
      return false;
    }
  }
}
