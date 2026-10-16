import 'package:material_ui/material_ui.dart';

/// Standardized spacing and padding constants for the app.
class AppSpacing {
  // Base spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // Common padding values
  static const EdgeInsets screenPadding = EdgeInsets.all(xs);
  static const EdgeInsets screenPaddingNoBottom = EdgeInsets.all(xs);
  static const EdgeInsets cardPadding = EdgeInsets.all(xs);
  static const EdgeInsets sectionPadding = EdgeInsets.all(xs);

  // Gaps for Column and Row
  static const SizedBox fieldGap = SizedBox(height: sm);
  static const SizedBox rowGap = SizedBox(width: sm);
  static const SizedBox smallGap = SizedBox(height: sm);
  static const SizedBox mediumGap = SizedBox(height: md);
  static const SizedBox largeGap = SizedBox(height: lg);

  // Border radius values
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
}
