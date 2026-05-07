/// Design system constants for consistent styling
///
/// This file provides const values that can be reused throughout the app
/// for better performance (widget tree optimization) and consistency.
library;

import 'package:flutter/material.dart';

/// Standard border radius values used across the app
///
/// Use these constants instead of `BorderRadius.circular(n)` for better performance
abstract final class AppRadius {
  /// Extra small radius (4dp) - for small elements like chips, pills
  static const BorderRadius xs = BorderRadius.all(Radius.circular(4));

  /// Small radius (8dp) - for buttons, small cards
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));

  /// Medium radius (12dp) - for cards, inputs
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));

  /// Large radius (16dp) - for dialogs, modals
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));

  /// Extra large radius (20dp) - for bottom sheets, large cards
  static const BorderRadius xl = BorderRadius.all(Radius.circular(20));

  /// Full circular radius (24dp) - for rounded buttons, avatars
  static const BorderRadius full = BorderRadius.all(Radius.circular(24));

  /// Bottom sheet radius - top corners only
  static const BorderRadius bottomSheet = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  );

  /// Card bottom radius - bottom corners only
  static const BorderRadius cardBottom = BorderRadius.only(
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );

  /// Header radius - bottom corners only (for app bar style headers)
  static const BorderRadius headerBottom = BorderRadius.only(
    bottomLeft: Radius.circular(30),
    bottomRight: Radius.circular(30),
  );
}

/// Standard spacing values used across the app
abstract final class AppSpacing {
  /// Extra small spacing (4dp)
  static const double xs = 4.0;

  /// Small spacing (8dp)
  static const double sm = 8.0;

  /// Medium spacing (12dp)
  static const double md = 12.0;

  /// Standard spacing (16dp)
  static const double lg = 16.0;

  /// Large spacing (20dp)
  static const double xl = 20.0;

  /// Extra large spacing (24dp)
  static const double xxl = 24.0;

  /// Section spacing (32dp)
  static const double section = 32.0;

  /// Page horizontal padding
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);

  /// Page padding
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  /// Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );

  /// Input padding
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Chip padding
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );
}

/// Standard icon sizes used across the app
abstract final class AppIconSize {
  /// Extra small icon (12dp)
  static const double xs = 12.0;

  /// Small icon (16dp)
  static const double sm = 16.0;

  /// Standard icon (24dp)
  static const double md = 24.0;

  /// Large icon (28dp)
  static const double lg = 28.0;

  /// Extra large icon (32dp)
  static const double xl = 32.0;

  /// Feature icon (48dp)
  static const double feature = 48.0;

  /// Hero icon (64dp)
  static const double hero = 64.0;
}

/// Standard animation durations
abstract final class AppDurations {
  /// Fast animation (150ms)
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard animation (300ms)
  static const Duration standard = Duration(milliseconds: 300);

  /// Slow animation (500ms)
  static const Duration slow = Duration(milliseconds: 500);

  /// Page transition (350ms)
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// Splash delay (2s)
  static const Duration splash = Duration(seconds: 2);

  /// Auto-scroll interval (4s)
  static const Duration autoScroll = Duration(seconds: 4);
}

/// Standard shadow configurations
abstract final class AppShadows {
  /// Subtle shadow for cards
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity black
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Elevated shadow for floating elements
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity black
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
  ];

  /// Bottom shadow for headers
  static const List<BoxShadow> bottom = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}

/// Common text styles that can be const
abstract final class AppTextStyles {
  /// Section title style
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  /// Card title style
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Body text style
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  /// Caption text style
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  /// Button text style
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Large number display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
  );

  /// Medium number display
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
}

/// Common widget configurations
abstract final class AppWidgetConfig {
  /// Standard loading indicator size
  static const double loadingSize = 40.0;

  /// Standard avatar size
  static const double avatarSize = 48.0;

  /// Small avatar size
  static const double avatarSizeSmall = 32.0;

  /// Large avatar size
  static const double avatarSizeLarge = 64.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 56.0;

  /// FAB size
  static const double fabSize = 56.0;

  /// Input field height
  static const double inputHeight = 48.0;

  /// Button height
  static const double buttonHeight = 48.0;

  /// Card min height
  static const double cardMinHeight = 100.0;
}
