import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bank_sender_ids.dart';
import '../../auth/providers/biometric_provider.dart';
import '../providers/setup_provider.dart';
// 1. IMPORT THE BIOMETRIC PROVIDER


class SetupBottomSheet extends ConsumerStatefulWidget {
  const SetupBottomSheet({super.key});

  @override
  ConsumerState<SetupBottomSheet> createState() => _SetupBottomSheetState();
}

class _SetupBottomSheetState extends ConsumerState<SetupBottomSheet> with WidgetsBindingObserver {
  bool _notificationPermissionGranted = false;
  final Set<String> _selectedBanks = {};

  final Color primaryColor = const Color(0xFF0F172A);
  final Color accentColor  = const Color(0xFF3B82F6);
  final Color surfaceColor = const Color(0xFFF8FAFC);

  final List<String> _allBanks = kBankSenderIds.keys.toList();

  // ─── METHOD CHANNEL ───
  static const _methodChannel = MethodChannel('com.focusfin/settings');

  Future<void> _openNotificationSettings() async {
    try {
      await _methodChannel.invokeMethod('openSettings');
    } catch (e) {
      print("⚠️ Failed to open settings: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final bool isGranted = await _methodChannel.invokeMethod('checkPermission');
      setState(() {
        _notificationPermissionGranted = isGranted;
      });
    } catch (e) {
      print("⚠️ Failed to check permission: $e");
    }
  }

  void _handleSubmit() async {
    if (!_notificationPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Our app can't work without notification access"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedBanks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one bank'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Notice we don't check for biometrics here! It's 100% optional.
    await ref.read(setupProvider.notifier).completeSetup(_selectedBanks.toList());

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // 2. WATCH THE REAL BIOMETRIC STATE
    final isBiometricEnabled = ref.watch(biometricProvider);

    return Container(
      height: screenHeight * 0.85,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Quick Setup",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: primaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select the banks you use. We'll track only those.",
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),

          // ─── 1. NOTIFICATION PERMISSION CARD (Required) ───
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _notificationPermissionGranted ? Colors.green.shade50 : surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _notificationPermissionGranted ? Colors.green.shade200 : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _notificationPermissionGranted ? Colors.green.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _notificationPermissionGranted ? Icons.check_circle_rounded : Icons.notifications_active_outlined,
                    color: _notificationPermissionGranted ? Colors.green.shade700 : primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notification Access",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _notificationPermissionGranted ? Colors.green.shade800 : primaryColor,
                        ),
                      ),
                      Text(
                        _notificationPermissionGranted ? "Access Granted" : "Required to read bank alerts",
                        style: TextStyle(
                          fontSize: 13,
                          color: _notificationPermissionGranted ? Colors.green.shade600 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _notificationPermissionGranted ? () {} : _openNotificationSettings,
                  style: TextButton.styleFrom(
                    backgroundColor: _notificationPermissionGranted ? Colors.green.shade600 : primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                      _notificationPermissionGranted ? "Allowed" : "Allow",
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── 2. OPTIONAL BIOMETRIC CARD ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fingerprint_rounded, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "App Lock (Optional)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        "Require Fingerprint to view balance",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // 3. ACTUAL SWITCH LOGIC ENABLED
                Switch.adaptive(
                  value: isBiometricEnabled,
                  activeColor: accentColor,
                  onChanged: (val) async {
                    final success = await ref.read(biometricProvider.notifier).toggleBiometric(val);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Authentication failed or fingerprint not found."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            "Select Your Banks",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _allBanks.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final bank = _allBanks[index];
                    final isSelected = _selectedBanks.contains(bank);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedBanks.remove(bank);
                            } else {
                              _selectedBanks.add(bank);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          color: isSelected ? accentColor.withOpacity(0.08) : Colors.transparent,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? accentColor : Colors.grey.shade400,
                                    width: isSelected ? 6 : 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  bank,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? primaryColor : Colors.grey.shade700,
                                  ),
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
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Complete Setup",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}