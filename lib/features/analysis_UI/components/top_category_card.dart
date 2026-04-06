//Highest spend card

// lib/features/analysis/widgets/top_category_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/transaction_categories.dart';
import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';

class TopCategoryCard extends StatelessWidget {
  final String category;
  final double amount;
  final double total;

  const TopCategoryCard({
    super.key,
    required this.category,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final cat = kTransactionCategories
        .where((x) => x.label == category)
        .firstOrNull;
    final color = cat?.color ?? c.textMuted;
    final icon  = cat?.icon  ?? Icons.category_rounded;
    final pct   = total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0';

    return AppGlassCard(
      child: Row(
        children: [
          AppCircleIcon(
            icon: icon,
            color: color,
            size: 22,
            padding: 12,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highest spend',
                  style: TextStyle(
                    fontSize: 10,
                    color: c.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.isEmpty ? '—' : category,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                '$pct% of total',
                style: AppTextStyles.caption.copyWith(color: c.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}