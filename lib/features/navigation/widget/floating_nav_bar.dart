// lib/features/navigation/widget/floating_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../App/app_theme.dart';
import '../providers/nav_provider.dart';

class FloatingNavBar extends ConsumerWidget {
  const FloatingNavBar({super.key});

  final List<Map<String, dynamic>> navItems = const [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.receipt_long_rounded, 'label': 'History'},
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Budget'},
    {'icon': Icons.analytics_rounded, 'label': 'Analysis'},
    {'icon': Icons.person_rounded, 'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navProvider);
    final currentItem = navItems[navState.selectedIndex];
    final c = context.appColors; // 🎨 Grab dynamic colors

    return AnimatedAlign(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuint,
      alignment: navState.isExpanded ? Alignment.bottomCenter : Alignment.bottomRight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuint,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        height: 64,
        width: navState.isExpanded ? MediaQuery.of(context).size.width : 140,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          // 🎨 THE FIX: Uses inverted theme colors (Dark in Light Mode, Light in Dark Mode)
          color: c.textDark,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: c.textDark.withOpacity(0.25), // Dynamic shadow
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: navState.isExpanded
              ? _buildExpanded(context, ref, c)
              : _buildMinimized(context, ref, currentItem, c),
        ),
      ),
    );
  }

  // ─── EXPANDED STATE (Full Bar) ───
  Widget _buildExpanded(BuildContext context, WidgetRef ref, AppColorScheme c) {
    final navState = ref.watch(navProvider);

    return SingleChildScrollView(
      key: const ValueKey('expanded'),
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(navItems.length, (index) {
            final isSelected = navState.selectedIndex == index;
            final item = navItems[index];

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(navProvider.notifier).setIndex(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  // Uses the app's background color for high-contrast selection bubbles
                  color: isSelected ? c.bg.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item['icon'],
                  // High contrast for selected, faded for unselected
                  color: isSelected ? c.bg : c.bg.withOpacity(0.4),
                  size: 26,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── MINIMIZED STATE (Corner Pill) ───
  Widget _buildMinimized(
      BuildContext context, WidgetRef ref, Map<String, dynamic> currentItem, AppColorScheme c) {

    return SingleChildScrollView(
      key: const ValueKey('minimized'),
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(navProvider.notifier).toggleExpanded(),
        child: SizedBox(
          width: 140,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(currentItem['icon'], color: c.bg, size: 24), // High contrast icon
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentItem['label'],
                    style: TextStyle(
                      color: c.bg, // High contrast text
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                  ),
                ),
                Icon(Icons.keyboard_arrow_left_rounded, color: c.bg.withOpacity(0.6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}