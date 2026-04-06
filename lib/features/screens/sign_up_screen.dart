import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers/auth_provider.dart';

// Your custom theme palette
class _C {
  static const bg            = Color(0xFFF4F3EF);
  static const textDark      = Color(0xFF111111);
  static const textMuted     = Color(0xFF888888);
  static const emerald       = Color(0xFF10B981);
  static const rose          = Color(0xFFEF4444);
  static const border        = Color(0xFFE5E3DD);
  static const gradientStart = Color(0xFF2B2B2B);
  static const gradientEnd   = Color(0xFF000000);
  static const glassFill     = Color(0xB8E8E6E0);
  static const glassBorder   = Color(0xFFD0CEC8);
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  final _emailController = TextEditingController();
  final _masterPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild the UI whenever the PIN changes to update the 6 boxes
    _pinController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _emailController.dispose();
    _masterPasswordController.dispose();
    super.dispose();
  }

  // Validates before calling Firebase
  String? _validate() {
    if (_usernameController.text.trim().isEmpty) {
      return 'Please enter a username';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (_pinController.text.length != 6) {
      return 'PIN must be exactly 6 digits';
    }
    if (_masterPasswordController.text.length < 6) {
      return 'Master password must be at least 6 characters';
    }
    return null;
  }

  void _handleSignUp() async {
    // Clear any existing error first
    ref.read(authProvider.notifier).clearError();

    // Local validation before hitting Firebase
    final validationError = _validate();
    if (validationError != null) {
      ref.read(authProvider.notifier).setError(validationError);
      return;
    }

    final success = await ref.read(authProvider.notifier).signUp(
      _usernameController.text,
      _pinController.text,
      _emailController.text,
      _masterPasswordController.text,
    );

    // Note: If signUp is successful, your AuthRouter should handle the navigation,
    // assuming you set isAuthenticated to true inside the signUp provider method.
    if (success && mounted) {
      // Optional: pop the signup screen to let the AuthRouter route to MainLayout
      Navigator.of(context).pop();
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textMuted),
      prefixIcon: Icon(icon, color: _C.textMuted),
      filled: true,
      fillColor: _C.glassFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _C.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _C.textDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }

  // Fully Responsive 6-Box PIN Widget matching the LoginScreen
  Widget _buildPinBoxes() {
    final pinLength = _pinController.text.length;

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: List.generate(11, (index) {
            if (index % 2 != 0) return const SizedBox(width: 8);

            final pinIndex = index ~/ 2;
            final isFocused = pinLength == pinIndex;
            final hasData = pinLength > pinIndex;

            return Expanded(
              child: AspectRatio(
                aspectRatio: 0.85,
                child: Container(
                  decoration: BoxDecoration(
                    color: _C.glassFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused ? _C.textDark : _C.border,
                      width: isFocused ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasData ? '●' : '',
                    style: const TextStyle(
                      fontSize: 24,
                      color: _C.textDark,
                    ),
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
              controller: _pinController,
              autofocus: false,
              keyboardType: TextInputType.number,
              cursorColor: Colors.transparent,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
              onSubmitted: (_) => _handleSignUp(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // Custom Back Button to maintain the clean full-screen look
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _C.glassFill,
                              border: Border.all(color: _C.border),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.textDark, size: 20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: _C.textDark,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Secure your finances with FocusFin.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _C.textMuted,
                        ),
                      ),

                      const SizedBox(height: 48),

                      TextField(
                        controller: _usernameController,
                        decoration: _buildInputDecoration("Username", Icons.person_outline_rounded),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration("Email Address", Icons.email_outlined),
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        "6-Digit Secure PIN",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildPinBoxes(),

                      const SizedBox(height: 24),

                      TextField(
                        controller: _masterPasswordController,
                        obscureText: true,
                        decoration: _buildInputDecoration("Master Password", Icons.shield_outlined),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleSignUp(),
                      ),

                      const SizedBox(height: 32),

                      if (authState.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _C.rose.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _C.rose.withOpacity(0.3)),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: _C.rose, fontSize: 14, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const Spacer(),

                      // Premium Gradient Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [_C.gradientStart, _C.gradientEnd],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _C.textDark.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text(
                            "Create Account",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
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