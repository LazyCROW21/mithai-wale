import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

export 'breakpoints.dart';

/// A widget that renders one of three layout variants based on the available
/// screen width, using [AppBreakpoints] to determine the active tier.
///
/// ### Usage
/// ```dart
/// ResponsiveLayout(
///   mobile:  HomePageMobileView(),
///   tablet:  HomePageTabletView(),
///   desktop: HomePageDesktopView(),
/// )
/// ```
///
/// * [mobile]  — rendered when `width < 600`
/// * [tablet]  — rendered when `600 ≤ width < 1024`
/// * [desktop] — rendered when `width ≥ 1024`
///
/// If [tablet] is omitted the [mobile] widget is used for tablet widths.
/// If [desktop] is omitted the [tablet] (or [mobile]) widget is used.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Widget shown on mobile screens (`width < 600`).
  final Widget mobile;

  /// Widget shown on tablet screens (`600 ≤ width < 1024`).
  /// Falls back to [mobile] when `null`.
  final Widget? tablet;

  /// Widget shown on desktop screens (`width ≥ 1024`).
  /// Falls back to [tablet] (then [mobile]) when `null`.
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = AppBreakpoints.resolve(constraints.maxWidth);
        return switch (deviceType) {
          DeviceType.desktop => desktop ?? tablet ?? mobile,
          DeviceType.tablet => tablet ?? mobile,
          DeviceType.mobile => mobile,
        };
      },
    );
  }
}
