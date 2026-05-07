import 'package:flutter/material.dart';

/// Helper pour le design responsive
///
/// Fournit des utilitaires pour adapter l'UI à différentes tailles d'écran
class ResponsiveHelper {
  /// Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Détermine si l'écran est un mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Détermine si l'écran est une tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Détermine si l'écran est un desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Retourne le nombre de colonnes pour une grille responsive
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  /// Retourne le padding horizontal adaptatif
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  /// Retourne une valeur responsive
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

/// Widget qui construit différemment selon la taille d'écran
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints) mobile;
  final Widget Function(BuildContext, BoxConstraints)? tablet;
  final Widget Function(BuildContext, BoxConstraints)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveHelper.desktopBreakpoint) {
          return (desktop ?? tablet ?? mobile)(context, constraints);
        }
        if (constraints.maxWidth >= ResponsiveHelper.mobileBreakpoint) {
          return (tablet ?? mobile)(context, constraints);
        }
        return mobile(context, constraints);
      },
    );
  }
}

/// Widget qui adapte ses enfants en Row ou Column selon l'orientation
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;

  /// Si true, utilise toujours Column sur mobile
  final bool forceColumnOnMobile;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = 8.0,
    this.forceColumnOnMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final useColumn =
            forceColumnOnMobile &&
            ResponsiveHelper.isMobile(context) &&
            orientation == Orientation.portrait;

        final spacer = SizedBox(
          width: useColumn ? 0 : spacing,
          height: useColumn ? spacing : 0,
        );

        final spacedChildren = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          spacedChildren.add(children[i]);
          if (i < children.length - 1) {
            spacedChildren.add(spacer);
          }
        }

        if (useColumn) {
          return Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: spacedChildren,
          );
        }

        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: spacedChildren,
        );
      },
    );
  }
}

/// Extension pour faciliter l'utilisation du responsive
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);

  int get gridColumns => ResponsiveHelper.getGridColumns(this);
  double get horizontalPadding => ResponsiveHelper.getHorizontalPadding(this);

  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    return ResponsiveHelper.value(
      context: this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Grille responsive automatique
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = columns ?? context.gridColumns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (spacing * (columnCount - 1))) /
            columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}
