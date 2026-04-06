// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for Notification MethodChannel
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';
import '../../App/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/biometric_provider.dart';
import '../../setup/providers/setup_provider.dart';



// ═══════════════════════════════════════════════════════════════
//  MAIN PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName != null && user!.displayName!.isNotEmpty ? user.displayName! : "User";
    final String email = user?.email ?? "No email linked";
    final String initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    final c = context.appColors; // <-- Dynamic colors

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            // ─── HEADER ───
            _ProfileHeader(displayName: displayName, email: email, initials: initials),
            const SizedBox(height: 32),

            // ─── ACCOUNT SECTION ───
            const AppSectionLabel(title: "Account"),
            const SizedBox(height: 12),
            AppGlassCard(
              padding: EdgeInsets.zero,
              radius: AppRadius.lg,
              child: Column(
                children: [
                  AppProfileTile(
                    icon: Icons.person_outline_rounded,
                    label: "Personal Information",
                    onTap: () => _showBottomSheet(context, const _PersonalInfoSheet()),
                  ),
                  const AppTileDivider(),
                  AppProfileTile(
                    icon: Icons.shield_outlined,
                    label: "Security & Passwords",
                    onTap: () => _showBottomSheet(context, const _SecuritySheet()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ─── PREFERENCES SECTION ───
            const AppSectionLabel(title: "Preferences"),
            const SizedBox(height: 12),
            AppGlassCard(
              padding: EdgeInsets.zero,
              radius: AppRadius.lg,
              child: Column(
                children: [
                  AppProfileTile(
                    icon: Icons.currency_rupee_rounded,
                    label: "Currency",
                    trailingText: "INR (₹)",
                    onTap: () => _showBottomSheet(context, const _CurrencySheet()),
                  ),
                  const AppTileDivider(),
                  AppProfileTile(
                    icon: Icons.notifications_none_rounded,
                    label: "Notifications",
                    onTap: () => _showBottomSheet(context, const _NotificationSheet()),
                  ),
                  const AppTileDivider(),

                  // ─── THEME TOGGLE ROW ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: c.surface2,
                              borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                              border: Border.all(color: c.border),
                            ),
                            child: Icon(Icons.dark_mode_outlined, color: c.textMuted, size: 18)
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text("Appearance",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textDark)),
                        ),
                        // The interactive toggle replaces the trailing text/arrow
                        const AppThemeToggle(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ─── DATA & SUPPORT SECTION ───
            const AppSectionLabel(title: "Data & Support"),
            const SizedBox(height: 12),
            AppGlassCard(
              padding: EdgeInsets.zero,
              radius: AppRadius.lg,
              child: Column(
                children: [
                  AppProfileTile(
                    icon: Icons.file_download_outlined,
                    label: "Export Data",
                    onTap: () => _showBottomSheet(context, const AppComingSoonSheet(title: "Export Data")),
                  ),
                  const AppTileDivider(),
                  AppProfileTile(
                    icon: Icons.help_outline_rounded,
                    label: "Help Center",
                    onTap: () => _showBottomSheet(context, const AppComingSoonSheet(title: "Help Center")),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ─── LOGOUT BUTTON ───
            ElevatedButton(
              onPressed: () => _showLogoutConfirm(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.rose.withOpacity(c.isDark ? 0.1 : 0.08),
                foregroundColor: c.rose,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: c.rose.withOpacity(0.3)),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 20),
                  SizedBox(width: 8),
                  Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                "FocusFin v1.0.0",
                style: TextStyle(
                  color: c.textMuted.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Sheet Helper Function
  void _showBottomSheet(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => child,
    );
  }

  // Logout Dialog
  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (ctx, anim1, anim2) {
        return StatefulBuilder(
            builder: (context, setState) {
              final c = context.appColors; // Dynamic color inside dialog

              return ScaleTransition(
                scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
                child: FadeTransition(
                  opacity: anim1,
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: AppGlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppCircleIcon(
                            icon: Icons.logout_rounded,
                            color: c.rose,
                            size: 32,
                            padding: 16,
                            opacity: 0.15,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Log Out?",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textDark, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Are you sure you want to securely log out of your account?",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textMuted, height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                  ),
                                  child: Text("Cancel", style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await ref.read(authProvider.notifier).logout();
                                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.rose,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                  ),
                                  child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOTTOM SHEETS
// ═══════════════════════════════════════════════════════════════

// ─── 1. PERSONAL INFO SHEET ───
class _PersonalInfoSheet extends ConsumerWidget {
  const _PersonalInfoSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final setupState = ref.watch(setupProvider);
    final c = context.appColors;

    return AppGlassSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Personal Information", style: AppTextStyles.sectionHeading.copyWith(color: c.textDark)),
          const SizedBox(height: 24),

          AppInfoField(label: "Full Name", value: user?.displayName ?? "Not provided"),
          const SizedBox(height: 16),
          AppInfoField(label: "Email Address", value: user?.email ?? "Not provided"),
          const SizedBox(height: 24),

          const AppSectionLabel(title: "TRACKED BANKS", padding: EdgeInsets.zero),
          const SizedBox(height: 12),
          if (setupState.selectedBankNames.isEmpty)
            Text("No banks currently tracked.", style: TextStyle(color: c.textDark, fontWeight: FontWeight.w500))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: setupState.selectedBankNames.map((bank) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(bank, style: TextStyle(fontWeight: FontWeight.w600, color: c.textDark)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── 2. SECURITY & PASSWORDS SHEET ───
class _SecuritySheet extends ConsumerWidget {
  const _SecuritySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBiometricEnabled = ref.watch(biometricProvider);
    final c = context.appColors;

    return AppGlassSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppCircleIcon(
            icon: Icons.fingerprint_rounded,
            color: c.emerald,
            size: 36,
            padding: 16,
            opacity: 0.15,
          ),
          const SizedBox(height: 20),
          Text("App Lock Security", style: AppTextStyles.sectionHeading.copyWith(color: c.textDark)),
          const SizedBox(height: 8),
          Text(
            "Secure your balance and transactions using your device's native fingerprint or face scanner.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textMuted, height: 1.4),
          ),
          const SizedBox(height: 32),

          if (isBiometricEnabled) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.emerald.withOpacity(0.05),
                border: Border.all(color: c.emerald.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: c.emerald, size: 18),
                  const SizedBox(width: 8),
                  Text("App Lock is Active", style: TextStyle(color: c.emerald, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await ref.read(biometricProvider.notifier).toggleBiometric(false);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.rose.withOpacity(0.1),
                foregroundColor: c.rose,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text("Remove Fingerprint Lock", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () async {
                final success = await ref.read(biometricProvider.notifier).toggleBiometric(true);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Failed to set up Fingerprint."), backgroundColor: c.rose));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textDark,
                foregroundColor: c.bg,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text("Set Up Fingerprint Lock", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 3. CURRENCY SHEET ───
class _CurrencySheet extends StatelessWidget {
  const _CurrencySheet();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppGlassSheet(
      child: Column(
        children: [
          AppCircleIcon(
            icon: Icons.currency_rupee_rounded,
            color: c.amber,
            size: 36,
            padding: 16,
            opacity: 0.15,
          ),
          const SizedBox(height: 20),
          Text("Currency Preferences", style: AppTextStyles.sectionHeading.copyWith(color: c.textDark)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: c.border),
            ),
            child: Text(
              "We currently only support tracking finances in India (INR ₹). Support for multiple currencies will be available in a future update!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textDark, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── 4. NOTIFICATIONS SHEET ───
class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();
  static const _methodChannel = MethodChannel('com.focusfin/settings');

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppGlassSheet(
      child: Column(
        children: [
          AppCircleIcon(
            icon: Icons.notifications_active_outlined,
            color: c.textDark,
            size: 36,
            padding: 16,
            opacity: c.isDark ? 0.1 : 0.05,
          ),
          const SizedBox(height: 20),
          Text("Notification Access", style: AppTextStyles.sectionHeading.copyWith(color: c.textDark)),
          const SizedBox(height: 12),
          Text(
            "FocusFin relies on reading your bank SMS alerts securely in the background to build your dashboard.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textMuted, height: 1.4),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () async {
              try {
                await _methodChannel.invokeMethod('openSettings');
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                // Ignore error silently
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: c.textDark,
              foregroundColor: c.bg,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text("Open Device Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  UI COMPONENTS
// ═══════════════════════════════════════════════════════════════
class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String initials;

  const _ProfileHeader({required this.displayName, required this.email, required this.initials});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Column(
      children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: c.textDark,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: c.textDark.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: c.bg),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(displayName, style: AppTextStyles.screenTitle.copyWith(fontSize: 24, color: c.textDark)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: c.glassFill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: c.glassBorder),
          ),
          child: Text(email, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted)),
        ),
      ],
    );
  }
}