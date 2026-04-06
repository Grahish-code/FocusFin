//total Spent + Received row
// lib/features/analysis/widgets/summary_cards.dart

import 'package:flutter/material.dart';

import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';

class SummaryCards extends StatelessWidget {
  final double totalDebit;
  final double totalCredit;

  const SummaryCards({
    super.key,
    required this.totalDebit,
    required this.totalCredit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppGlassCard(
            child: _SummaryContent(
              label: 'Total Spent',
              value: '₹${totalDebit.toStringAsFixed(0)}',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.rose,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppGlassCard(
            child: _SummaryContent(
              label: 'Received',
              value: '₹${totalCredit.toStringAsFixed(0)}',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.emerald,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryContent({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppCircleIcon(
        icon: icon,
        color: color,
        size: 16,
        padding: 8,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(AppRadius.xs + 2),
      ),
      const SizedBox(height: 12),
      Text(value, style: AppTextStyles.amountMedium.copyWith(color: context.appColors.textDark)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption.copyWith(color: context.appColors.textMuted)),
    ],
  );
}