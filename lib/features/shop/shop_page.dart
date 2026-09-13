import 'package:flutter/material.dart';

import '../../core/layout/responsive_layout.dart';
import 'views/shop_desktop_view.dart';
import 'views/shop_mobile_view.dart';
import 'views/shop_tablet_view.dart';

/// Entry point for the Shop feature.
/// Delegates to the appropriate layout view via [ResponsiveLayout].
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: ShopMobileView(),
      tablet: ShopTabletView(),
      desktop: ShopDesktopView(),
    );
  }
}
