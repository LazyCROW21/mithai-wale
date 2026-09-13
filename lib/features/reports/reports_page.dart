import 'package:flutter/material.dart';

import '../../core/layout/responsive_layout.dart';
import 'views/reports_desktop_view.dart';
import 'views/reports_mobile_view.dart';
import 'views/reports_tablet_view.dart';

/// Entry point for the Reports feature.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: ReportsMobileView(),
      tablet: ReportsTabletView(),
      desktop: ReportsDesktopView(),
    );
  }
}
