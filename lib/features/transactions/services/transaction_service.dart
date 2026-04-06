import 'package:uuid/uuid.dart';

/// Represents a parsed bank transaction_UI from an SMS.
class ParsedTransaction {
  final String id;
  final double amount;
  final String type;      // 'credit' or 'debit'
  final double? balance;
  final String date;      // ISO 8601
  final String createdAt; // ISO 8601
  final String rawSms;
  final String? source;   // Bank name

  ParsedTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.balance,
    required this.date,
    required this.createdAt,
    required this.rawSms,
    this.source,
  });
}

class TransactionService {
  final _uuid = const Uuid();

  /// Main entry point — takes raw SMS sender + body + bank name.
  /// Returns a [ParsedTransaction] or null if this SMS is not a transaction_UI alert.
  ParsedTransaction? parseSmS({
    required String sender,
    required String body,
    required String bankName,
    DateTime? receivedAt,
  }) {
    print('💬 [TransactionService] Parsing SMS from sender="$sender" bank="$bankName"');
    print('💬 [TransactionService] Body: $body');

    final now = receivedAt ?? DateTime.now();

    // Step 1 — detect transaction_UI type
    final type = _detectType(body);
    if (type == null) {
      print('💬 [TransactionService] ⚠️ Not a debit/credit SMS — skipping.');
      return null;
    }
    print('💬 [TransactionService] ✅ Type detected: $type');

    // Step 2 — extract amount
    final amount = _extractAmount(body);
    if (amount == null) {
      print('💬 [TransactionService] ⚠️ Could not extract amount — skipping.');
      return null;
    }
    print('💬 [TransactionService] ✅ Amount extracted: $amount');

    // Step 3 — extract balance (optional, don't fail if missing)
    final balance = _extractBalance(body);
    print('💬 [TransactionService] Balance extracted: ${balance ?? "not found"}');

    final transaction = ParsedTransaction(
      id:        _uuid.v4(),
      amount:    amount,
      type:      type,
      balance:   balance,
      date:      now.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      rawSms:    body,
      source:    bankName,
    );

    print('💬 [TransactionService] ✅ ParsedTransaction ready — id=${transaction.id}');
    return transaction;
  }

  // ─── Type detection ───────────────────────────────────────────────────────

  String? _detectType(String body) {
    final lower = body.toLowerCase();

    // Credit keywords
    final creditPatterns = [
      'credited', 'credit', 'received', 'deposited',
      'added', 'refund', 'cashback', 'reversal',
    ];
    // Debit keywords
    final debitPatterns = [
      'debited', 'debit', 'withdrawn', 'paid', 'spent',
      'purchase', 'payment', 'deducted', 'used',
    ];

    // Check debit first (more specific)
    for (final kw in debitPatterns) {
      if (lower.contains(kw)) {
        print('💬 [TransactionService] Debit keyword matched: "$kw"');
        return 'debit';
      }
    }
    for (final kw in creditPatterns) {
      if (lower.contains(kw)) {
        print('💬 [TransactionService] Credit keyword matched: "$kw"');
        return 'credit';
      }
    }
    return null;
  }

  // ─── Amount extraction ────────────────────────────────────────────────────

  double? _extractAmount(String body) {
    final patterns = [
      // INR 1,234.56 or INR1234
      RegExp(r'(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
      // debited by Rs. 500
      RegExp(r'(?:debited|credited)\s+(?:by|for|with)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+\.?\d*)', caseSensitive: false),
      // for INR 150.00
      RegExp(r'for\s+INR\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(body);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final value = double.tryParse(raw);
        if (value != null) {
          print('💬 [TransactionService] Amount pattern[$i] matched → $value');
          return value;
        }
      }
    }
    return null;
  }

  // ─── Balance extraction ───────────────────────────────────────────────────

  double? _extractBalance(String body) {
    final patterns = [
      // Available Bal INR 184.88
      RegExp(r'Available\s*Bal\s*(?:INR|Rs\.?|₹)?\s*([\d,]+\.?\d*)', caseSensitive: false),
      // Bal INR 34.88
      RegExp(r'\.?Bal\s+(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
      // Balance: INR 5000
      RegExp(r'Balance[:\s]+(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
      // Avl Bal: INR 500
      RegExp(r'Avl\s*Bal[:\s]+(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
      // Bal Rs. 1,234
      RegExp(r'Bal\s*Rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      // INR 34.88 Cr (credit balance notation)
      RegExp(r'INR\s*([\d,]+\.?\d*)\s*Cr\b', caseSensitive: false),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(body);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final value = double.tryParse(raw);
        if (value != null) {
          print('💬 [TransactionService] Balance pattern[$i] matched → $value');
          return value;
        }
      }
    }
    print('💬 [TransactionService] No balance pattern matched.');
    return null;
  }
}