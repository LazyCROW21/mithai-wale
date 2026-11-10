/// Responsive breakpoints for mithai_wale.
///
/// Layout tiers (aligns with Material Design 3 adaptive layout guidelines):
/// ┌──────────────┬────────────────────────┐
/// │ Device       │ Width                  │
/// ├──────────────┼────────────────────────┤
/// │ Mobile       │ < 600 dp               │
/// │ Tablet       │ 600 dp – 1024 dp       │
/// │ Desktop      │ ≥ 1024 dp              │
/// └──────────────┴────────────────────────┘
library;

/// Categorises the current screen into one of three layout tiers.
enum DeviceType {
  /// Single-column layout, bottom navigation bar.
  mobile,

  /// Two-pane layout, navigation rail.
  tablet,

  /// Multi-column layout, persistent navigation drawer.
  desktop,
}

/// Breakpoint constants used by [ResponsiveLayout] and layout extensions.
abstract final class AppBreakpoints {
  /// Minimum width (inclusive) for a tablet layout.
  static const double tablet = 600;

  /// Minimum width (inclusive) for a desktop layout.
  static const double desktop = 1024;

  /// Returns the [DeviceType] for the given [width].
  static DeviceType resolve(double width) {
    if (width >= desktop) return DeviceType.desktop;
    if (width >= tablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}
