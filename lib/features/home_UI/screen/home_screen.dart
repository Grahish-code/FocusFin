// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust these imports to match your actual project structure
import '../../../core/constants/transaction_categories.dart';

import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';
import '../../auth/providers/biometric_provider.dart';
import '../../sms/providers/balance_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../provider/home_ui_provider.dart';

// Import your new component
import '../component/sticky_balance_card.dart';

// ═══════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceState = ref.watch(balanceProvider);
    final txState      = ref.watch(transactionProvider);
    final isVisible    = ref.watch(balanceVisibilityProvider);
    final isBiometricEnabled = ref.watch(biometricProvider);

    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── PINNED BALANCE CARD ───────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyBalanceHeaderDelegate(
              ref,
              balanceState,
              isVisible,
              isBiometricEnabled,
              c.isDark, // <-- This forces the gradient to sync instantly!
            ),
          ),

          // ─── UNCATEGORIZED SECTION HEADER ──────────────────────────────
          if (txState.uncategorized.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 18,
                      decoration: BoxDecoration(
                        color: c.textDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${txState.uncategorized.length} transaction${txState.uncategorized.length > 1 ? 's need' : ' needs'} a category',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── UNCATEGORIZED CARD ANIMATION WRAPPER ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.15, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: txState.uncategorized.isNotEmpty
                    ? _CategorizationCard(
                  key: ValueKey(txState.uncategorized.first['id']),
                  tx: txState.uncategorized.first,
                  remaining: txState.uncategorized.length,
                )
                    : const _AllClearedCard(key: ValueKey('all_cleared')),
              ),
            ),
          ),

          // ─── RECENT TRANSACTIONS HEADER ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Transactions",
                    style: AppTextStyles.cardTitle.copyWith(color: c.textDark),
                  ),
                  if (txState.isLoading)
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.textDark),
                    ),
                ],
              ),
            ),
          ),

          // ─── TRANSACTIONS LIST ─────────────────────────────────────────
          if (txState.transactions.isEmpty && !txState.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text("No transactions found.",
                      style: TextStyle(color: c.textMuted, fontSize: 16)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final tx       = txState.transactions[index];
                    final isCredit = tx['type'] == 'credit';
                    final hasCategory = tx['category'] != null;

                    final matchedCat = hasCategory
                        ? kTransactionCategories
                        .where((x) => x.label == tx['category'])
                        .firstOrNull
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            AppCircleIcon(
                              icon: isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isCredit ? c.emerald : c.textDark,
                              size: 18,
                              padding: 10,
                              opacity: isCredit ? 0.12 : (c.isDark ? 0.12 : 0.06),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['source'] ?? 'Unknown Source',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: c.textDark,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        (tx['date'] ?? '').toString().split('T').first,
                                        style: TextStyle(
                                            color: c.textMuted,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11),
                                      ),
                                      if (matchedCat != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: matchedCat.color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(matchedCat.icon,
                                                  color: matchedCat.color, size: 10),
                                              const SizedBox(width: 4),
                                              Text(
                                                matchedCat.label,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: matchedCat.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${isCredit ? '+' : '-'} ₹${tx['amount']}",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isCredit ? c.emerald : c.textDark,
                                fontSize: 16,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: txState.transactions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CATEGORIZATION CARD & ALL CLEARED CARD
// ═══════════════════════════════════════════════════════════════
class _CategorizationCard extends ConsumerWidget {
  final Map<String, dynamic> tx;
  final int remaining;

  const _CategorizationCard({super.key, required this.tx, required this.remaining});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final isDebit = tx['type'] == 'debit';
    final amount  = tx['amount'];
    final source  = tx['source'] ?? 'Unknown';
    final date    = (tx['date'] ?? '').toString().split('T').first;

    return AppGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                AppCircleIcon(
                  icon: isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: c.textDark,
                  size: 16,
                  padding: 8,
                  opacity: c.isDark ? 0.12 : 0.06,
                  borderRadius: BorderRadius.circular(10),
                  shape: BoxShape.rectangle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(source, style: TextStyle(color: c.textDark, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(date, style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w500, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${isDebit ? '-' : '+'} ₹$amount", style: TextStyle(color: c.textDark, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
                    if (remaining > 1)
                      Text('+${remaining - 1} more waiting', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Select a category', style: TextStyle(color: c.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: (kTransactionCategories.length / 2).ceil(),
              itemBuilder: (context, colIndex) {
                final topIndex    = colIndex * 2;
                final bottomIndex = topIndex + 1;
                final topCat      = kTransactionCategories[topIndex];
                final bottomCat   = bottomIndex < kTransactionCategories.length ? kTransactionCategories[bottomIndex] : null;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CategoryPill(cat: topCat, txId: tx['id'], ref: ref),
                      const SizedBox(height: 8),
                      if (bottomCat != null)
                        _CategoryPill(cat: bottomCat, txId: tx['id'], ref: ref)
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final TransactionCategory cat;
  final String txId;
  final WidgetRef ref;

  const _CategoryPill({required this.cat, required this.txId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: () {
        ref.read(transactionProvider.notifier).categorizeTransaction(id: txId, category: cat.label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cat.color.withOpacity(c.isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cat.color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, color: cat.color, size: 14),
            const SizedBox(width: 6),
            Text(cat.label, style: TextStyle(color: c.textDark, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _AllClearedCard extends StatelessWidget {
  const _AllClearedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Row(
        children: [
          AppCircleIcon(
            icon: Icons.check_circle_rounded,
            color: c.emerald,
            size: 28,
            padding: 12,
            opacity: 0.12,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You're all caught up!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textDark)),
                const SizedBox(height: 4),
                Text("All your transactions have been beautifully categorized.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.textMuted, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}