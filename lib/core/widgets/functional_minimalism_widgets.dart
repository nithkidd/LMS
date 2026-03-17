import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TrellisAccent {
  const TrellisAccent({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  TrellisAccent copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    IconData? icon,
  }) {
    return TrellisAccent(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      icon: icon ?? this.icon,
    );
  }
}

class TrellisAccentPalette {
  TrellisAccentPalette._();

  static const List<TrellisAccent> _palette = [
    TrellisAccent(
      backgroundColor: AppColors.primarySoft,
      foregroundColor: AppColors.primary,
      icon: Icons.dashboard_customize_rounded,
    ),
    TrellisAccent(
      backgroundColor: AppColors.highlightSoft,
      foregroundColor: AppColors.warning,
      icon: Icons.folder_copy_rounded,
    ),
    TrellisAccent(
      backgroundColor: Color(0xFFEEF3FD),
      foregroundColor: Color(0xFF3559B8),
      icon: Icons.auto_stories_rounded,
    ),
    TrellisAccent(
      backgroundColor: Color(0xFFFCE8E6),
      foregroundColor: AppColors.danger,
      icon: Icons.draw_rounded,
    ),
    TrellisAccent(
      backgroundColor: AppColors.accentSoft,
      foregroundColor: AppColors.success,
      icon: Icons.eco_rounded,
    ),
    TrellisAccent(
      backgroundColor: AppColors.secondarySoft,
      foregroundColor: AppColors.info,
      icon: Icons.light_mode_rounded,
    ),
  ];

  static TrellisAccent bySeed(
    String seed, {
    int offset = 0,
    required IconData fallbackIcon,
  }) {
    final sum = seed.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return _palette[(sum + offset) % _palette.length].copyWith(
      icon: fallbackIcon,
    );
  }

  static TrellisAccent byIndex(int index, {required IconData icon}) {
    return _palette[index % _palette.length].copyWith(icon: icon);
  }

  static TrellisAccent primary({required IconData icon}) {
    return _palette.first.copyWith(icon: icon);
  }

  static TrellisAccent success({required IconData icon}) {
    return _palette[4].copyWith(icon: icon);
  }

  static TrellisAccent warning({required IconData icon}) {
    return _palette[1].copyWith(icon: icon);
  }

  static TrellisAccent rose({required IconData icon}) {
    return _palette[3].copyWith(icon: icon);
  }

  static TrellisAccent subject(String name, {int index = 0}) {
    final normalized = name.trim().toLowerCase();

    if (normalized.contains('math') || normalized.contains('គណិត')) {
      return _palette[2].copyWith(icon: Icons.calculate_rounded);
    }
    if (normalized.contains('biology') || normalized.contains('ជីវ')) {
      return _palette[4].copyWith(icon: Icons.eco_rounded);
    }
    if (normalized.contains('chem') || normalized.contains('គីមី')) {
      return _palette[3].copyWith(icon: Icons.science_rounded);
    }
    if (normalized.contains('phys') || normalized.contains('រូប')) {
      return _palette[5].copyWith(icon: Icons.rocket_launch_rounded);
    }
    if (normalized.contains('english') ||
        normalized.contains('language') ||
        normalized.contains('អង់គ្លេស') ||
        normalized.contains('ភាសា')) {
      return _palette[0].copyWith(icon: Icons.translate_rounded);
    }
    if (normalized.contains('history') || normalized.contains('ប្រវត្តិ')) {
      return _palette[1].copyWith(icon: Icons.history_edu_rounded);
    }
    if (normalized.contains('geo') || normalized.contains('ភូមិ')) {
      return _palette[5].copyWith(icon: Icons.public_rounded);
    }
    if (normalized.contains('ict') ||
        normalized.contains('computer') ||
        normalized.contains('technology')) {
      return _palette[0].copyWith(icon: Icons.computer_rounded);
    }
    if (normalized.contains('art') || normalized.contains('សិល្បៈ')) {
      return _palette[3].copyWith(icon: Icons.brush_rounded);
    }

    return byIndex(index, icon: Icons.menu_book_rounded);
  }

  static TrellisAccent schoolClass(
    String name, {
    int index = 0,
    bool isAdviser = false,
  }) {
    if (isAdviser) {
      return warning(icon: Icons.workspace_premium_rounded);
    }
    return byIndex(index, icon: Icons.groups_rounded);
  }

  static TrellisAccent person(String name, {String? sex}) {
    final normalizedSex = sex?.trim().toLowerCase();
    if (normalizedSex == 'f') {
      return rose(icon: Icons.person_rounded);
    }
    return success(icon: Icons.person_rounded);
  }
}

class TrellisSectionSurface extends StatelessWidget {
  const TrellisSectionSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.paddingMd),
    this.margin,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppSizes.radiusLg),
    ),
    this.backgroundColor = AppColors.surfaceRaised,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: boxShadow ?? AppShadows.surface,
      ),
      child: child,
    );
  }
}

