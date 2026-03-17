import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color canvas = Color(0xFFF5F8FE);
  static const Color canvasSoft = Color(0xFFF9FBFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFFCFDFF);
  static const Color surfaceMuted = Color(0xFFF1F4FA);
  static const Color primary = Color(0xFF1A73E8);
  static const Color primarySoft = Color(0xFFE8F0FE);
  static const Color secondary = Color(0xFF8AB4F8);
  static const Color secondarySoft = Color(0xFFEAF2FF);
  static const Color accent = Color(0xFF0F9D58);
  static const Color accentSoft = Color(0xFFE6F4EA);
  static const Color highlight = Color(0xFFF9AB00);
  static const Color highlightSoft = Color(0xFFFEF7E0);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color border = Color(0xFFD7DFEB);
  static const Color borderStrong = Color(0xFFB8C6DD);
  static const Color shadow = Color(0x1A3C4043);
  static const Color success = Color(0xFF188038);
  static const Color warning = Color(0xFFB06000);
  static const Color danger = Color(0xFFC5221F);
  static const Color info = Color(0xFF1967D2);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}

class AppTextStyles {
  AppTextStyles._();

  static const double khmerHeight = 1.4;

  static const TextStyle display = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.08,
    color: AppColors.textPrimary,
    letterSpacing: -0.7,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.16,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: khmerHeight,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: khmerHeight,
    color: AppColors.textPrimary,
    letterSpacing: 0.05,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: khmerHeight,
    color: AppColors.textSecondary,
    letterSpacing: 0.08,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Kantumruy Pro',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.1,
  );
}

class AppSizes {
  AppSizes._();

  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusXl = 36;

  static const double paddingXs = 6;
  static const double paddingSm = 10;
  static const double paddingMd = 18;
  static const double paddingLg = 24;
  static const double paddingXl = 32;
  static const double paddingXxl = 40;

  static const double minimumTouchTarget = 52;
}

class AppMotion {
  AppMotion._();

  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration section = Duration(milliseconds: 420);
  static const Duration reveal = Duration(milliseconds: 760);

  static const Curve standardCurve = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve emphasizedCurve = Cubic(0.16, 1, 0.3, 1);
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get surface => const [
    BoxShadow(color: AppColors.shadow, blurRadius: 32, offset: Offset(0, 16)),
    BoxShadow(color: Color(0x0F3C4043), blurRadius: 10, offset: Offset(0, 4)),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.accent,
          onPrimary: AppColors.white,
          onSecondary: AppColors.textPrimary,
          onTertiary: AppColors.white,
          error: AppColors.danger,
          onError: AppColors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          outline: AppColors.borderStrong,
        );

    final baseTextTheme = const TextTheme(
      displaySmall: AppTextStyles.display,
      headlineMedium: AppTextStyles.heading,
      titleLarge: AppTextStyles.subheading,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.button,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      borderSide: const BorderSide(color: AppColors.border, width: 1.2),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Kantumruy Pro',
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: colorScheme,
      textTheme: baseTextTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x663C86F7),
        selectionHandleColor: AppColors.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Kantumruy Pro',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.1,
          letterSpacing: -0.25,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        helperStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.danger),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: 18,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, AppSizes.minimumTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLg,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: AppTextStyles.button,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, AppSizes.minimumTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLg,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(0, AppSizes.minimumTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLg,
            vertical: 18,
          ),
          side: const BorderSide(color: AppColors.borderStrong, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, AppSizes.minimumTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        selectedColor: AppColors.primarySoft,
        disabledColor: AppColors.surfaceMuted,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        height: 76,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary;
          return AppTextStyles.caption.copyWith(color: color);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary;
          return IconThemeData(color: color);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
        selectedLabelTextStyle: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
        ),
        unselectedLabelTextStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        indicatorColor: AppColors.primarySoft,
        useIndicator: true,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingXs,
        ),
        minVerticalPadding: AppSizes.paddingXs,
        iconColor: AppColors.textSecondary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        extendedTextStyle: AppTextStyles.button.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(44, 44),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.secondarySoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
      ),
    );
  }
}
