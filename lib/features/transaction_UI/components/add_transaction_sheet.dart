// lib/features/transactions/screens/add_transaction_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust path to match your project structure
import '../../../core/constants/transaction_categories.dart';

import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';
import '../../transactions/providers/transaction_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedType = 'debit';
  String _selectedCategory = 'Others';
  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final c = context.appColors;

    // 🛠️ THE FIX: Wrap the ENTIRE sheet in the SingleChildScrollView,
    // and apply the keyboard padding here.
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: kb),
      physics: const BouncingScrollPhysics(),
      child: AppGlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "New Transaction",
              style: AppTextStyles.sectionHeading.copyWith(color: c.textDark),
            ),
            const SizedBox(height: 24),

            // ── Type Toggle (Debit/Credit) ──
            Row(
              children: [
                Expanded(
                  child: _TypeToggleBtn(
                    c: c,
                    label: 'Paid (Debit)',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: _selectedType == 'debit',
                    activeColor: c.rose,
                    onTap: () => setState(() => _selectedType = 'debit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeToggleBtn(
                    c: c,
                    label: 'Received',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: _selectedType == 'credit',
                    activeColor: c.emerald,
                    onTap: () => setState(() => _selectedType = 'credit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Amount & Date Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const AppSectionLabel(title: "AMOUNT", padding: EdgeInsets.zero),

                // Date Picker Button
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: c.isDark
                                ? ColorScheme.dark(
                              primary: c.emerald,
                              onPrimary: Colors.white,
                              surface: c.surface,
                              onSurface: c.textDark,
                            )
                                : ColorScheme.light(
                              primary: c.textDark,
                              onPrimary: Colors.white,
                              surface: c.surface,
                              onSurface: c.textDark,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: c.textDark),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(_selectedDate),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Amount Input ──
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
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.textDark),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintText: '0',
                        hintStyle: TextStyle(color: c.textMuted.withOpacity(0.4)),
                        isDense: true,
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
                  final isSelected = _selectedCategory == cat.label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat.label),
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
                controller: _noteController,
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
              child: AppGradientButton(
                label: "Save Transaction",
                onPressed: () async {
                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) return;

                  await ref.read(transactionProvider.notifier).addManualTransaction(
                    amount: amount,
                    type: _selectedType,
                    date: _selectedDate,
                    category: _selectedCategory,
                    note: _noteController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Transaction added", style: TextStyle(fontWeight: FontWeight.w600, color: c.bg)),
                        backgroundColor: c.textDark, // Inverted colors for high contrast
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Toggle Button for Debit/Credit
class _TypeToggleBtn extends StatelessWidget {
  final AppColorScheme c; // Added dynamic scheme
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