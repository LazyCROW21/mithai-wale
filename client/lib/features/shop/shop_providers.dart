import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shop_state.dart';
import 'shop_viewmodel.dart';

final shopViewModelProvider =
    NotifierProvider<ShopViewModel, ShopState>(ShopViewModel.new);
