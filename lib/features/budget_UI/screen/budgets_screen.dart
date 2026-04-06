// lib/features/budget/screens/budgets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/transaction_categories.dart';
import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';
import '../components/budget_hero_card.dart';
import '../provider/budget_provider.dart';


// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(budgetProvider);
    final c        = context.appColors;

    double totalLimit = 0, totalSpent = 0;
    for (final e in state.categoryLimits.entries) {
      totalLimit += e.value;
      totalSpent += state.categorySpent[e.key] ?? 0;
    }

    final items = kTransactionCategories.map((cat) {
      final limit = state.categoryLimits[cat.label];
      final spent = state.categorySpent[cat.label] ?? 0.0;
      final pct   = (limit != null && limit > 0) ? spent / limit : 0.0;
      return {'cat': cat, 'limit': limit, 'spent': spent, 'pct': pct, 'isSet': limit != null};
    }).toList()
      ..sort((a, b) {
        if (a['isSet'] != b['isSet']) return a['isSet'] == true ? -1 : 1;
        if (a['isSet'] == false) return 0;
        return (b['pct'] as double).compareTo(a['pct'] as double);
      });

    final overItems = items.where((i) => i['isSet'] == true && (i['pct'] as double) >= 1.0).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: state.isLoading
            ? Center(child: CircularProgressIndicator(color: c.textDark))
            : ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 20, bottom: 40),
          children: [
            // ── Hero card ──────────────────────────────────────
            if (state.categoryLimits.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BudgetHeroCard(
                  totalLimit: totalLimit,
                  totalSpent: totalSpent,
                  overCount: overItems.length,
                  setCount: state.categoryLimits.length,
                ),
              ),
              const SizedBox(height: 16),

              // Alert / safe strip
              if (overItems.isNotEmpty)
                _AlertStrip(items: overItems)
              else
                const _SafeStrip(),
              const SizedBox(height: 20),
            ],

            // ── Section: active ────────────────────────────────
            const AppSectionLabel(
              title: 'Active Budgets',
              padding: EdgeInsets.fromLTRB(22, 4, 22, 12),
            ),

            ...items.where((i) => i['isSet'] == true).map((i) => _BudgetCard(
              cat:   i['cat'] as TransactionCategory,
              limit: i['limit'] as double,
              spent: i['spent'] as double,
            )),

            const SizedBox(height: 8),

            // ── Section: unset ─────────────────────────────────
            if (items.any((i) => i['isSet'] == false)) ...[
              const AppSectionLabel(
                title: 'No Limit Set',
                padding: EdgeInsets.fromLTRB(22, 4, 22, 12),
              ),
              ...items.where((i) => i['isSet'] == false).map((i) {
                final cat = i['cat'] as TransactionCategory;
                return _UnsetCard(
                    cat: cat,
                    onTap: () => _showSheet(context, ref, cat));
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref, TransactionCategory cat) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetSheet(cat: cat, ctrl: ctrl, ref: ref),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ALERT / SAFE STRIP
// ═══════════════════════════════════════════════════════════════
class _AlertStrip extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _AlertStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final firstCat = items.first['cat'] as TransactionCategory;
    final names = items.map((i) => (i['cat'] as TransactionCategory).label).join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: c.rose.withOpacity(c.isDark ? 0.08 : 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.rose.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          AppCircleIcon(
            icon: firstCat.icon,
            color: c.rose,
            size: 18,
            padding: 8,
            opacity: 0.15,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${items.length} ${items.length == 1 ? 'category' : 'categories'} over limit',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: c.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  names,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: c.rose),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeStrip extends StatelessWidget {
  const _SafeStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: c.emerald.withOpacity(c.isDark ? 0.08 : 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.emerald.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          AppCircleIcon(
            icon: Icons.check_circle_rounded,
            color: c.emerald,
            size: 18,
            padding: 8,
            opacity: 0.15,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're within all limits",
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: c.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  "Great job this month!",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.emerald.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BUDGET CARD
// ═══════════════════════════════════════════════════════════════
class _BudgetCard extends StatelessWidget {
  final TransactionCategory cat;
  final double limit, spent;

  const _BudgetCard({required this.cat, required this.limit, required this.spent});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final pct       = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOver    = spent >= limit;
    final isWarn    = !isOver && pct >= 0.9;
    final remaining = limit - spent;

    final Color barColor;
    final Color remainColor;

    if (isOver) {
      barColor = remainColor = c.rose;
    } else if (isWarn || pct >= 0.6) {
      barColor = remainColor = c.amber;
    } else {
      barColor = remainColor = c.emerald;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                AppCircleIcon(
                  icon: cat.icon,
                  color: cat.color,
                  size: 20,
                  padding: 10,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(14),
                  opacity: 0.15,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.label,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.textDark)),
                      const SizedBox(height: 2),
                      Text(
                        isOver
                            ? 'Over by ₹${(spent - limit).toStringAsFixed(0)}'
                            : '₹${remaining.toStringAsFixed(0)} left',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: remainColor),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${spent.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isOver ? c.rose : c.textDark)),
                    const SizedBox(height: 2),
                    Text('of ₹${limit.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppGlassTrack(percent: pct, color: barColor, notchBg: c.glassFill),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  UNSET CARD
// ═══════════════════════════════════════════════════════════════
class _UnsetCard extends StatelessWidget {
  final TransactionCategory cat;
  final VoidCallback onTap;
  const _UnsetCard({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: onTap,
        child: AppGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(cat.icon, color: c.textMuted.withOpacity(0.5), size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Set limit for ${cat.label}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('+ ADD',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: c.textDark,
                        letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════
class _BudgetSheet extends ConsumerStatefulWidget {
  final TransactionCategory cat;
  final TextEditingController ctrl;
  final WidgetRef ref;
  const _BudgetSheet({required this.cat, required this.ctrl, required this.ref});

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  void _setQuick(double v) => widget.ctrl.text = v.toStringAsFixed(0);

  Future<void> _save() async {
    final amount = double.tryParse(widget.ctrl.text);
    if (amount == null || amount <= 0) return;
    await widget.ref.read(budgetProvider.notifier).saveBudgetLimit(widget.cat.label, amount);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final kb  = MediaQuery.of(context).viewInsets.bottom;
    final cat = widget.cat;
    final c   = context.appColors;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: AppGlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppCircleIcon(
                  icon: cat.icon,
                  color: cat.color,
                  size: 22,
                  padding: 12,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                  opacity: 0.12,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.label,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.textDark)),
                    Text('Monthly spending limit',
                        style: TextStyle(
                            fontSize: 12,
                            color: c.textMuted,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Text('₹ ',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: c.textMuted.withOpacity(0.6))),
                  Expanded(
                    child: TextField(
                      controller: widget.ctrl,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: c.textDark),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintText: '0',
                        hintStyle: TextStyle(
                            color: c.textMuted.withOpacity(0.4),
                            fontWeight: FontWeight.w900,
                            fontSize: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [2000, 5000, 8000, 10000, 15000, 20000].map((v) =>
                  GestureDetector(
                    onTap: () => setState(() => _setQuick(v.toDouble())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        '₹${v >= 1000 ? '${v ~/ 1000}k' : v}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.textDark),
                      ),
                    ),
                  ),
              ).toList(),
            ),
            const SizedBox(height: 24),
            AppGradientButton(label: 'Set Limit', onPressed: _save),
          ],
        ),
      ),
    );
  }
}