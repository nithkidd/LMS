import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/grade_calculation_service.dart';

class AdvisorRankingPrintView extends StatelessWidget {
  final AdvisorRankingPrintData data;
  final String title;
  final String subtitle;

  const AdvisorRankingPrintView({
    super.key,
    required this.data,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (data.rows.isEmpty) {
      return const Center(child: Text('មិនមានសិស្សក្នុងថ្នាក់នេះទេ។'));
    }

    final splitIndex = (data.rows.length + 1) ~/ 2;
    final leftRows = data.rows.take(splitIndex).toList(growable: false);
    final rightRows = data.rows.skip(splitIndex).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth < 1240
            ? 1240.0
            : constraints.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: SizedBox(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSizes.paddingMd),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RankingTableCard(
                        title: 'ជួរឈរខាងឆ្វេង',
                        rows: leftRows,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMd),
                    Expanded(
                      child: _RankingTableCard(
                        title: 'ជួរឈរខាងស្តាំ',
                        rows: rightRows,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surfaceRaised, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading.copyWith(fontSize: 22)),
          const SizedBox(height: AppSizes.paddingXs),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingTableCard extends StatelessWidget {
  final String title;
  final List<AdvisorRankingPrintRow> rows;

  const _RankingTableCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMd,
                vertical: AppSizes.paddingSm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Text(
                title,
                style: AppTextStyles.subheading.copyWith(
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 920
                    ? 920.0
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(78),
                        1: FlexColumnWidth(3.35),
                        2: FlexColumnWidth(1.25),
                        3: FlexColumnWidth(1.25),
                        4: FlexColumnWidth(1.2),
                        5: FlexColumnWidth(1.25),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder(
                        horizontalInside: const BorderSide(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                        verticalInside: const BorderSide(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      children: [
                        _buildHeaderRow(),
                        ...rows.asMap().entries.map(
                          (entry) => _buildDataRow(entry.key, entry.value),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return const TableRow(
      decoration: BoxDecoration(color: AppColors.surfaceMuted),
      children: [
        _TableCellPadding(child: _HeaderText('ល.រ')),
        _TableCellPadding(child: _HeaderText('គោត្តនាម និងនាម')),
        _TableCellPadding(child: _HeaderText('សរុប')),
        _TableCellPadding(child: _HeaderText('ម-ភាគ')),
        _TableCellPadding(child: _HeaderText('និទ្ទេស')),
        _TableCellPadding(child: _HeaderText('លទ្ធផល')),
      ],
    );
  }

  TableRow _buildDataRow(int index, AdvisorRankingPrintRow row) {
    final isFail = row.resultStatus == 'ធ្លាក់';
    final resultColor = isFail ? Colors.red : Colors.blue;

    return TableRow(
      decoration: BoxDecoration(color: _rowColor(index)),
      children: [
        _TableCellPadding(
          child: Text(
            row.rank.toString(),
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        _TableCellPadding(
          child: Text(
            row.fullName,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _TableCellPadding(
          child: Text(
            row.totalScore.toStringAsFixed(1),
            style: AppTextStyles.body,
          ),
        ),
        _TableCellPadding(
          child: Text(
            row.averageScore.toStringAsFixed(2),
            style: AppTextStyles.body,
          ),
        ),
        _TableCellPadding(child: Text(row.mention, style: AppTextStyles.body)),
        _TableCellPadding(
          child: Text(
            row.resultStatus,
            style: AppTextStyles.body.copyWith(
              color: resultColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Color _rowColor(int index) {
    return index.isEven
        ? AppColors.surfaceRaised
        : AppColors.canvasSoft.withValues(alpha: 0.72);
  }
}

class _HeaderText extends StatelessWidget {
  final String label;

  const _HeaderText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TableCellPadding extends StatelessWidget {
  final Widget child;

  const _TableCellPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: 16,
      ),
      child: child,
    );
  }
}
