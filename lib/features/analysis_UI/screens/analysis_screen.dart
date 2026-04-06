// lib/features/analysis/screens/analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';
import '../components/category_bar_graph.dart';
import '../components/range_toggle.dart';
import '../components/ribbon_row.dart';
import '../components/spending_trend_chart.dart';
import '../components/summary_cards.dart';
import '../components/top_category_card.dart';
import '../providers/analysis_provider.dart';


class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final c = context.appColors;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Range toggle ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RangeToggle(current: state.range),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Loading ────────────────────────────────────────────
        if (state.isLoading)
          SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: c.textDark),
            ),
          )

        // ── Empty state ────────────────────────────────────────
        else if (state.transactions.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 64, color: c.border),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: c.textMuted, fontSize: 15),
                  ),
                ],
              ),
            ),
          )

        // ── Content ────────────────────────────────────────────
        else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SummaryCards(
                  totalDebit: state.totalDebit,
                  totalCredit: state.totalCredit,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TopCategoryCard(
                  category: state.topCategory,
                  amount: state.topCategoryAmount,
                  total: state.totalDebit,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const AppSectionLabel(title: 'Spending Trend'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppGlassCard(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: SpendingTrendChart(spendingByDay: state.spendingByDay),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const AppSectionLabel(title: 'Spending by Category'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppGlassCard(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: CategoryBarGraph(
                    data: state.spendingByCategory,
                    total: state.totalDebit,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const AppSectionLabel(title: 'Category Breakdown'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final sorted = state.spendingByCategory.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    return RibbonRow(
                      index: i,
                      entry: sorted[i],
                      total: state.totalDebit,
                      isLast: i == sorted.length - 1,
                    );
                  },
                  childCount: state.spendingByCategory.length,
                ),
              ),
            ),
          ],
      ],
    );
  }
}