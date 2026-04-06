//The 1M / 3M / 6M / 1Y pill switcher

// lib/features/analysis/widgets/range_toggle.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../App/app_theme.dart';
import '../providers/analysis_provider.dart';

class RangeToggle extends ConsumerWidget {
  final AnalysisRange current;
  const RangeToggle({super.key, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;

    const options = [
      (AnalysisRange.month1, '1M'),
      (AnalysisRange.month3, '3M'),
      (AnalysisRange.month6, '6M'),
      (AnalysisRange.year1,  '1Y'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.glassFill,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: c.glassBorder, width: 1),
            boxShadow: context.glassShadow,
          ),
          child: Row(
            children: options.map((opt) {
              final selected = current == opt.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref
                      .read(analysisProvider.notifier)
                      .setRange(opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? c.textDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      opt.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? c.bg : c.textMuted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}