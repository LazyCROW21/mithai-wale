import 'package:flutter/material.dart';

import '../../core/layout/responsive_layout.dart';
import 'views/settings_desktop_view.dart';
import 'views/settings_mobile_view.dart';
import 'views/settings_tablet_view.dart';

/// Entry point for the Settings feature.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: SettingsMobileView(),
      tablet: SettingsTabletView(),
      desktop: SettingsDesktopView(),
    );
  }
}
