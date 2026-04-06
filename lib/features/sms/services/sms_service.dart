import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bank_sender_ids.dart';
import '../../transactions/providers/transaction_provider.dart';

class BalanceResult {
  final String balance;
  final DateTime date;

  BalanceResult({required this.balance, required this.date});

  String get formattedDate {
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
}

/// Connects to the native Kotlin SmsBroadcastReceiver via a MethodChannel.
/// Must be initialized once from main.dart after ProviderScope is ready.
class SmsListenerService {
  static const _channel = MethodChannel('com.focusfin.sms/receiver');

  final Ref _ref;

  SmsListenerService(this._ref);

  /// Call this once from main.dart to start listening for incoming bank SMS.
  void initialize({Future<void>? appReadyFuture}) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmSReceived') {
        // existing — no category, insert with null
        final args = call.arguments as Map;
        await _routeSmsToTransactionProvider(args);

      } else if (call.method == 'onCategorySelected') {
        // NEW — comes live from the overlay with category already picked
        final args = call.arguments as Map;
        await _routeSmsWithCategoryToProvider(args);
      }
    });

    print('📡 [SmsListenerService] ✅ Listener active.');
    _processMissedMessagesQueue(appReadyFuture: appReadyFuture);
    _processCategoryQueue(appReadyFuture: appReadyFuture); // NEW
  }

  /// NEW: Fetches the background queue and processes them
  Future<void> _processMissedMessagesQueue({Future<void>? appReadyFuture}) async {
    try {
      print('📡 [SmsListenerService] Checking for missed messages in the background queue...');

      if (appReadyFuture != null) {
        print('📡 [SmsListenerService] ⏳ Waiting for DB + auth to be ready...');
        await appReadyFuture;
        print('📡 [SmsListenerService] ✅ App ready. Now draining queue...');
      }

      final List<dynamic>? missedMessages = await _channel.invokeMethod('getAndClearMissedSmsQueue');

      if (missedMessages != null && missedMessages.isNotEmpty) {
        print('📡 [SmsListenerService] 📥 Found ${missedMessages.length} missed messages! Processing...');
        for (var msg in missedMessages) {
          await _routeSmsToTransactionProvider(Map<String, dynamic>.from(msg));
        }
        print('📡 [SmsListenerService] ✅ Finished processing missed messages.');
      } else {
        print('📡 [SmsListenerService] No missed messages in queue.');
      }
    } catch (e) {
      print('📡 [SmsListenerService] ⚠️ Failed to fetch missed SMS queue: $e');
    }
  }

  /// Drains the category queue on app launch (same pattern as missed SMS queue)
  Future<void> _processCategoryQueue({Future<void>? appReadyFuture}) async {
    try {
      if (appReadyFuture != null) await appReadyFuture;

      final List<dynamic>? queued = await _channel.invokeMethod('getAndClearCategoryQueue');

      if (queued != null && queued.isNotEmpty) {
        print('📡 [SmsListenerService] 📥 Found ${queued.length} queued categorized transactions.');
        for (var item in queued) {
          await _routeSmsWithCategoryToProvider(Map<String, dynamic>.from(item));
        }
      }
    } catch (e) {
      print('📡 [SmsListenerService] ⚠️ Failed to drain category queue: $e');
    }
  }

  /// Handles an SMS that already has a category (from overlay — live or queued)
  Future<void> _routeSmsWithCategoryToProvider(Map<dynamic, dynamic> args) async {
    final sender    = (args['sender']   as String? ?? '').trim();
    final body      = (args['body']     as String? ?? '').trim();
    final category  = (args['category'] as String? ?? '').trim();
    final tsMs      = args['timestamp'] as int?;

    final strippedSender = _stripCarrierPrefix(sender);
    final bankName = kSenderIdToBankName[strippedSender];

    if (bankName == null) {
      print('📡 [SmsListenerService] ⚠️ Sender "$strippedSender" not in bank map — ignoring.');
      return;
    }

    final receivedAt = tsMs != null
        ? DateTime.fromMillisecondsSinceEpoch(tsMs)
        : DateTime.now();

    // Hand off with category already known
    await _ref.read(transactionProvider.notifier).handleIncomingSmsWithCategory(
      sender:     sender,
      body:       body,
      bankName:   bankName,
      category:   category,
      receivedAt: receivedAt,
    );
  }

  /// HELPER: Standardizes how we handle an SMS payload (used by both Live and Queued messages)
  Future<void> _routeSmsToTransactionProvider(Map<dynamic, dynamic> args) async {
    final sender = (args['sender'] as String? ?? '').trim();
    final body   = (args['body']   as String? ?? '').trim();
    final tsMs   = args['timestamp'] as int?;

    print('📡 [SmsListenerService] Processing SMS from sender="$sender"');

    final strippedSender = _stripCarrierPrefix(sender);
    final bankName = kSenderIdToBankName[strippedSender];

    if (bankName == null) {
      print('📡 [SmsListenerService] ⚠️ Sender "$strippedSender" not in bank map — ignoring SMS.');
      return;
    }

    final receivedAt = tsMs != null
        ? DateTime.fromMillisecondsSinceEpoch(tsMs)
        : DateTime.now();

    // Hand off to Riverpod
    await _ref.read(transactionProvider.notifier).handleIncomingSms(
      sender:     sender,
      body:       body,
      bankName:   bankName,
      receivedAt: receivedAt,
    );
  }

  /// Fetches the latest balance by checking ALL known sender IDs for the given bank name.
  Future<BalanceResult?> getLatestBalance(String bankName) async {
    print('📡 [SmsListenerService] Starting getLatestBalance for bank: $bankName');

    try {
      // 1. Find all registered Sender IDs for this specific bank
      final senderIds = kBankSenderIds[bankName];

      if (senderIds == null || senderIds.isEmpty) {
        print('📡 [SmsListenerService] ❌ No sender IDs found in constants for: $bankName');
        return null;
      }

      print('📡 [SmsListenerService] Searching across ${senderIds.length} sender IDs: $senderIds');

      // 2. Ask Kotlin to fetch SMS for ALL of these sender IDs simultaneously
      final fetchFutures = senderIds.map((senderId) => _channel.invokeMethod<List<dynamic>>(
        'getSmsFromSender',
        {'sender': senderId, 'limit': 20}, // Limit 20 per ID is enough to find recent ones
      ));

      // Wait for all Kotlin queries to finish
      final resultsList = await Future.wait(fetchFutures);

      // 3. Combine all the fetched messages into a single list
      final List<Map<dynamic, dynamic>> allMessages = [];
      for (final result in resultsList) {
        if (result != null) {
          allMessages.addAll(result.cast<Map<dynamic, dynamic>>());
        }
      }

      print('📡 [SmsListenerService] Total combined messages fetched: ${allMessages.length}');

      if (allMessages.isEmpty) {
        print('📡 [SmsListenerService] ❌ No messages found for any $bankName sender IDs.');
        return null;
      }

      // 4. Sort the combined list by timestamp descending (Newest first)
      allMessages.sort((a, b) {
        final tsA = a['timestamp'] as int? ?? 0;
        final tsB = b['timestamp'] as int? ?? 0;
        return tsB.compareTo(tsA); // Descending order
      });

      // 5. Scan from newest to oldest to find the first valid balance
      for (int i = 0; i < allMessages.length; i++) {
        final msg = allMessages[i];
        final sender = (msg['sender'] as String? ?? '');
        final body   = (msg['body']   as String? ?? '');
        final tsMs   = msg['timestamp'] as int?;

        // Print preview (replacing newlines to keep logs clean)
        final bodyPreview = body.replaceAll('\n', ' ');
        print('📡 [SmsListenerService] --- Checking Message [$i] ---');
        print('📡 [SmsListenerService]   Sender : $sender');
        print('📡 [SmsListenerService]   Body   : ${bodyPreview.length > 60 ? '${bodyPreview.substring(0, 60)}...' : bodyPreview}');

        final balance = _parseBalance(body);

        if (balance != null) {
          print('📡 [SmsListenerService] ✅ Balance found: $balance');

          final smsDate = tsMs != null
              ? DateTime.fromMillisecondsSinceEpoch(tsMs)
              : DateTime.now();

          return BalanceResult(balance: balance, date: smsDate);
        } else {
          print('📡 [SmsListenerService]   ⚠️ No balance pattern matched in this message');
        }
      }

      print('📡 [SmsListenerService] ❌ No balance found in any of the fetched messages');
      return null;

    } catch (e, stack) {
      print('📡 [SmsListenerService] ❌ Exception: $e');
      print('📡 [SmsListenerService] StackTrace: $stack');
      return null;
    }
  }

  String? _parseBalance(String body) {
    final patterns = [
      RegExp(r'Available\s*Bal\s*INR\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'Bal\s*INR\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'Bal[:\s]+INR\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'Balance[:\s]+INR\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'Avl\s*Bal[:\s]+INR\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'INR\s*([\d,]+\.?\d*)\s*Cr', caseSensitive: false),
      RegExp(r'Bal\s*Rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(body);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Strips TRAI carrier prefix from sender ID.
  /// e.g. "VM-PNBSMS" → "PNBSMS", "AX-SBIINB" → "SBIINB"
  /// Keeps plain IDs like "PNBSMS" unchanged.
  String _stripCarrierPrefix(String sender) {
    final prefixPattern = RegExp(r'^[A-Z]{2}-(.+)$');
    final match = prefixPattern.firstMatch(sender.toUpperCase());
    if (match != null) {
      final stripped = match.group(1)!;
      print('📡 [SmsListenerService] Prefix stripped: "$sender" → "$stripped"');
      return stripped;
    }
    return sender.toUpperCase();
  }
}

/// Provider so it can be accessed across the app if needed
final smsListenerServiceProvider = Provider<SmsListenerService>((ref) {
  print('📡 [SmsListenerService] Provider created.');
  return SmsListenerService(ref);
});