import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/providers/database_provider.dart';
import '../../transactions/providers/transaction_provider.dart';

enum ViewMode { date, category }

// ─── 1. THE STATE CLASS ───
class TransactionUIState {
  final ViewMode viewMode;
  final int month;
  final int year;
  final List<Map<String, dynamic>> filteredTransactions;
  final Map<String, Map<String, dynamic>> groupedByCategory;

  const TransactionUIState({
    this.viewMode = ViewMode.date,
    this.month = 1,
    this.year = 2026,
    this.filteredTransactions = const [],
    this.groupedByCategory = const {},
  });

  TransactionUIState copyWith({
    ViewMode? viewMode,
    int? month,
    int? year,
    List<Map<String, dynamic>>? filteredTransactions,
    Map<String, Map<String, dynamic>>? groupedByCategory,
  }) {
    return TransactionUIState(
      viewMode: viewMode ?? this.viewMode,
      month: month ?? this.month,
      year: year ?? this.year,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      groupedByCategory: groupedByCategory ?? this.groupedByCategory,
    );
  }
}

// ─── 2. THE NOTIFIER CLASS ───
class TransactionUINotifier extends Notifier<TransactionUIState> {
  @override
  TransactionUIState build() {
    final now = DateTime.now();

    // Listen to your main transactionProvider. If an SMS comes in or the
    // DB updates, this automatically re-runs the filters for the UI!
    ref.listen(transactionProvider, (previous, next) {

        _computeData();

    });

    Future.microtask(() => _computeData());
    return TransactionUIState(month: now.month, year: now.year);
  }

  // ─── UI CONTROLS ───
  void setViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setMonthYear(int month, int year) {
    state = state.copyWith(month: month, year: year);
    _computeData(); // Recalculate lists when month changes
  }

  // ─── THE MATH / FILTERING ───
  void _computeData() {
    // Read the master list from your existing provider
    final allTxs = ref.read(transactionProvider).transactions;

    // 1. Filter by selected month/year
    final filtered = allTxs.where((t) {
      final date = DateTime.parse(t['date']);
      return date.month == state.month && date.year == state.year;
    }).toList();

    // 2. Group by category
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var tx in filtered) {
      final category = tx['category'] ?? 'Others';
      final amount = (tx['amount'] as num).toDouble();
      final type = tx['type'] as String;

      if (!grouped.containsKey(category)) {
        grouped[category] = {'total': 0.0, 'transactions': <Map<String, dynamic>>[]};
      }

      // Add to category total (usually we only sum debits for expenses)
      if (type == 'debit') {
        grouped[category]!['total'] += amount;
      }
      grouped[category]!['transactions'].add(tx);
    }

    // 3. Update the state
    state = state.copyWith(
      filteredTransactions: filtered,
      groupedByCategory: grouped,
    );
  }

  // ─── ADD MANUAL TRANSACTION ───
  Future<void> addManualTransaction({
    required double amount,
    required String type,
    required DateTime date,
    required String category,
    String? note,
  }) async {
    final dbService = ref.read(databaseProvider.notifier).databaseService;

    // Fetch last known balance
    final lastTx = await dbService.fetchLatestBalanceTransaction();
    double currentBalance = lastTx?['balance'] ?? 0.0;

    // Calculate new balance
    double newBalance = type == 'credit' ? currentBalance + amount : currentBalance - amount;

    // Insert
    await dbService.insertTransaction(
      id: const Uuid().v4(),
      amount: amount,
      type: type,
      date: date.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      category: category,
      note: note,
      balance: newBalance,
      source: 'Manual Entry',
    );

    // Refresh the main transaction provider (which triggers the ref.listen above)
    ref.read(transactionProvider.notifier).fetchTransactions();
  }
}

// ─── 3. THE PROVIDER ───
final transactionUIProvider = NotifierProvider<TransactionUINotifier, TransactionUIState>(
  TransactionUINotifier.new,
);