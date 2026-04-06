// lib/features/analysis/widgets/ribbon_row.dart

import 'package:flutter/material.dart';

import '../../../core/constants/transaction_categories.dart';
import '../../App/app_theme.dart';
import '../../App/app_widgets.dart';

class RibbonRow extends StatefulWidget {
  final int index;
  final MapEntry<String, double> entry;
  final double total;
  final bool isLast;

  const RibbonRow({
    super.key,
    required this.index,
    required this.entry,
    required this.total,
    required this.isLast,
  });

  @override
  State<RibbonRow> createState() => _RibbonRowState();
}

class _RibbonRowState extends State<RibbonRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final cat = kTransactionCategories
        .where((x) => x.label == widget.entry.key)
        .firstOrNull;
    final color = cat?.color ?? c.textMuted;
    final icon  = cat?.icon  ?? Icons.category_rounded;
    final ratio = widget.total > 0 ? widget.entry.value / widget.total : 0.0;
    final rank  = widget.index + 1;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
            offset: Offset(_slide.value, 0), child: child),
      ),
      child: Padding(
        // ── Row gap: 10px between each card, none after last ──
        padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Rank badge + connector line ────────────────────
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isLast)
                    Container(
                      width: 1.5,
                      height: 42, // tightened to match the 10px row gap
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Card ───────────────────────────────────────────
            Expanded(
              child: AppGlassCard(
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppCircleIcon(
                          icon: icon,
                          color: color,
                          size: 16,
                          padding: 8,
                          shape: BoxShape.rectangle,
                          borderRadius:
                          BorderRadius.circular(AppRadius.xs + 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '₹${widget.entry.value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(ratio * 100).toStringAsFixed(1)}% of total',
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 10, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}