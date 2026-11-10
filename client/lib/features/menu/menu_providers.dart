import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'menu_state.dart';
import 'menu_viewmodel.dart';

final menuViewModelProvider =
    NotifierProvider<MenuViewModel, MenuState>(MenuViewModel.new);
