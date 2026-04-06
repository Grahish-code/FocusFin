// lib/features/transactions/screens/transaction_action_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust path to match your project structure
import '../../../core/constants/transaction_categories.dart';

import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';
import '../../transactions/providers/transaction_provider.dart';


// ═══════════════════════════════════════════════════════════════
//  ACTION SHEET (BOTTOM MENU)
// ═══════════════════════════════════════════════════════════════
void showTransactionActionSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> tx) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final c = ctx.appColors; // <-- Grab dynamic colors

      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: ctx.glassShadow, // Dynamic shadow
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              "Manage Transaction",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: c.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Edit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActionSheetButton(
                icon: Icons.edit_rounded,
                label: 'Edit Transaction',
                color: c.textDark,
                bgColor: c.surface2, // Use dynamic surface color
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditSheet(context, ref, tx);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Delete Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActionSheetButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Transaction',
                color: c.rose,
                bgColor: c.rose.withOpacity(c.isDark ? 0.15 : 0.1), // Adapt opacity
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref, tx['id']);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

class _ActionSheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionSheetButton({
    required this.icon, required this.label,
    required this.color, required this.bgColor, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DELETE CONFIRMATION DIALOG
// ═══════════════════════════════════════════════════════════════
void _confirmDelete(BuildContext context, WidgetRef ref, String txId) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    pageBuilder: (ctx, anim1, anim2) {
      final c = ctx.appColors; // <-- Grab dynamic colors

      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
        child: FadeTransition(
          opacity: anim1,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: AppGlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppCircleIcon(
                    icon: Icons.delete_sweep_rounded,
                    color: c.rose,
                    size: 32,
                    padding: 16,
                    opacity: 0.15,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Delete Transaction?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This will automatically update your current balance and budget totals.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        // Upgraded to gradient button with rose override
                        child: AppGradientButton(
                          label: "Delete",
                          gradientOverride: AppGradients.rose,
                          shadowOverride: AppShadows.roseGlow,
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await ref.read(transactionProvider.notifier).deleteTransaction(txId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Transaction deleted", style: TextStyle(fontWeight: FontWeight.w600, color: c.bg)),
                                  backgroundColor: c.textDark, // High contrast
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════
//  EDIT TRANSACTION SHEET
// ═══════════════════════════════════════════════════════════════
void _showEditSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> tx) {
  final amountController = TextEditingController(text: tx['amount'].toString());
  final noteController = TextEditingController(text: tx['note'] ?? '');

  String selectedType = tx['type'];
  String selectedCategory = kTransactionCategories.any((cat) => cat.label == tx['category'])
      ? tx['category']
      : 'Others';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
          builder: (context, setState) {
            final kb = MediaQuery.of(context).viewInsets.bottom;
            final c = context.appColors; // <-- Grab dynamic colors

            return Padding(
              padding: EdgeInsets.only(bottom: kb),
              child: AppGlassSheet(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Edit Transaction",
                        style: AppTextStyles.sectionHeading.copyWith(color: c.textDark),
                      ),
                      const SizedBox(height: 24),

                      // ── Type Toggle (Debit/Credit) ──
                      Row(
                        children: [
                          Expanded(
                            child: _TypeToggleBtn(
                              c: c, // Pass scheme
                              label: 'Debit',
                              icon: Icons.arrow_upward_rounded,
                              isSelected: selectedType == 'debit',
                              activeColor: c.rose,
                              onTap: () => setState(() => selectedType = 'debit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeToggleBtn(
                              c: c, // Pass scheme
                              label: 'Credit',
                              icon: Icons.arrow_downward_rounded,
                              isSelected: selectedType == 'credit',
                              activeColor: c.emerald,
                              onTap: () => setState(() => selectedType = 'credit'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Amount Input ──
                      const AppSectionLabel(title: "AMOUNT", padding: EdgeInsets.zero),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Text('₹ ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.textMuted.withOpacity(0.5))),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.textDark),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  hintText: '0',
                                  hintStyle: TextStyle(color: c.textMuted.withOpacity(0.4)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Category Selector (Horizontal Pills) ──
                      const AppSectionLabel(title: "CATEGORY", padding: EdgeInsets.zero),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          itemCount: kTransactionCategories.length,
                          itemBuilder: (context, index) {
                            final cat = kTransactionCategories[index];
                            final isSelected = selectedCategory == cat.label;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => selectedCategory = cat.label),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? cat.color : cat.color.withOpacity(c.isDark ? 0.15 : 0.05),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: isSelected ? cat.color : cat.color.withOpacity(c.isDark ? 0.3 : 0.15)),
                                    boxShadow: isSelected && c.isDark
                                        ? [BoxShadow(color: cat.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cat.icon, color: isSelected ? Colors.white : cat.color, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : c.textDark,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Note Input ──
                      const AppSectionLabel(title: "NOTE (OPTIONAL)", padding: EdgeInsets.zero),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: c.border),
                        ),
                        child: TextField(
                          controller: noteController,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textDark),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: 'What was this for?',
                            hintStyle: TextStyle(color: c.textMuted.withOpacity(0.4)),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Save Button ──
                      SizedBox(
                        width: double.infinity,
                        // Upgraded to global gradient CTA
                        child: AppGradientButton(
                          label: "Save Changes",
                          onPressed: () async {
                            final amount = double.tryParse(amountController.text);
                            if (amount != null && amount > 0) {
                              Navigator.pop(ctx);
                              await ref.read(transactionProvider.notifier).editTransaction(
                                id: tx['id'],
                                amount: amount,
                                type: selectedType,
                                category: selectedCategory,
                                note: noteController.text.trim(),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Transaction saved", style: TextStyle(fontWeight: FontWeight.w600, color: c.bg)),
                                    backgroundColor: c.textDark, // High contrast
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
      );
    },
  );
}

// Custom Toggle Button for Debit/Credit
class _TypeToggleBtn extends StatelessWidget {
  final AppColorScheme c; // Receive dynamic scheme
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeToggleBtn({
    required this.c,
    required this.label, required this.icon,
    required this.isSelected, required this.activeColor, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(c.isDark ? 0.15 : 0.12) : c.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isSelected ? activeColor.withOpacity(0.3) : c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : c.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : c.textMuted,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}