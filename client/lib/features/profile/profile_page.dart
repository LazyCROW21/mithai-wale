import 'package:flutter/material.dart';

import '../../core/layout/responsive_layout.dart';
import 'views/profile_desktop_view.dart';
import 'views/profile_mobile_view.dart';
import 'views/profile_tablet_view.dart';

/// Entry point for the Profile feature.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: ProfileMobileView(),
      tablet: ProfileTabletView(),
      desktop: ProfileDesktopView(),
    );
  }
}
