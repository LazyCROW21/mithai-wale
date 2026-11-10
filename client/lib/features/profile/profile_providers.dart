import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_state.dart';
import 'profile_viewmodel.dart';

/// Riverpod provider for [ProfileViewModel].
final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
