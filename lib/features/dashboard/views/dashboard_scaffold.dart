import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../models/dashboard_summary.dart';

class DashboardNavItemData {
  const DashboardNavItemData({
    required this.label,
    required this.icon,
    this.detail,
  });

  final String label;
  final IconData icon;
  final String? detail;
}

class DashboardStatusBadgeData {
  const DashboardStatusBadgeData({
    required this.label,
    required this.accent,
    this.icon,
  });

  final String label;
  final TrellisAccent accent;
  final IconData? icon;
}

class DashboardMetricData {
  const DashboardMetricData({
    required this.label,
    required this.value,
    required this.accent,
    this.detail,
  });

  final String label;
  final String value;
  final TrellisAccent accent;
  final String? detail;
}

class DashboardScaffold extends StatefulWidget {
  const DashboardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.scopeLabel,
    required this.navigationItems,
    required this.statusBadges,
    required this.onRefresh,
    required this.onSignOut,
    required this.sectionBuilder,
  });

  final String title;
  final String subtitle;
  final String scopeLabel;
  final List<DashboardNavItemData> navigationItems;
  final List<DashboardStatusBadgeData> statusBadges;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSignOut;
  final Widget Function(BuildContext context, int section, bool compact)
  sectionBuilder;

  @override
  State<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = AppBreakpoints.isCompact(width);
        final usesRail = AppBreakpoints.usesRail(width);
        final padding = AppBreakpoints.shellPadding(width);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: _section,
                  onDestinationSelected: (value) {
                    setState(() => _section = value);
                  },
                  destinations: [
                    for (final item in widget.navigationItems)
                      NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.icon),
                        label: item.label,
                      ),
                  ],
                )
              : null,
          body: Stack(
            children: [
              const Positioned.fill(child: _DashboardBackdrop()),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (usesRail)
                        _DashboardRail(
                          title: widget.title,
                          items: widget.navigationItems,
                          section: _section,
                          onSelected: (value) =>
                              setState(() => _section = value),
                        ),
                      if (usesRail) const SizedBox(width: AppSizes.paddingLg),
                      Expanded(
                        child: ListView(
                          children: [
                            TrellisStaggeredReveal(
                              index: 0,
                              child: _DashboardMasthead(
                                title: widget.title,
                                subtitle: widget.subtitle,
                                scopeLabel: widget.scopeLabel,
                                statusBadges: widget.statusBadges,
                                onRefresh: widget.onRefresh,
                                onSignOut: widget.onSignOut,
                                compact: compact,
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingLg),
                            TrellisSmoothSwitcher(
                              switchKey: _section,
                              child: TrellisStaggeredReveal(
                                index: 1,
                                verticalOffset: 22,
                                child: widget.sectionBuilder(
                                  context,
                                  _section,
                                  compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DashboardStatusView extends StatelessWidget {
  const DashboardStatusView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: loading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSizes.paddingLg),
                        Text(title, style: AppTextStyles.subheading),
                        const SizedBox(height: AppSizes.paddingSm),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : TrellisEmptyState(
                      icon: icon,
                      title: title,
                      message: message,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subheading),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSizes.paddingMd),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSizes.paddingLg),
          child,
        ],
      ),
    );
  }
}

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({
    super.key,
    required this.metrics,
    this.compact = false,
  });

  final List<DashboardMetricData> metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _resolveMetricColumns(width, compact);
        final itemCount = metrics.length;
        final rows = (itemCount / columns).ceil();
        final cardHeight = compact ? 196.0 : 206.0;
        final gridHeight =
            (rows * cardHeight) + ((rows - 1) * AppSizes.paddingMd);

        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSizes.paddingMd,
              mainAxisSpacing: AppSizes.paddingMd,
              mainAxisExtent: cardHeight,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return _DashboardMetricCard(metric: metrics[index]);
            },
          ),
        );
      },
    );
  }

  int _resolveMetricColumns(double width, bool compact) {
    if (width >= 1180) return 4;
    if (width >= 760) return 3;
    if (width >= 460) return 2;
    return 1;
  }
}

