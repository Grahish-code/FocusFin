// lib/features/budget/widgets/budget_hero_card.dart

import 'package:flutter/material.dart';

import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';

class BudgetHeroCard extends StatelessWidget {
  final double totalLimit;
  final double totalSpent;
  final int overCount;
  final int setCount;

  const BudgetHeroCard({
    super.key,
    required this.totalLimit,
    required this.totalSpent,
    required this.overCount,
    required this.setCount,
  });

  @override
  Widget build(BuildContext context) {
    final c         = context.appColors;
    final isDark    = c.isDark;
    final pct       = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final remaining = totalLimit - totalSpent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: isDark
            ? const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : const LinearGradient(
          colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: isDark ? AppShadows.primaryGlow : AppShadows.elevatedLight,
      ),
      child: Stack(
        children: [
          // ── Top shimmer line (mirrors balance card) ──────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: AppGradients.glassShimmer,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Label ──────────────────────────────────────
                Text(
                  'TOTAL MONTHLY BUDGET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Amount spent ───────────────────────────────
                Text(
                  '₹${totalSpent.toStringAsFixed(0)}',
                  style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'spent of ₹${totalLimit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Progress track ─────────────────────────────
                AppGlassTrack(
                  percent: pct,
                  color: Colors.white,
                  notchBg: Colors.white.withOpacity(0.15),
                ),
                const SizedBox(height: 20),

                // ── Stats row ──────────────────────────────────
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _Stat(value: '₹${remaining.toStringAsFixed(0)}', label: 'Remaining'),
                      _divider(),
                      _Stat(value: '$setCount', label: 'Categories'),
                      _divider(),
                      _Stat(
                        value: '$overCount',
                        label: 'Overbudget',
                        valueColor: overCount > 0 ? AppColors.rose : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: Colors.white.withOpacity(0.2),
  );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _Stat({
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}