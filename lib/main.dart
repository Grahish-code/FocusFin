import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'features/App/app_theme.dart';
import 'features/App/theme_provider.dart';
import 'features/home_UI/screen/home_screen.dart';
import 'features/screens/login_screen.dart';
import 'features/screens/sign_up_screen.dart';
import 'features/sms/services/sms_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/navigation/screens/main_layout_screen.dart';


/// The engine cache ID must match the one in SmsBroadcastReceiver.kt
const String kFlutterEngineId = 'focusfin_sms_engine';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 [main] WidgetsFlutterBinding initialized.');

  await Firebase.initializeApp();
  print('🚀 [main] Firebase initialized.');

  // Register this engine in the cache so the native BroadcastReceiver
  // can reuse it instead of spinning up a new headless one.
  _cacheFlutterEngine();

  runApp(
    const ProviderScope(
      child: FocusFinApp(),
    ),
  );
}

/// Registers the current Flutter engine in FlutterEngineCache
/// so SmsBroadcastReceiver.kt can find and reuse it.
void _cacheFlutterEngine() {
  // We call into native to register the engine via a MethodChannel
  print('🚀 [main] Registering Flutter engine in native cache (id=$kFlutterEngineId)...');
  const channel = MethodChannel('com.focusfin.sms/engine');
  channel.invokeMethod('cacheEngine', {'engineId': kFlutterEngineId}).then((_) {
    print('🚀 [main] ✅ Engine registered in native cache.');
  }).catchError((e) {
    print('🚀 [main] ⚠️ Engine cache registration failed (may be first launch): $e');
  });
}

class FocusFinApp extends StatelessWidget {
  const FocusFinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _AppWithSmsListener();
  }
}

/// Separate ConsumerWidget so we have access to Riverpod ref to init SMS listener
class _AppWithSmsListener extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppWithSmsListener> createState() => _AppWithSmsListenerState();
}

class _AppWithSmsListenerState extends ConsumerState<_AppWithSmsListener> {
  @override
  void initState() {
    super.initState();
    print('🚀 [_AppWithSmsListener] initState — starting SMS listener...');
    final appReadyFuture = ref.read(authProvider.notifier).waitUntilReady();
    // Initialize the Flutter-side SMS channel listener
    ref.read(smsListenerServiceProvider).initialize(appReadyFuture: appReadyFuture);
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 THEME: 1. Watch the theme mode provider
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'FocusFin',
      debugShowCheckedModeBanner: false,

      // 🎨 THEME: 2. Hook up your custom theme architecture!
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: currentThemeMode,

      home: const AuthRouter(),
      routes: {
        '/login':  (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home':   (context) => const HomeScreen(),
      },
    );
  }
}

/// 🚦 THE TRAFFIC COP: Routes the user based on their Firebase/Local DB auth state.
class AuthRouter extends ConsumerWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 1. App just opened, checking Firebase and Local DB...
    if (authState.isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Colors.white, // Feel free to change to AppColors.bgLight if you want!
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0F172A), // Or AppColors.textDarkL
          ),
        ),
      );
    }

    // 2. Firebase remembered them AND Local DB unlocked successfully!
    if (authState.isAuthenticated) {
      return const MainLayoutScreen();
    }

    // 3. Not logged in (or Local DB key was wiped)
    return const LoginScreen();
  }
}