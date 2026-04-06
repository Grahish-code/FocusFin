// lib/features/transactions/screens/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/transaction_categories.dart';
import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';
import '../components/add_transaction_sheet.dart';
import '../components/transaction_actions.dart';
import '../providers/transactions_ui_provider.dart';

// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState    = ref.watch(transactionUIProvider);
    final uiNotifier = ref.read(transactionUIProvider.notifier);
    final c          = context.appColors; // <-- Grab dynamic colors

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── FILTERS & HEADER ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month Stepper
                  Container(
                    decoration: BoxDecoration(
                      color: c.surface2, // Using surface2 for consistent contrast
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StepperBtn(
                          icon: Icons.chevron_left_rounded,
                          onTap: () {
                            if (uiState.month == 1) {
                              uiNotifier.setMonthYear(
                                  12, uiState.year - 1);
                            } else {
                              uiNotifier.setMonthYear(
                                  uiState.month - 1, uiState.year);
                            }
                          },
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            DateFormat('MMM yyyy').format(
                                DateTime(uiState.year, uiState.month)),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: c.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        _StepperBtn(
                          icon: Icons.chevron_right_rounded,
                          onTap: () {
                            if (uiState.month == 12) {
                              uiNotifier.setMonthYear(
                                  1, uiState.year + 1);
                            } else {
                              uiNotifier.setMonthYear(
                                  uiState.month + 1, uiState.year);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // View Mode Toggle (date | category)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TogglePill(
                          icon: Icons.calendar_today_rounded,
                          isSelected:
                          uiState.viewMode == ViewMode.date,
                          onTap: () =>
                              uiNotifier.setViewMode(ViewMode.date),
                        ),
                        _TogglePill(
                          icon: Icons.pie_chart_rounded,
                          isSelected:
                          uiState.viewMode == ViewMode.category,
                          onTap: () =>
                              uiNotifier.setViewMode(ViewMode.category),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── ADD TRANSACTION BUTTON ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: context.ctaGradient, // Adapt to theme
                  boxShadow: context.ctaShadow,   // Adapt to theme
                  borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddTransactionSheet(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.transparent, // Let container gradient show
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Manual Transaction',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── LIST VIEW ─────────────────────────────────────────
            Expanded(
              child: uiState.viewMode == ViewMode.date
                  ? const _DateWiseListView()
                  : const _CategoryWiseListView(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DATE WISE LIST
// ═══════════════════════════════════════════════════════════════
class _DateWiseListView extends ConsumerWidget {
  const _DateWiseListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionUIProvider).filteredTransactions;
    final c = context.appColors;

    if (transactions.isEmpty) return const _EmptyState();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx      = transactions[index];
        final isDebit = tx['type'] == 'debit';
        final catData = kTransactionCategories.firstWhere(
              (x) => x.label == (tx['category'] ?? 'Others'),
          orElse: () => kTransactionCategories.last,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onLongPress: () =>
                showTransactionActionSheet(context, ref, tx),
            child: AppGlassCard(
              padding: const EdgeInsets.all(16),
              radius: AppRadius.lg,
              child: Row(
                children: [
                  // Category icon box
                  AppCircleIcon(
                    icon: catData.icon,
                    color: catData.color,
                    size: 22,
                    padding: 11,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(14),
                    opacity: 0.15,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['note']?.isNotEmpty == true
                              ? tx['note']
                              : catData.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: c.textDark,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM · hh:mm a')
                              .format(DateTime.parse(tx['date'])),
                          style: AppTextStyles.caption.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${isDebit ? '-' : '+'} ₹${tx['amount']}',
                    style: TextStyle(
                      color: isDebit
                          ? c.rose
                          : c.emerald,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CATEGORY WISE LIST
// ═══════════════════════════════════════════════════════════════
class _CategoryWiseListView extends ConsumerWidget {
  const _CategoryWiseListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedData = ref.watch(transactionUIProvider).groupedByCategory;
    final c = context.appColors;

    if (groupedData.isEmpty) return const _EmptyState();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: groupedData.entries.map((entry) {
        final categoryName = entry.key;
        final totalSpend = entry.value['total'] as double;
        final txList = entry.value['transactions'] as List<Map<String, dynamic>>;
        final catData = kTransactionCategories.firstWhere(
              (x) => x.label == categoryName,
          orElse: () => kTransactionCategories.last,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppGlassCard(
            padding: EdgeInsets.zero,
            radius: AppRadius.lg,
            child: Theme(
              // Removes the ugly ExpansionTile divider lines
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: c.textDark,
                collapsedIconColor: c.textMuted,
                tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.only(
                    bottom: 12, left: 16, right: 16),
                leading: AppCircleIcon(
                  icon: catData.icon,
                  color: catData.color,
                  size: 22,
                  padding: 11,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(14),
                  opacity: 0.15,
                ),
                title: Text(
                  categoryName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: c.textDark,
                  ),
                ),
                subtitle: Text(
                  '${txList.length} transaction${txList.length > 1 ? 's' : ''}',
                  style: AppTextStyles.caption.copyWith(color: c.textMuted),
                ),
                trailing: Text(
                  '₹${totalSpend.toStringAsFixed(0)}',
                  style: AppTextStyles.amountSmall.copyWith(color: c.textDark),
                ),
                children: txList.map((tx) {
                  return InkWell(
                    onLongPress: () =>
                        showTransactionActionSheet(context, ref, tx),
                    borderRadius:
                    BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      child: Row(
                        children: [
                          // indent bar
                          Container(
                            width: 2,
                            height: 24,
                            decoration: BoxDecoration(
                              color: c.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx['note']?.isNotEmpty == true
                                      ? tx['note']
                                      : 'Transaction',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: c.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  DateFormat('dd MMM · hh:mm a')
                                      .format(DateTime.parse(tx['date'])),
                                  style: AppTextStyles.caption
                                      .copyWith(fontSize: 10, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${tx['amount']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LOCAL UI COMPONENTS
// ═══════════════════════════════════════════════════════════════

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 20, color: c.textDark),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TogglePill({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.textDark : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? c.bg : c.textMuted, // Flips to background color for contrast
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: c.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: c.textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transactions for this month will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: c.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}