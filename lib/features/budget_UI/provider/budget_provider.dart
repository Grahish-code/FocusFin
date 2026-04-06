import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/providers/database_provider.dart';

// ─── 1. THE STATE CLASS ───
class BudgetState {
  final int month;
  final int year;
  final bool isLoading;

  // Maps a Category Name -> Budget Limit (e.g., {'Petrol': 2000.0})
  final Map<String, double> categoryLimits;

  // Maps a Category Name -> Amount Spent This Month (e.g., {'Petrol': 1500.0})
  final Map<String, double> categorySpent;

  // List of warning cards for last month's overages
  final List<Map<String, dynamic>> lastMonthOverages;

  const BudgetState({
    required this.month,
    required this.year,
    this.isLoading = false,
    this.categoryLimits = const {},
    this.categorySpent = const {},
    this.lastMonthOverages = const [],
  });

  BudgetState copyWith({
    int? month,
    int? year,
    bool? isLoading,
    Map<String, double>? categoryLimits,
    Map<String, double>? categorySpent,
    List<Map<String, dynamic>>? lastMonthOverages,
  }) {
    return BudgetState(
      month: month ?? this.month,
      year: year ?? this.year,
      isLoading: isLoading ?? this.isLoading,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      categorySpent: categorySpent ?? this.categorySpent,
      lastMonthOverages: lastMonthOverages ?? this.lastMonthOverages,
    );
  }
}

// ─── 2. THE NOTIFIER CLASS ───
class BudgetNotifier extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    final now = DateTime.now();
    // Start by loading data for the current real-world month
    Future.microtask(() => loadBudgetData(now.month, now.year));
    return BudgetState(month: now.month, year: now.year, isLoading: true);
  }

  // Call this when the user changes the month on the Budget Screen
  Future<void> setMonthYear(int month, int year) async {
    state = state.copyWith(month: month, year: year, isLoading: true);
    await loadBudgetData(month, year);
  }

  // ─── THE MAIN LOGIC ENGINE ───
  Future<void> loadBudgetData(int month, int year) async {
    final db = ref.read(databaseProvider.notifier).databaseService;
    if (!db.isOpen) return;

    // 1. Check if budgets exist for THIS month
    List<Map<String, dynamic>> currentBudgets = await db.fetchBudgetsForMonth(month, year);

    // 2. THE CARRY-OVER TRICK: If empty, try to copy from the previous month
    if (currentBudgets.isEmpty) {
      int prevMonth = month == 1 ? 12 : month - 1;
      int prevYear = month == 1 ? year - 1 : year;

      final prevBudgets = await db.fetchBudgetsForMonth(prevMonth, prevYear);

      if (prevBudgets.isNotEmpty) {
        print('📊 [BudgetNotifier] Copying ${prevBudgets.length} budgets from previous month.');
        for (var b in prevBudgets) {
          await db.insertOrUpdateBudget(
            id: const Uuid().v4(),
            category: b['category'],
            amount: (b['amount'] as num).toDouble(),
            month: month,
            year: year,
          );
        }
        // Re-fetch now that we've copied them over
        currentBudgets = await db.fetchBudgetsForMonth(month, year);
      }
    }

    // Convert raw DB rows into an easy Map: {'Food': 3000.0, 'Petrol': 2000.0}
    final Map<String, double> limitsMap = {};
    for (var b in currentBudgets) {
      limitsMap[b['category'] as String] = (b['amount'] as num).toDouble();
    }

    // 3. CALCULATE SPENT AMOUNT FOR THIS MONTH
    // We get the transactions directly from the DB for this exact month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59); // Last day of month
    final txs = await db.fetchTransactionsForRange(from: startDate, to: endDate);

    final Map<String, double> spentMap = {};
    for (var tx in txs) {
      if (tx['type'] == 'debit') { // We only care about money leaving the account
        final cat = tx['category'] ?? 'Others';
        final amt = (tx['amount'] as num).toDouble();
        spentMap[cat] = (spentMap[cat] ?? 0.0) + amt;
      }
    }

    // 4. CHECK FOR LAST MONTH'S OVERAGES (The warning cards)
    final overages = await _calculateLastMonthOverages(month, year);

    // 5. UPDATE THE STATE
    state = state.copyWith(
      isLoading: false,
      categoryLimits: limitsMap,
      categorySpent: spentMap,
      lastMonthOverages: overages,
    );
  }

  // ─── SET A NEW BUDGET LIMIT ───
  Future<void> saveBudgetLimit(String category, double amount) async {
    final db = ref.read(databaseProvider.notifier).databaseService;

    await db.insertOrUpdateBudget(
      id: const Uuid().v4(), // We just generate a new ID, the DB replaces based on Category+Month+Year
      category: category,
      amount: amount,
      month: state.month,
      year: state.year,
    );

    // Refresh the UI
    await loadBudgetData(state.month, state.year);
  }

  // ─── OVER-BUDGET WARNING LOGIC ───
  Future<List<Map<String, dynamic>>> _calculateLastMonthOverages(int currentMonth, int currentYear) async {
    final db = ref.read(databaseProvider.notifier).databaseService;

    int lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    int lastYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    final lastBudgets = await db.fetchBudgetsForMonth(lastMonth, lastYear);
    if (lastBudgets.isEmpty) return []; // Nothing to compare

    final start = DateTime(lastYear, lastMonth, 1);
    final end = DateTime(lastYear, lastMonth + 1, 0, 23, 59, 59);
    final lastTxs = await db.fetchTransactionsForRange(from: start, to: end);

    // Add up last month's spending
    Map<String, double> lastSpent = {};
    for (var tx in lastTxs) {
      if (tx['type'] == 'debit') {
        final cat = tx['category'] ?? 'Others';
        lastSpent[cat] = (lastSpent[cat] ?? 0.0) + (tx['amount'] as num).toDouble();
      }
    }

    // Compare spent vs limit
    List<Map<String, dynamic>> warnings = [];
    for (var b in lastBudgets) {
      String cat = b['category'];
      double limit = (b['amount'] as num).toDouble();
      double spent = lastSpent[cat] ?? 0.0;

      if (spent > limit) {
        warnings.add({
          'category': cat,
          'limit': limit,
          'spent': spent,
          'over_by': spent - limit, // Math for the UI text
        });
      }
    }
    return warnings;
  }
}

// ─── 3. THE PROVIDER ───
final budgetProvider = NotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);