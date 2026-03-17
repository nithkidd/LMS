enum AppViewport { compact, medium, expanded, large }

class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMax = 767;
  static const double mediumMax = 1099;
  static const double expandedMax = 1439;

  static AppViewport fromWidth(double width) {
    if (width <= compactMax) {
      return AppViewport.compact;
    }
    if (width <= mediumMax) {
      return AppViewport.medium;
    }
    if (width <= expandedMax) {
      return AppViewport.expanded;
    }
    return AppViewport.large;
  }

  static bool isCompact(double width) =>
      fromWidth(width) == AppViewport.compact;

  static bool usesRail(double width) {
    final viewport = fromWidth(width);
    return viewport == AppViewport.medium ||
        viewport == AppViewport.expanded ||
        viewport == AppViewport.large;
  }

  static bool showsAside(double width) {
    final viewport = fromWidth(width);
    return viewport == AppViewport.expanded || viewport == AppViewport.large;
  }

  static int classGridColumns(double width) {
    final viewport = fromWidth(width);
    switch (viewport) {
      case AppViewport.compact:
        return 1;
      case AppViewport.medium:
        return 2;
      case AppViewport.expanded:
        return 2;
      case AppViewport.large:
        return 3;
    }
  }

  static int folderGridColumns(double width) {
    final viewport = fromWidth(width);
    switch (viewport) {
      case AppViewport.compact:
        return 1;
      case AppViewport.medium:
        return 2;
      case AppViewport.expanded:
        return 2;
      case AppViewport.large:
        return 3;
    }
  }

  static double shellPadding(double width) {
    final viewport = fromWidth(width);
    switch (viewport) {
      case AppViewport.compact:
        return 16;
      case AppViewport.medium:
        return 20;
      case AppViewport.expanded:
        return 24;
      case AppViewport.large:
        return 32;
    }
  }
}
