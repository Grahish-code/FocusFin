// lib/features/screens/login_screen.dart

import 'package:FocusFin/features/App/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../App/app_widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/providers/biometric_provider.dart';
// Ensure this import points to your actual MainLayoutScreen
import '../navigation/screens/main_layout_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController          = TextEditingController();
  final _pinController            = TextEditingController();
  final _masterPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() => setState(() {}));

    // Auto-prompt fingerprint when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricLogin();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    _masterPasswordController.dispose();
    super.dispose();
  }

  // ── Biometric Login ───────────────────────────────────────────────
  Future<void> _tryBiometricLogin() async {
    final isBiometricEnabled = ref.read(biometricProvider);
    if (!isBiometricEnabled) return;

    final passed = await ref
        .read(biometricProvider.notifier)
        .requireAuth(reason: 'Scan fingerprint to log in to FocusFin');

    if (passed && mounted) {
      await ref.read(authProvider.notifier).loginWithSavedCredentials();
    }
  }

  // ── Manual Login ──────────────────────────────────────────────────
  String? _validate(bool needsMasterPassword) {
    if (_emailController.text.trim().isEmpty) return 'Please enter your email';
    if (_pinController.text.length != 6)      return 'PIN must be exactly 6 digits';
    if (needsMasterPassword && _masterPasswordController.text.trim().isEmpty) {
      return 'Please enter your master password';
    }
    return null;
  }

  void _handleLogin() async {
    ref.read(authProvider.notifier).clearError();
    final authState       = ref.read(authProvider);
    final validationError = _validate(authState.needsMasterPassword);

    if (validationError != null) {
      ref.read(authProvider.notifier).setError(validationError);
      return;
    }

    if (authState.needsMasterPassword) {
      await ref.read(authProvider.notifier).loginWithMasterPassword(
        _emailController.text,
        _pinController.text,
        _masterPasswordController.text,
      );
    } else {
      await ref.read(authProvider.notifier).login(
        _emailController.text,
        _pinController.text,
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────
  InputDecoration _buildInputDecoration(String label, IconData icon, AppColorScheme c) {
    return InputDecoration(
      labelText:   label,
      labelStyle:  TextStyle(color: c.textMuted),
      prefixIcon:  Icon(icon, color: c.textMuted),
      filled:      true,
      fillColor:   c.surface2, // Upgraded to dynamic surface
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:   BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:   BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:   BorderSide(color: c.textDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }

  Widget _buildPinBoxes(AppColorScheme c) {
    final pinLength = _pinController.text.length;

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: List.generate(11, (index) {
            if (index % 2 != 0) return const SizedBox(width: 8);
            final pinIndex  = index ~/ 2;
            final isFocused = pinLength == pinIndex;
            final hasData   = pinLength > pinIndex;

            return Expanded(
              child: AspectRatio(
                aspectRatio: 0.85,
                child: Container(
                  decoration: BoxDecoration(
                    color:        c.surface2, // Upgraded to dynamic surface
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused ? c.textDark : c.border,
                      width: isFocused ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasData ? '●' : '',
                    style: TextStyle(fontSize: 24, color: c.textDark),
                  ),
                ),
              ),
            );
          }),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.0,
            child: TextField(
              controller:       _pinController,
              autofocus:        false,
              keyboardType:     TextInputType.number,
              cursorColor:      Colors.transparent,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style:      const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
              onSubmitted: (_) => _handleLogin(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = context.appColors; // 🎨 Grab dynamic colors

    // ✅ THE ACTUAL FIX: Listen to authProvider and push to MainLayoutScreen!
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
              (route) => false, // Clears the stack so they can't swipe back to login
        );
      }
    });

    final authState          = ref.watch(authProvider);
    final isBiometricEnabled = ref.watch(biometricProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 80),

                      Text(
                        "FocusFin",
                        style: TextStyle(
                          fontSize:      48,
                          fontWeight:    FontWeight.w900,
                          color:         c.textDark,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Bring your finances into focus.",
                        style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w500,
                          color:      c.textMuted,
                        ),
                      ),

                      const SizedBox(height: 60),

                      TextField(
                        controller:      _emailController,
                        keyboardType:    TextInputType.emailAddress,
                        style:           TextStyle(color: c.textDark, fontWeight: FontWeight.w600),
                        decoration:      _buildInputDecoration("Email Address", Icons.email_outlined, c),
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "Secure PIN",
                        style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      c.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildPinBoxes(c),

                      if (authState.needsMasterPassword) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:        c.surface2,
                            borderRadius: BorderRadius.circular(16),
                            border:       Border.all(color: c.rose.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.key_rounded, color: c.textDark),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Local key lost. Enter your master password to restore access.',
                                  style: TextStyle(fontSize: 13, color: c.textDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller:  _masterPasswordController,
                          obscureText: true,
                          style:       TextStyle(color: c.textDark, fontWeight: FontWeight.w600),
                          decoration:  _buildInputDecoration("Master Password", Icons.shield_outlined, c),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                      ],

                      const SizedBox(height: 32),

                      if (authState.errorMessage != null)
                        Container(
                          margin:  const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color:        c.rose.withOpacity(c.isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border:       Border.all(color: c.rose.withOpacity(0.3)),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: TextStyle(
                              color:      c.rose,
                              fontSize:   14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const Spacer(),

                      // ── Fingerprint Button (only when enabled) ──
                      if (isBiometricEnabled)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutlinedButton.icon(
                            onPressed: authState.isLoading ? null : _tryBiometricLogin,
                            icon:  Icon(Icons.fingerprint, size: 28, color: c.textDark),
                            label: Text(
                              "Login with Fingerprint",
                              style: TextStyle(
                                color:      c.textDark,
                                fontSize:   16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side:    BorderSide(color: c.border, width: 1.5),
                              shape:   RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: c.surface,
                            ),
                          ),
                        ),

                      // ── Primary Login Button ──
                      AppGradientButton(
                        label: authState.needsMasterPassword ? "Restore Access" : "Login",
                        isLoading: authState.isLoading,
                        onPressed: _handleLogin,
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        style: TextButton.styleFrom(
                          padding:       const EdgeInsets.symmetric(vertical: 16),
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: RichText(
                          text: TextSpan(
                            text:  "Don't have an account? ",
                            style: TextStyle(color: c.textMuted, fontSize: 15),
                            children: [
                              TextSpan(
                                text:  "Sign up",
                                style: TextStyle(
                                  color:      c.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}