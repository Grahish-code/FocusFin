// Animated bar chart with tap tooltip

// lib/features/analysis/widgets/category_bar_graph.dart

import 'package:flutter/material.dart';

import '../../../core/constants/transaction_categories.dart';
import '../../App/app_theme.dart';

class CategoryBarGraph extends StatefulWidget {
  final Map<String, double> data;
  final double total;

  const CategoryBarGraph({
    super.key,
    required this.data,
    required this.total,
  });

  @override
  State<CategoryBarGraph> createState() => _CategoryBarGraphState();
}

class _CategoryBarGraphState extends State<CategoryBarGraph>
    with SingleTickerProviderStateMixin {
  int? _tapped;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final c = context.appColors;
    final sorted = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    // Tooltip
    Widget tooltip = const SizedBox(height: 28);
    if (_tapped != null && _tapped! < sorted.length) {
      final e = sorted[_tapped!];
      final cat = kTransactionCategories
          .where((x) => x.label == e.key)
          .firstOrNull;
      final color = cat?.color ?? c.textMuted;
      tooltip = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(e.key,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textDark)),
          const SizedBox(width: 8),
          Text('₹${e.value.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tooltip row
        SizedBox(height: 28, child: tooltip),
        const SizedBox(height: 12),

        // Bars
        SizedBox(
          height: 130,
          child: AnimatedBuilder(
            animation: CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
            builder: (context, _) {
              final progress = CurvedAnimation(
                  parent: _ctrl, curve: Curves.easeOutCubic)
                  .value;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(sorted.length, (i) {
                  final e = sorted[i];
                  final cat = kTransactionCategories
                      .where((x) => x.label == e.key)
                      .firstOrNull;
                  final color = cat?.color ?? c.textMuted;
                  final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                  final isTapped = _tapped == i;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _tapped = isTapped ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: (ratio * 110 * progress).clamp(4.0, 110.0),
                              decoration: BoxDecoration(
                                color: isTapped
                                    ? color
                                    : color.withOpacity(0.22),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                                border: isTapped
                                    ? Border.all(
                                    color: color.withOpacity(0.5),
                                    width: 1.5)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Icon axis labels
        Row(
          children: List.generate(sorted.length, (i) {
            final cat = kTransactionCategories
                .where((x) => x.label == sorted[i].key)
                .firstOrNull;
            final color = cat?.color ?? c.textMuted;
            final isTapped = _tapped == i;
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _tapped = isTapped ? null : i),
                child: Icon(
                  cat?.icon ?? Icons.category_rounded,
                  size: 14,
                  color: isTapped ? color : c.textMuted.withOpacity(0.4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}