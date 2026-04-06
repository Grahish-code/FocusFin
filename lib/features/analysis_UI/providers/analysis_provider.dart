import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/providers/database_provider.dart';

enum AnalysisRange { month1, month3, month6, year1 }

class AnalysisState {
  final AnalysisRange range;
  final bool isLoading;
  final List<Map<String, dynamic>> transactions;

  // Computed
  final double totalDebit;
  final double totalCredit;
  final Map<String, double> spendingByCategory;
  final Map<String, double> spendingByDay;      // "2026-04-01" → amount
  final String topCategory;
  final double topCategoryAmount;

  const AnalysisState({
    this.range = AnalysisRange.month1,
    this.isLoading = false,
    this.transactions = const [],
    this.totalDebit = 0,
    this.totalCredit = 0,
    this.spendingByCategory = const {},
    this.spendingByDay = const {},
    this.topCategory = '',
    this.topCategoryAmount = 0,
  });

  AnalysisState copyWith({
    AnalysisRange? range,
    bool? isLoading,
    List<Map<String, dynamic>>? transactions,
    double? totalDebit,
    double? totalCredit,
    Map<String, double>? spendingByCategory,
    Map<String, double>? spendingByDay,
    String? topCategory,
    double? topCategoryAmount,
  }) {
    return AnalysisState(
      range:               range               ?? this.range,
      isLoading:           isLoading           ?? this.isLoading,
      transactions:        transactions        ?? this.transactions,
      totalDebit:          totalDebit          ?? this.totalDebit,
      totalCredit:         totalCredit         ?? this.totalCredit,
      spendingByCategory:  spendingByCategory  ?? this.spendingByCategory,
      spendingByDay:       spendingByDay       ?? this.spendingByDay,
      topCategory:         topCategory         ?? this.topCategory,
      topCategoryAmount:   topCategoryAmount   ?? this.topCategoryAmount,
    );
  }
}

class AnalysisNotifier extends Notifier<AnalysisState> {
  @override
  AnalysisState build() {
    Future.microtask(() => fetchAnalysis());
    return const AnalysisState();
  }

  Future<void> setRange(AnalysisRange range) async {
    state = state.copyWith(range: range);
    await fetchAnalysis();
  }

  Future<void> fetchAnalysis() async {
    state = state.copyWith(isLoading: true);

    try {
      final db = ref.read(databaseProvider.notifier).databaseService;
      if (!db.isOpen) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final now = DateTime.now();
      final from = switch (state.range) {
        AnalysisRange.month1 => DateTime(now.year, now.month - 1,  now.day),
        AnalysisRange.month3 => DateTime(now.year, now.month - 3,  now.day),
        AnalysisRange.month6 => DateTime(now.year, now.month - 6,  now.day),
        AnalysisRange.year1  => DateTime(now.year - 1, now.month,  now.day),
      };

      final txs = await db.fetchTransactionsForRange(from: from, to: now);

      double totalDebit  = 0;
      double totalCredit = 0;
      final Map<String, double> byCategory = {};
      final Map<String, double> byDay      = {};

      for (final tx in txs) {
        final amount   = (tx['amount'] as num).toDouble();
        final type     = tx['type'] as String;
        final category = (tx['category'] as String?) ?? 'Uncategorized';
        final day      = (tx['date'] as String).split('T').first;

        if (type == 'debit') {
          totalDebit += amount;
          byCategory[category] = (byCategory[category] ?? 0) + amount;
          byDay[day]           = (byDay[day] ?? 0) + amount;
        } else {
          totalCredit += amount;
        }
      }

      // Sort byDay by date
      final sortedByDay = Map.fromEntries(
        byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      String topCat    = '';
      double topAmount = 0;
      byCategory.forEach((cat, amt) {
        if (amt > topAmount) { topAmount = amt; topCat = cat; }
      });

      state = state.copyWith(
        isLoading:          false,
        transactions:       txs,
        totalDebit:         totalDebit,
        totalCredit:        totalCredit,
        spendingByCategory: byCategory,
        spendingByDay:      sortedByDay,
        topCategory:        topCat,
        topCategoryAmount:  topAmount,
      );
    } catch (e) {
      print('📊 [AnalysisNotifier] ❌ Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

final analysisProvider = NotifierProvider<AnalysisNotifier, AnalysisState>(
  AnalysisNotifier.new,
);