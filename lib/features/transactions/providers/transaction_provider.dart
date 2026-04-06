// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../database/providers/database_provider.dart';
// import '../services/transaction_service.dart';
//
// class TransactionState {
//   final bool isInserting;
//   final String? lastError;
//   final int totalInserted; // running count for this session
//
//   TransactionState({
//     this.isInserting = false,
//     this.lastError,
//     this.totalInserted = 0,
//   });
//
//   TransactionState copyWith({
//     bool? isInserting,
//     String? lastError,
//     int? totalInserted,
//   }) {
//     return TransactionState(
//       isInserting:   isInserting   ?? this.isInserting,
//       lastError:     lastError,
//       totalInserted: totalInserted ?? this.totalInserted,
//     );
//   }
// }
//
// class TransactionNotifier extends Notifier<TransactionState> {
//   final _transactionService = TransactionService();
//
//   @override
//   TransactionState build() {
//     print('📦 [TransactionNotifier] Initialized.');
//     return TransactionState();
//   }
//
//   /// Called when a bank SMS arrives (from the SMS channel or broadcast receiver).
//   /// [sender]   — raw SMS sender ID e.g. "PNBSMS" or "VM-PNBSMS"
//   /// [body]     — full SMS body text
//   /// [bankName] — resolved bank name from kSenderIdToBankName
//   /// [receivedAt] — timestamp from the SMS metadata
//   Future<void> handleIncomingSms({
//     required String sender,
//     required String body,
//     required String bankName,
//     DateTime? receivedAt,
//   }) async {
//     print('📦 [TransactionNotifier] handleIncomingSms() called.');
//     print('📦 [TransactionNotifier] sender=$sender | bank=$bankName');
//
//     state = state.copyWith(isInserting: true, lastError: null);
//
//     try {
//       // Step 1 — parse SMS
//       final parsed = _transactionService.parseSmS(
//         sender:     sender,
//         body:       body,
//         bankName:   bankName,
//         receivedAt: receivedAt,
//       );
//
//       if (parsed == null) {
//         print('📦 [TransactionNotifier] ⚠️ SMS did not parse into a transaction_UI — ignoring.');
//         state = state.copyWith(isInserting: false);
//         return;
//       }
//
//       // Step 2 — get DB service from database provider
//       final dbService = ref.read(databaseProvider.notifier).databaseService;
//
//       if (!dbService.isOpen) {
//         print('📦 [TransactionNotifier] ❌ Database is not open — cannot insert.');
//         state = state.copyWith(
//           isInserting: false,
//           lastError: 'Database not open',
//         );
//         return;
//       }
//
//       // Step 3 — insert into DB with category = null
//       final success = await dbService.insertTransaction(
//         id:        parsed.id,
//         amount:    parsed.amount,
//         type:      parsed.type,
//         date:      parsed.date,
//         createdAt: parsed.createdAt,
//         balance:   parsed.balance,
//         rawSms:    parsed.rawSms,
//         source:    parsed.source,
//         category:  null, // user will categorise later
//       );
//
//       if (success) {
//         print('📦 [TransactionNotifier] ✅ Transaction saved to DB successfully.');
//         state = state.copyWith(
//           isInserting:   false,
//           totalInserted: state.totalInserted + 1,
//         );
//       } else {
//         print('📦 [TransactionNotifier] ❌ DB insert returned false.');
//         state = state.copyWith(
//           isInserting: false,
//           lastError:   'Failed to save transaction_UI',
//         );
//       }
//     } catch (e, stack) {
//       print('📦 [TransactionNotifier] ❌ Exception: $e');
//       print('📦 [TransactionNotifier] StackTrace: $stack');
//       state = state.copyWith(
//         isInserting: false,
//         lastError:   'Unexpected error: $e',
//       );
//     }
//   }
// }
//
// final transactionProvider = NotifierProvider<TransactionNotifier, TransactionState>(
//   TransactionNotifier.new,
// );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/providers/database_provider.dart';
import '../services/transaction_service.dart';

class TransactionState {
  final bool isInserting;
  final String? lastError;
  final int totalInserted; // running count for this session
  final List<Map<String, dynamic>> transactions; // Fetched from DB
  final List<Map<String, dynamic>> uncategorized;
  final bool isLoading; // Fetch loading state

