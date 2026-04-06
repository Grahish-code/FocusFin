// lib/features/navigation/screens/main_layout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Profile_UI/screen/profile_screen.dart';
import '../../analysis_UI/screens/analysis_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../budget_UI/screen/budgets_screen.dart';
import '../../setup/providers/setup_provider.dart';
import '../../setup/widgets/setup_bottom_sheet.dart';
import '../../transaction_UI/screen/transactions_screen.dart';
import '../providers/nav_provider.dart';
import '../widget/floating_nav_bar.dart';
import '../../home_UI/screen/home_screen.dart';

// 🎨 THEME: Import your theme file to access context.appColors
import '../../App/app_theme.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  DateTime? currentBackPressTime;

  final List<String> _pageTitles = [
    "FocusFin",
    "Transactions",
    "Budgets",
    "Analysis",
    "My Profile",
  ];

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);
    final navState = ref.watch(navProvider);

    // 🎨 THEME: Grab the dynamic color scheme
    final c = context.appColors;

    if (!setupState.isLoading && !setupState.isSetupComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: c.surface, // Dynamic surface
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => const SetupBottomSheet(),
        );
      });
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final now = DateTime.now();
        if (currentBackPressTime == null ||
            now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
          currentBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Press back again to exit',
                style: TextStyle(color: c.bg, fontWeight: FontWeight.w600), // Inverted for contrast
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: c.textDark, // Inverted for contrast
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: c.bg, // Dynamic background
        appBar: AppBar(
          backgroundColor: c.bg, // Blends seamlessly with body in both modes
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _pageTitles[navState.selectedIndex],
            style: TextStyle(
              color: c.textDark, // Dynamic text
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: c.textDark),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  enableDrag: true,
                  backgroundColor: c.surface, // Dynamic surface
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  builder: (_) => const SetupBottomSheet(),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout, color: c.textDark),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),

        // ─── THE MAGIC STACK ───
        body: Stack(
          children: [
            // 1. The Pages
            IndexedStack(
              index: navState.selectedIndex,
              children: const [
                HomeScreen(),
                TransactionsScreen(),
                BudgetsScreen(),
                AnalysisScreen(),
                ProfileScreen()
              ],
            ),

            // 2. The Floating Nav Bar Overlay Shield
            if (navState.isExpanded)
              GestureDetector(
                onTap: () => ref.read(navProvider.notifier).toggleExpanded(),
                child: Container(color: Colors.transparent),
              ),

            const FloatingNavBar(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PLACEHOLDER VIEW
// ═══════════════════════════════════════════════════════════════
class _PlaceholderView extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderView({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors; // Dynamic theme for placeholder

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            child: Icon(icon, size: 64, color: c.textMuted.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.textDark.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Coming Soon",
              style: TextStyle(
                color: c.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}