import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Convenience extensions on [BuildContext] for responsive layout queries.
///
/// ### Example
/// ```dart
/// if (context.isMobile) {
///   return const MobileNav();
/// }
/// ```
extension LayoutExtensions on BuildContext {
  /// The current screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// The current screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Resolves the [DeviceType] based on the current screen width.
  DeviceType get deviceType => AppBreakpoints.resolve(screenWidth);

  /// `true` when the current layout tier is [DeviceType.mobile].
  bool get isMobile => deviceType == DeviceType.mobile;

  /// `true` when the current layout tier is [DeviceType.tablet].
  bool get isTablet => deviceType == DeviceType.tablet;

  /// `true` when the current layout tier is [DeviceType.desktop].
  bool get isDesktop => deviceType == DeviceType.desktop;
}
