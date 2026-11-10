import 'package:flutter/material.dart';

import '../../core/layout/responsive_layout.dart';
import 'views/orders_desktop_view.dart';
import 'views/orders_mobile_view.dart';
import 'views/orders_tablet_view.dart';

/// Entry point for the Orders feature.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: OrdersMobileView(),
      tablet: OrdersTabletView(),
      desktop: OrdersDesktopView(),
    );
  }
}
