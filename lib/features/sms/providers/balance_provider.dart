import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/sms_service.dart';
import '../../database/providers/database_provider.dart'; // Add this import!

class BalanceState {
  final String? balance;
  final String? dateFormatted;
  final bool isLoading;
  final String? error;

  BalanceState({
    this.balance,
    this.dateFormatted,
    this.isLoading = false,
    this.error,
  });

  BalanceState copyWith({
    String? balance,
    String? dateFormatted,
    bool? isLoading,
    String? error,
  }) {
    return BalanceState(
      balance: balance ?? this.balance,
      dateFormatted: dateFormatted ?? this.dateFormatted,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BalanceNotifier extends Notifier<BalanceState> {
  @override
  BalanceState build() {
    print('⚙️ [BalanceNotifier] build() called — initializing and triggering fetchBalance()');
    Future.microtask(() => fetchBalance());
    return BalanceState(isLoading: true);
  }

  // Helper function to format DateTime nicely for the UI
  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;

    String suffix = 'th';
    if (day % 10 == 1 && day != 11) suffix = 'st';
    else if (day % 10 == 2 && day != 12) suffix = 'nd';
    else if (day % 10 == 3 && day != 13) suffix = 'rd';

    return '$day$suffix $month $year';
  }

  Future<void> fetchBalance() async {
    print('⚙️ [BalanceNotifier] fetchBalance() started');
    state = BalanceState(isLoading: true);

    try {
      // ─────────────────────────────────────────────────────────────────
      // STRATEGY 1: FAST PATH - CHECK THE LOCAL DATABASE FIRST
      // ─────────────────────────────────────────────────────────────────
      final dbService = ref.read(databaseProvider.notifier).databaseService;

      if (dbService.isOpen) {
        final latestTx = await dbService.fetchLatestBalanceTransaction();

        if (latestTx != null) {
          final dbBalance = latestTx['balance'].toString();
          final dbDateStr = latestTx['date'] as String;
          final dbDate = DateTime.parse(dbDateStr);

          print('⚙️ [BalanceNotifier] ✅ Balance pulled from LOCAL DB: ₹$dbBalance');

          state = BalanceState(
            isLoading: false,
            balance: dbBalance,
            dateFormatted: _formatDate(dbDate),
          );
          return; // Exit early! No need to run native Kotlin code.
        }
      }

      // ─────────────────────────────────────────────────────────────────
      // STRATEGY 2: FALLBACK - DB IS EMPTY, FETCH FROM KOTLIN / SMS
      // ─────────────────────────────────────────────────────────────────
      print('⚙️ [BalanceNotifier] DB empty or no balance found. Falling back to native SMS read...');

      final prefs = await SharedPreferences.getInstance();
      final banksJson = prefs.getString('selected_bank_names');

      if (banksJson == null) {
        state = BalanceState(isLoading: false, error: 'Bank not configured');
        return;
      }

      final selectedBanks = List<String>.from(jsonDecode(banksJson));

      if (selectedBanks.isEmpty) {
        state = BalanceState(isLoading: false, error: 'No banks selected');
        return;
      }

      final primaryBankName = selectedBanks.first;

      final smsService = ref.read(smsListenerServiceProvider);
      final result = await smsService.getLatestBalance(primaryBankName);

      if (result == null) {
        state = BalanceState(isLoading: false, error: 'No balance found in SMS');
      } else {
        print('⚙️ [BalanceNotifier] ✅ Balance pulled from NATIVE SMS: ₹${result.balance}');
        state = BalanceState(
          isLoading: false,
          balance: result.balance,
          dateFormatted: result.formattedDate,
        );
      }

    } catch (e, stack) {
      print('⚙️ [BalanceNotifier] ❌ Unexpected exception: $e');
      print('⚙️ [BalanceNotifier] StackTrace: $stack');
      state = BalanceState(isLoading: false, error: 'Failed to read balance');
    }
  }
}

final balanceProvider = NotifierProvider<BalanceNotifier, BalanceState>(
  BalanceNotifier.new,
);