  TransactionState({
    this.isInserting = false,
    this.lastError,
    this.totalInserted = 0,
    this.transactions = const [],
    this.uncategorized = const [],
    this.isLoading = false,
  });

  TransactionState copyWith({
    bool? isInserting,
    String? lastError,
    int? totalInserted,
    List<Map<String, dynamic>>? transactions,
    List<Map<String, dynamic>>? uncategorized,
    bool? isLoading,
  }) {
    return TransactionState(
      isInserting:   isInserting   ?? this.isInserting,
      lastError:     lastError,
      totalInserted: totalInserted ?? this.totalInserted,
      transactions:  transactions  ?? this.transactions,
      uncategorized: uncategorized ?? this.uncategorized,
      isLoading:     isLoading     ?? this.isLoading,
    );
  }
}

class TransactionNotifier extends Notifier<TransactionState> {
  final _transactionService = TransactionService();

  @override
  TransactionState build() {
    print('📦 [TransactionNotifier] Initialized.');
    // Automatically fetch transactions when the provider is first read
    Future.microtask(() => fetchTransactions());
    return TransactionState();
  }

  /// Called when overlay has already captured the category.
  /// Parses the SMS and inserts directly with the chosen category.
  Future<void> handleIncomingSmsWithCategory({
    required String sender,
    required String body,
    required String bankName,
    required String category,
    DateTime? receivedAt,
  }) async {
    print('📦 [TransactionNotifier] handleIncomingSmsWithCategory() — category="$category"');

    state = state.copyWith(isInserting: true, lastError: null);

    try {
      final parsed = _transactionService.parseSmS(
        sender:     sender,
        body:       body,
        bankName:   bankName,
        receivedAt: receivedAt,
      );

      if (parsed == null) {
        print('📦 [TransactionNotifier] ⚠️ SMS did not parse — ignoring.');
        state = state.copyWith(isInserting: false);
        return;
      }

      final dbService = ref.read(databaseProvider.notifier).databaseService;

      if (!dbService.isOpen) {
        state = state.copyWith(isInserting: false, lastError: 'Database not open');
        return;
      }

      final success = await dbService.insertTransaction(
        id:        parsed.id,
        amount:    parsed.amount,
        type:      parsed.type,
        date:      parsed.date,
        createdAt: parsed.createdAt,
        balance:   parsed.balance,
        rawSms:    parsed.rawSms,
        source:    parsed.source,
        category:  category,   // ← the key difference
      );

      if (success) {
        print('📦 [TransactionNotifier] ✅ Saved with category="$category".');
        state = state.copyWith(isInserting: false, totalInserted: state.totalInserted + 1);
        fetchTransactions();
      } else {
        state = state.copyWith(isInserting: false, lastError: 'Failed to save transaction');
      }
    } catch (e, stack) {
      print('📦 [TransactionNotifier] ❌ Exception: $e\n$stack');
      state = state.copyWith(isInserting: false, lastError: 'Unexpected error: $e');
    }
  }

