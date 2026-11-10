import 'package:flutter/material.dart';

import '../../core/layout/responsive_layout.dart';
import 'views/ledger_desktop_view.dart';
import 'views/ledger_mobile_view.dart';
import 'views/ledger_tablet_view.dart';

/// Payment Ledger page orchestrator.
class LedgerPage extends StatelessWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: LedgerMobileView(),
      tablet: LedgerTabletView(),
      desktop: LedgerDesktopView(),
    );
  }
}
