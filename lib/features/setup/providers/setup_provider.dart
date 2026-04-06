import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/bank_sender_ids.dart';


class SetupState {
  final bool isSetupComplete;
  final bool isLoading;
  final List<String> selectedBankNames; // e.g. ['Punjab National Bank', 'HDFC Bank']

  SetupState({
    this.isSetupComplete = false,
    this.isLoading = true,
    this.selectedBankNames = const [],
  });

  SetupState copyWith({
    bool? isSetupComplete,
    bool? isLoading,
    List<String>? selectedBankNames,
  }) {
    return SetupState(
      isSetupComplete:   isSetupComplete   ?? this.isSetupComplete,
      isLoading:         isLoading         ?? this.isLoading,
      selectedBankNames: selectedBankNames ?? this.selectedBankNames,
    );
  }

  /// All sender IDs for every selected bank — used by Kotlin receiver
  List<String> get allSelectedSenderIds {
    final ids = <String>[];
    for (final bankName in selectedBankNames) {
      final senderIds = kBankSenderIds[bankName];
      if (senderIds != null) ids.addAll(senderIds);
    }
    return ids;
  }
}

class SetupNotifier extends Notifier<SetupState> {
  static const _keySetupComplete  = 'setup_complete';
  static const _keySelectedBanks  = 'selected_bank_names'; // JSON list

  @override
  SetupState build() {
    print('⚙️ [SetupNotifier] build() called — loading setup status...');
    _loadSetupStatus();
    return SetupState();
  }

  Future<void> _loadSetupStatus() async {
    print('⚙️ [SetupNotifier] Reading SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();

    final isComplete   = prefs.getBool(_keySetupComplete) ?? false;
    final banksJson    = prefs.getString(_keySelectedBanks);
    final selectedBanks = banksJson != null
        ? List<String>.from(jsonDecode(banksJson))
        : <String>[];

    print('⚙️ [SetupNotifier] isSetupComplete=$isComplete');
    print('⚙️ [SetupNotifier] selectedBanks=$selectedBanks');

    state = state.copyWith(
      isSetupComplete:   isComplete,
      isLoading:         false,
      selectedBankNames: selectedBanks,
    );
  }

  Future<void> completeSetup(List<String> selectedBankNames) async {
    print('⚙️ [SetupNotifier] completeSetup() called.');
    print('⚙️ [SetupNotifier] Banks selected: $selectedBankNames');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySetupComplete, true);
    await prefs.setString(_keySelectedBanks, jsonEncode(selectedBankNames));

    // Also persist flattened sender IDs list for the Kotlin receiver to read
    final allSenderIds = <String>[];
    for (final name in selectedBankNames) {
      final ids = kBankSenderIds[name] ?? [];
      allSenderIds.addAll(ids);
    }
    await prefs.setString('selected_sender_ids', jsonEncode(allSenderIds));

    print('⚙️ [SetupNotifier] Sender IDs saved for Kotlin: $allSenderIds');

    state = state.copyWith(
      isSetupComplete:   true,
      isLoading:         false,
      selectedBankNames: selectedBankNames,
    );

    print('⚙️ [SetupNotifier] ✅ Setup complete.');
  }
}

final setupProvider = NotifierProvider<SetupNotifier, SetupState>(
  SetupNotifier.new,
);