  /// Fetches all transactions from the database
  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, lastError: null);

    try {
      final dbService = ref.read(databaseProvider.notifier).databaseService;

      if (!dbService.isOpen) {
        state = state.copyWith(
          isLoading: false,
          lastError: 'Database not open',
        );
        return;
      }

      final results = await Future.wait([
        dbService.fetchAllTransactions(),
        dbService.fetchUncategorizedTransactions(),
      ]);

      state = state.copyWith(
        isLoading: false,
        transactions: results[0],
        uncategorized: results[1],   // ADD THIS
      );
    } catch (e, stack) {
      print('📦 [TransactionNotifier] ❌ Fetch Exception: $e');
      state = state.copyWith(
        isLoading: false,
        lastError: 'Failed to fetch transactions: $e',
      );
    }
  }


  // Inside TransactionNotifier class

  Future<void> addManualTransaction({
    required double amount,
    required String type,
    required DateTime date,
    required String category,
    String? note,
  }) async {
    state = state.copyWith(isInserting: true);
    final dbService = ref.read(databaseProvider.notifier).databaseService;

    // 1. Get the latest balance to calculate the new one
    final lastTx = await dbService.fetchLatestBalanceTransaction();
    double currentBalance = lastTx?['balance'] ?? 0.0;

    // 2. Calculate new balance
    double newBalance = type == 'credit'
        ? currentBalance + amount
        : currentBalance - amount;

    // 3. Insert
    await dbService.insertTransaction(
      id: const Uuid().v4(),
      amount: amount,
      type: type,
      date: date.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      category: category,
      note: note,
      balance: newBalance,
      source: 'Manual',
    );

    await fetchTransactions(); // Refresh UI
  }

  Future<void> categorizeTransaction({
    required String id,
    required String category,
  }) async {
    final dbService = ref.read(databaseProvider.notifier).databaseService;
    final success = await dbService.updateTransactionCategory(
      id: id,
      category: category,
    );
    if (success) {
      // Optimistically remove from uncategorized list immediately
      state = state.copyWith(
        uncategorized: state.uncategorized.where((t) => t['id'] != id).toList(),
      );
      // Also refresh the full list so category shows up there too
      fetchTransactions();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final dbService = ref.read(databaseProvider.notifier).databaseService;
    final success = await dbService.deleteTransaction(id);
    if (success) {
      await fetchTransactions(); // This forces all UI and categories to recalculate!
    }
  }

  Future<void> editTransaction({
    required String id,
    required double amount,
    required String type,
    required String category,
    String? note,
  }) async {
    final dbService = ref.read(databaseProvider.notifier).databaseService;
    final success = await dbService.updateTransactionDetails(
      id: id,
      amount: amount,
      type: type,
      category: category,
      note: note,
    );
    if (success) {
      await fetchTransactions(); // Instantly fixes the category math!
    }
  }

  /// Called when a bank SMS arrives (from the SMS channel or broadcast receiver).
  Future<void> handleIncomingSms({
    required String sender,
    required String body,
    required String bankName,
    DateTime? receivedAt,
  }) async {
    print('📦 [TransactionNotifier] handleIncomingSms() called.');
    print('📦 [TransactionNotifier] sender=$sender | bank=$bankName');

    state = state.copyWith(isInserting: true, lastError: null);

    try {
      // Step 1 — parse SMS
      final parsed = _transactionService.parseSmS(
        sender:     sender,
        body:       body,
        bankName:   bankName,
        receivedAt: receivedAt,
      );

      if (parsed == null) {
        print('📦 [TransactionNotifier] ⚠️ SMS did not parse into a transaction_UI — ignoring.');
        state = state.copyWith(isInserting: false);
        return;
      }

      // Step 2 — get DB service from database provider
      final dbService = ref.read(databaseProvider.notifier).databaseService;

      if (!dbService.isOpen) {
        print('📦 [TransactionNotifier] ❌ Database is not open — cannot insert.');
        state = state.copyWith(
          isInserting: false,
          lastError: 'Database not open',
        );
        return;
      }

      // Step 3 — insert into DB with category = null
      final success = await dbService.insertTransaction(
        id:        parsed.id,
        amount:    parsed.amount,
        type:      parsed.type,
        date:      parsed.date,
        createdAt: parsed.createdAt,
        balance:   parsed.balance,
        rawSms:    parsed.rawSms,
        source:    parsed.source,
        category:  null, // user will categorise later
      );

      if (success) {
        print('📦 [TransactionNotifier] ✅ Transaction saved to DB successfully.');
        state = state.copyWith(
          isInserting:   false,
          totalInserted: state.totalInserted + 1,
        );
        // Refresh the list immediately so the UI updates
        fetchTransactions();
      } else {
        print('📦 [TransactionNotifier] ❌ DB insert returned false.');
        state = state.copyWith(
          isInserting: false,
          lastError:   'Failed to save transaction_UI',
        );
      }
    } catch (e, stack) {
      print('📦 [TransactionNotifier] ❌ Exception: $e');
      print('📦 [TransactionNotifier] StackTrace: $stack');
      state = state.copyWith(
        isInserting: false,
        lastError:   'Unexpected error: $e',
      );
    }
  }
}



final transactionProvider = NotifierProvider<TransactionNotifier, TransactionState>(
  TransactionNotifier.new,
);