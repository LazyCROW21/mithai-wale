import 'package:flutter/foundation.dart';

/// Immutable state for Profile screen.
@immutable
class ProfileState {
  const ProfileState({
    this.name = '',
    this.password = '',
    this.phone = '',
    this.shopName = '',
    this.shopAddress = '',
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.isSaving = false,
    this.saveSuccess = false,
    this.errorMessage,
  });

  final String name;
  final String password;
  final String phone;
  final String shopName;
  final String shopAddress;
  final bool isPasswordVisible;
  final bool isLoading;
  final bool isSaving;
  final bool saveSuccess;
  final String? errorMessage;

  ProfileState copyWith({
    String? name,
    String? password,
    String? phone,
    String? shopName,
    String? shopAddress,
    bool? isPasswordVisible,
    bool? isLoading,
    bool? isSaving,
    bool? saveSuccess,
    String? Function()? errorMessage,
  }) {
    return ProfileState(
      name: name ?? this.name,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileState &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          password == other.password &&
          phone == other.phone &&
          shopName == other.shopName &&
          shopAddress == other.shopAddress &&
          isPasswordVisible == other.isPasswordVisible &&
          isLoading == other.isLoading &&
          isSaving == other.isSaving &&
          saveSuccess == other.saveSuccess &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      name.hashCode ^
      password.hashCode ^
      phone.hashCode ^
      shopName.hashCode ^
      shopAddress.hashCode ^
      isPasswordVisible.hashCode ^
      isLoading.hashCode ^
      isSaving.hashCode ^
      saveSuccess.hashCode ^
      errorMessage.hashCode;
}
