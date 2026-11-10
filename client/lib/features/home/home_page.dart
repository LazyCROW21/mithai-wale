import 'package:flutter/material.dart';

import '../../core/layout/responsive_layout.dart';
import 'views/home_desktop_view.dart';
import 'views/home_mobile_view.dart';
import 'views/home_tablet_view.dart';

/// Entry point for the Home feature.
///
/// Delegates rendering to the appropriate layout view via [ResponsiveLayout]:
/// - Mobile  (`< 600 dp`)  → [HomeMobileView]
/// - Tablet  (`600–1024 dp`) → [HomeTabletView]
/// - Desktop (`≥ 1024 dp`) → [HomeDesktopView]
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: HomeMobileView(),
      tablet: HomeTabletView(),
      desktop: HomeDesktopView(),
    );
  }
}