class TrellisPressableScale extends StatefulWidget {
  const TrellisPressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.985,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<TrellisPressableScale> createState() => _TrellisPressableScaleState();
}

class TrellisAccentIcon extends StatelessWidget {
  const TrellisAccentIcon({
    super.key,
    required this.accent,
    this.size = 52,
    this.iconSize = 24,
    this.padding,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.icon,
  });

  final TrellisAccent accent;
  final double size;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: padding,
      decoration: BoxDecoration(
        color: accent.backgroundColor,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.6)),
      ),
      child: Icon(
        icon ?? accent.icon,
        size: iconSize,
        color: accent.foregroundColor,
      ),
    );
  }
}

class TrellisInfoBadge extends StatelessWidget {
  const TrellisInfoBadge({
    super.key,
    required this.label,
    required this.accent,
    this.icon,
  });

  final String label;
  final TrellisAccent accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.foregroundColor.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? accent.icon, size: 16, color: accent.foregroundColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: accent.foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TrellisAvatar extends StatelessWidget {
  const TrellisAvatar({
    super.key,
    required this.name,
    this.sex,
    this.radius = 24,
  });

  final String name;
  final String? sex;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final accent = TrellisAccentPalette.person(name, sex: sex);
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.characters.first;

    return CircleAvatar(
      radius: radius,
      backgroundColor: accent.backgroundColor,
      child: Text(
        initial.toUpperCase(),
        style: AppTextStyles.body.copyWith(
          color: accent.foregroundColor,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

class TrellisEmptyState extends StatelessWidget {
  const TrellisEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String message;
  final TrellisAccent? accent;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent =
        accent ??
        TrellisAccentPalette.bySeed(
          title,
          fallbackIcon: icon,
        ).copyWith(icon: icon);

    return TrellisSectionSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLg,
        vertical: AppSizes.paddingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TrellisAccentIcon(
            accent: resolvedAccent,
            size: 82,
            iconSize: 36,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.subheading,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TrellisPressableScaleState extends State<TrellisPressableScale> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (_isPressed == isPressed || widget.onTap == null) {
      return;
    }
    setState(() => _isPressed = isPressed);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedScale(
            scale: _isPressed ? widget.pressedScale : 1,
            duration: _isPressed ? AppMotion.quick : AppMotion.standard,
            curve: AppMotion.standardCurve,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class TrellisStaggeredReveal extends StatelessWidget {
  const TrellisStaggeredReveal({
    super.key,
    required this.child,
    required this.index,
    this.verticalOffset = 16,
  });

  final Widget child;
  final int index;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0, 0.4).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.reveal,
      curve: AppMotion.emphasizedCurve,
      builder: (context, value, animatedChild) {
        final reveal = Interval(
          start,
          1,
          curve: AppMotion.emphasizedCurve,
        ).transform(value);
        final y = Tween<double>(
          begin: verticalOffset,
          end: 0,
        ).transform(reveal);
        final scale = Tween<double>(begin: 0.992, end: 1).transform(reveal);
        final opacity = Tween<double>(
          begin: 0.62,
          end: 1,
        ).transform(Curves.easeOut.transform(reveal));

        return Transform.translate(
          offset: Offset(0, y),
          child: Transform.scale(
            scale: scale,
            child: Opacity(opacity: opacity, child: animatedChild),
          ),
        );
      },
      child: child,
    );
  }
}

class TrellisSmoothSwitcher extends StatelessWidget {
  const TrellisSmoothSwitcher({
    super.key,
    required this.child,
    required this.switchKey,
    this.duration = AppMotion.section,
  });

  final Widget child;
  final Object switchKey;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.emphasizedCurve,
      switchOutCurve: AppMotion.standardCurve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        final fade = Tween<double>(
          begin: 0.72,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotion.emphasizedCurve,
                reverseCurve: AppMotion.standardCurve,
              ),
            );
        final scale = Tween<double>(begin: 0.994, end: 1).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasizedCurve,
            reverseCurve: AppMotion.standardCurve,
          ),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(switchKey), child: child),
    );
  }
}

class TrellisSoftIconButton extends StatelessWidget {
  const TrellisSoftIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.surfaceRaised,
        foregroundColor: foregroundColor ?? AppColors.textPrimary,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.all(12),
        side: const BorderSide(color: AppColors.border, width: 1),
        shadowColor: Colors.transparent,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class TrellisCardActions extends StatelessWidget {
  const TrellisCardActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.paddingSm,
      runSpacing: AppSizes.paddingSm,
      alignment: WrapAlignment.start,
      children: children,
    );
  }
}

class TrellisSearchField extends StatelessWidget {
  const TrellisSearchField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.clearLabel,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String clearLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              prefixIcon: const Icon(Icons.search_rounded),
              helperText: ' ',
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingSm),
        TrellisSmoothSwitcher(
          switchKey: hasValue,
          child: hasValue
              ? OutlinedButton.icon(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.clear_rounded),
                  label: Text(clearLabel),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