class DashboardAlertList extends StatelessWidget {
  const DashboardAlertList({
    super.key,
    required this.alerts,
    required this.emptyMessage,
  });

  final List<DashboardAlert> alerts;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Text(
        emptyMessage,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < alerts.length; index++) ...[
          _DashboardAlertRow(alert: alerts[index]),
          if (index != alerts.length - 1)
            const SizedBox(height: AppSizes.paddingMd),
        ],
      ],
    );
  }
}

class DashboardActionList extends StatelessWidget {
  const DashboardActionList({
    super.key,
    required this.actions,
    required this.onSelected,
  });

  final List<DashboardActionItem> actions;
  final ValueChanged<DashboardActionItem> onSelected;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          _DashboardActionTile(action: actions[index], onSelected: onSelected),
          if (index != actions.length - 1)
            const SizedBox(height: AppSizes.paddingMd),
        ],
      ],
    );
  }
}

class DashboardRankingList extends StatelessWidget {
  const DashboardRankingList({
    super.key,
    required this.rows,
    required this.emptyMessage,
    this.onSelected,
  });

  final List<DashboardRankingRow> rows;
  final String emptyMessage;
  final ValueChanged<DashboardRankingRow>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        emptyMessage,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }

    final maxScore = rows.fold<int>(
      0,
      (max, row) => row.score > max ? row.score : max,
    );

    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _DashboardRankingTile(
            row: rows[index],
            maxScore: maxScore == 0 ? 1 : maxScore,
            onSelected: onSelected,
          ),
          if (index != rows.length - 1)
            const SizedBox(height: AppSizes.paddingMd),
        ],
      ],
    );
  }
}

class _DashboardRail extends StatelessWidget {
  const _DashboardRail({
    required this.title,
    required this.items,
    required this.section,
    required this.onSelected,
  });

