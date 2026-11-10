import 'package:flutter/material.dart';

import '../../core/layout/responsive_layout.dart';
import 'views/menu_desktop_view.dart';
import 'views/menu_mobile_view.dart';
import 'views/menu_tablet_view.dart';

/// Entry point for the Menu Management feature.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MenuMobileView(),
      tablet: MenuTabletView(),
      desktop: MenuDesktopView(),
    );
  }
}
