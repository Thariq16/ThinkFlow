import 'package:flutter/material.dart';

/// Responsive layout wrapper — constrains content width on desktop while
/// staying full-width on mobile. All screens should wrap their body with this.
///
/// Breakpoints:
///   - Mobile:  < 600px  → full width, smaller padding
///   - Tablet:  600-1024px → max 600px centered, medium padding
///   - Desktop: > 1024px → max 720px centered, generous padding
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double mobileMaxWidth;
  final double tabletMaxWidth;
  final double desktopMaxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.mobileMaxWidth = double.infinity,
    this.tabletMaxWidth = 600,
    this.desktopMaxWidth = 720,
  });

  /// Check if current screen is mobile-sized
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Check if current screen is tablet-sized
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 1024;
  }

  /// Check if current screen is desktop-sized
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth;
        if (constraints.maxWidth < 600) {
          maxWidth = mobileMaxWidth;
        } else if (constraints.maxWidth < 1024) {
          maxWidth = tabletMaxWidth;
        } else {
          maxWidth = desktopMaxWidth;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