  final String title;
  final List<DashboardNavItemData> items;
  final int section;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      child: TrellisSectionSurface(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        backgroundColor: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 78,
              height: 78,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceRaised, AppColors.primarySoft],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Image.asset(
                'assets/trellis-logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              title,
              style: AppTextStyles.subheading.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text('Role-first operations shell', style: AppTextStyles.caption),
            const SizedBox(height: AppSizes.paddingSm),
            TrellisInfoBadge(
              label: 'Quiet navigation',
              accent: TrellisAccentPalette.primary(
                icon: Icons.motion_photos_on_rounded,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            for (var index = 0; index < items.length; index++) ...[
              _DashboardRailButton(
                item: items[index],
                selected: index == section,
                onPressed: () => onSelected(index),
              ),
              if (index != items.length - 1)
                const SizedBox(height: AppSizes.paddingSm),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardMasthead extends StatelessWidget {
  const _DashboardMasthead({
    required this.title,
    required this.subtitle,
    required this.scopeLabel,
    required this.statusBadges,
    required this.onRefresh,
    required this.onSignOut,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final String scopeLabel;
  final List<DashboardStatusBadgeData> statusBadges;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSignOut;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Operations overview', style: AppTextStyles.caption),
                    const SizedBox(height: AppSizes.paddingSm),
                    Text(
                      title,
                      style: compact
                          ? AppTextStyles.heading
                          : AppTextStyles.display.copyWith(
                              fontSize: 38,
                              height: 1.04,
                            ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Text(
                        subtitle,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: AppSizes.paddingLg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _HeaderActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      primary: true,
                      onPressed: () => onRefresh(),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    _HeaderActionButton(
                      icon: Icons.logout_rounded,
                      label: 'Sign out',
                      onPressed: () => onSignOut(),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Wrap(
            spacing: AppSizes.paddingSm,
            runSpacing: AppSizes.paddingSm,
            children: [
              TrellisInfoBadge(
                label: scopeLabel,
                accent: TrellisAccentPalette.primary(
                  icon: Icons.apartment_rounded,
                ),
              ),
              for (final badge in statusBadges)
                TrellisInfoBadge(
                  label: badge.label,
                  accent: badge.accent,
                  icon: badge.icon,
                ),
            ],
          ),
          if (compact) ...[
            const SizedBox(height: AppSizes.paddingLg),
            Wrap(
              spacing: AppSizes.paddingSm,
              runSpacing: AppSizes.paddingSm,
              children: [
                FilledButton.icon(
                  onPressed: () => onRefresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onSignOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSizes.paddingLg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMd,
                vertical: AppSizes.paddingSm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Built for fast scanning, clean hierarchy, and low-friction daily work.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft.withValues(alpha: 0.65),
              ),
            ),
          ),
          Positioned(
            left: -140,
            bottom: -180,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondarySoft.withValues(alpha: 0.68),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.canvasSoft.withValues(alpha: 0.94),
                    AppColors.canvas.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({required this.metric});

  final DashboardMetricData metric;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrellisAccentIcon(
            accent: metric.accent,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Text(metric.value, style: AppTextStyles.heading),
          const SizedBox(height: 4),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body,
          ),
          const Spacer(),
          if (metric.detail != null)
            Text(
              metric.detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(fontSize: 12.5),
            ),
        ],
      ),
    );
  }
}

class _DashboardRailButton extends StatelessWidget {
  const _DashboardRailButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final DashboardNavItemData item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? TrellisAccentPalette.primary(icon: item.icon)
        : TrellisAccentPalette.byIndex(5, icon: item.icon);

    return TrellisPressableScale(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        decoration: BoxDecoration(
          color: selected ? accent.backgroundColor : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: selected
                ? accent.foregroundColor.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: selected
                  ? accent.foregroundColor
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? accent.foregroundColor
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (item.detail != null)
                    Text(item.detail!, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAlertRow extends StatelessWidget {
  const _DashboardAlertRow({required this.alert});

  final DashboardAlert alert;

  @override
  Widget build(BuildContext context) {
    final accent = switch (alert.severity) {
      DashboardAlertSeverity.info => TrellisAccentPalette.primary(
        icon: Icons.info_outline_rounded,
      ),
      DashboardAlertSeverity.warning => TrellisAccentPalette.warning(
        icon: Icons.warning_amber_rounded,
      ),
      DashboardAlertSeverity.critical => TrellisAccentPalette.rose(
        icon: Icons.priority_high_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: accent.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrellisAccentIcon(
            accent: accent,
            size: 40,
            iconSize: 18,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(alert.message, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (alert.count != null)
            Text(
              '${alert.count}',
              style: AppTextStyles.subheading.copyWith(
                color: accent.foregroundColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardActionTile extends StatelessWidget {
  const _DashboardActionTile({required this.action, required this.onSelected});

  final DashboardActionItem action;
  final ValueChanged<DashboardActionItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return TrellisPressableScale(
      onTap: () => onSelected(action),
      child: TrellisSectionSurface(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        backgroundColor: action.isPrimary
            ? AppColors.primarySoft
            : AppColors.surface,
        child: Row(
          children: [
            TrellisAccentIcon(
              accent: action.isPrimary
                  ? TrellisAccentPalette.primary(icon: Icons.flash_on_rounded)
                  : TrellisAccentPalette.byIndex(
                      2,
                      icon: Icons.checklist_rounded,
                    ),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(action.description, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (action.valueLabel != null) ...[
              const SizedBox(width: AppSizes.paddingMd),
              Text(action.valueLabel!, style: AppTextStyles.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardRankingTile extends StatelessWidget {
  const _DashboardRankingTile({
    required this.row,
    required this.maxScore,
    this.onSelected,
  });

  final DashboardRankingRow row;
  final int maxScore;
  final ValueChanged<DashboardRankingRow>? onSelected;

  @override
  Widget build(BuildContext context) {
    final fill = maxScore == 0
        ? 0.0
        : (row.score / maxScore).clamp(0, 1).toDouble();

    return TrellisPressableScale(
      onTap: onSelected == null ? null : () => onSelected!(row),
      child: TrellisSectionSurface(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        backgroundColor: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMd),
                Text(row.metricLabel, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 6),
            Text(row.detail, style: AppTextStyles.caption),
            const SizedBox(height: AppSizes.paddingMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
