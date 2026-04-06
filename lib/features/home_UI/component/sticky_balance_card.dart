import 'package:FocusFin/features/App/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../App/app_widgets.dart';
import '../../auth/providers/biometric_provider.dart';
import '../../sms/providers/balance_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../provider/home_ui_provider.dart';

// ═══════════════════════════════════════════════════════════════
//  STICKY BALANCE HEADER DELEGATE
// ═══════════════════════════════════════════════════════════════
class StickyBalanceHeaderDelegate extends SliverPersistentHeaderDelegate {
  final WidgetRef ref;
  final dynamic balanceState;
  final bool isVisible;
  final bool isBiometricEnabled;
  final bool isDarkMode; // <-- ADDED THIS!

  StickyBalanceHeaderDelegate(
      this.ref,
      this.balanceState,
      this.isVisible,
      this.isBiometricEnabled,
      this.isDarkMode, // <-- ADDED THIS!
      );

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.appColors;

    return Container(
      color: c.bg, // Keeps the area around the card dynamic
      padding: const EdgeInsets.only(top: 20, bottom: 12, left: 24, right: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          // 🎨 gradient switches instantly now because isDarkMode is passed in
          gradient: isDarkMode
              ? const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)], // Dark Mode: Purple
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFF2B2B2B), Color(0xFF000000)], // Light Mode: Black Diamond
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: isDarkMode ? AppShadows.primaryGlow : AppShadows.elevatedLight,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: AppGradients.glassShimmer,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "CURRENT\nBALANCE",
                        style: AppTextStyles.sectionLabel.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 24, // <-- Add this to bump up the size (adjust as needed)
                          letterSpacing: 1.1,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () {
                            if (isVisible) {
                              ref.read(balanceProvider.notifier).fetchBalance();
                              ref.read(transactionProvider.notifier).fetchTransactions();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                Icons.refresh_rounded,
                                color: isVisible ? Colors.white : Colors.white54,
                                size: 16
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  if (balanceState.isLoading && isVisible)
                    const CircularProgressIndicator(color: Colors.white)
                  else if (balanceState.error != null && isVisible)
                    Text(balanceState.error!,
                        style: const TextStyle(
                            color: AppColors.rose, fontSize: 16, fontWeight: FontWeight.w500))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (!isVisible) {
                              bool unlocked = false;

                              if (isBiometricEnabled) {
                                unlocked = await ref.read(biometricProvider.notifier)
                                    .requireAuth(reason: 'Scan fingerprint to view balance');
                              }

                              if (!unlocked) {
                                final passResult = await _showPasswordDialog(context, ref);
                                unlocked = passResult == true;
                              }

                              if (unlocked) {
                                ref.read(balanceVisibilityProvider.notifier).unlock();
                                ref.read(balanceProvider.notifier).fetchBalance();
                                ref.read(transactionProvider.notifier).fetchTransactions();
                              }
                            } else {
                              ref.read(balanceVisibilityProvider.notifier).lock();
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isVisible
                                        ? (balanceState.balance != null ? '₹${balanceState.balance}' : '₹0.00')
                                        : '✦ ✦ ✦ ✦ ✦',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isVisible ? 34 : 24,
                                      fontWeight: isVisible ? FontWeight.w700 : FontWeight.w600,
                                      letterSpacing: isVisible ? -0.5 : 4.0,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                isVisible
                                    ? Icons.lock_open_rounded
                                    : (isBiometricEnabled ? Icons.fingerprint_rounded : Icons.lock_outline_rounded),
                                color: Colors.white70,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isVisible && balanceState.dateFormatted != null
                                ? 'Updated ${balanceState.dateFormatted}'
                                : (isVisible ? 'No recent transactions' : 'Tap to unlock your balance'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 230.0;

  @override
  double get minExtent => 230.0;

  @override
  bool shouldRebuild(covariant StickyBalanceHeaderDelegate oldDelegate) {
    // 🎨 THE FIX: Now it knows to rebuild if the theme changes!
    return oldDelegate.balanceState != balanceState ||
        oldDelegate.isVisible != isVisible ||
        oldDelegate.isBiometricEnabled != isBiometricEnabled ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

// ═══════════════════════════════════════════════════════════════
//  PASSWORD UNLOCK DIALOG
// ═══════════════════════════════════════════════════════════════
Future<bool?> _showPasswordDialog(BuildContext context, WidgetRef ref) async {
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  return await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    pageBuilder: (ctx, anim1, anim2) {
      return StatefulBuilder(
          builder: (context, setState) {
            final c = context.appColors;

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
                          icon: Icons.lock_outline_rounded,
                          color: c.textDark,
                          size: 32,
                          padding: 16,
                          opacity: c.isDark ? 0.1 : 0.05,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Unlock Balance",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textDark, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter your account password to reveal your balance.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: errorMessage != null ? c.rose : c.border),
                          ),
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            autofocus: true,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textDark),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Password",
                              hintStyle: TextStyle(color: c.textMuted.withOpacity(0.4)),
                            ),
                          ),
                        ),

                        if (errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(errorMessage!, style: TextStyle(color: c.rose, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],

                        const SizedBox(height: 28),

                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: isLoading ? null : () => Navigator.pop(ctx, false),
                                child: Text("Cancel", style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: AppGradientButton(
                                  label: 'Unlock',
                                  isLoading: isLoading,
                                  onPressed: () async {
                                    final password = passwordController.text.trim();
                                    if (password.isEmpty) return;

                                    setState(() {
                                      isLoading = true;
                                      errorMessage = null;
                                    });

                                    final success = await ref.read(balanceVisibilityProvider.notifier).verifyPassword(password);

                                    if (success) {
                                      if (ctx.mounted) Navigator.pop(ctx, true);
                                    } else {
                                      setState(() {
                                        isLoading = false;
                                        errorMessage = "Incorrect password";
                                      });
                                    }
                                  },
                                )
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