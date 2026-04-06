// lib/features/analysis/widgets/spending_trend_chart.dart

import 'package:flutter/material.dart';

import '../../App/app_theme.dart';

// ─── Data model ───────────────────────────────────────────────
class ChartPoint {
  final String label;
  final double value;
  const ChartPoint({required this.label, required this.value});
}

// ─── Mode enum ────────────────────────────────────────────────
enum TrendMode { weekly, monthly }

// ═══════════════════════════════════════════════════════════════
//  SPENDING TREND CHART
// ═══════════════════════════════════════════════════════════════
class SpendingTrendChart extends StatefulWidget {
  final Map<String, double> spendingByDay;
  const SpendingTrendChart({super.key, required this.spendingByDay});

  @override
  State<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends State<SpendingTrendChart>
    with SingleTickerProviderStateMixin {
  TrendMode _mode = TrendMode.monthly;
  int? _touchedIndex;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _switchMode(TrendMode m) {
    if (_mode == m) return;
    setState(() {
      _mode = m;
      _touchedIndex = null;
    });
    _anim.forward(from: 0);
  }

  List<ChartPoint> _weeklyPoints() {
    final now = DateTime.now();
    const weeks = 8;
    final buckets = List<double>.filled(weeks, 0);
    for (final e in widget.spendingByDay.entries) {
      final d = DateTime.tryParse(e.key);
      if (d == null) continue;
      final diff = now.difference(d).inDays;
      final bucket = (diff / 7).floor();
      if (bucket >= 0 && bucket < weeks) {
        buckets[weeks - 1 - bucket] += e.value;
      }
    }
    return List.generate(
        weeks, (i) => ChartPoint(label: 'W${i + 1}', value: buckets[i]));
  }

  List<ChartPoint> _monthlyPoints() {
    final now = DateTime.now();
    const months = 6;
    final buckets = List<double>.filled(months, 0);
    final labels = <String>[];
    for (var m = months - 1; m >= 0; m--) {
      var month = now.month - m;
      var year = now.year;
      while (month <= 0) {
        month += 12;
        year--;
      }
      labels.add(_shortMonth(month));
      for (final e in widget.spendingByDay.entries) {
        final d = DateTime.tryParse(e.key);
        if (d == null) continue;
        if (d.month == month && d.year == year) {
          buckets[months - 1 - m] += e.value;
        }
      }
    }
    return List.generate(
        months, (i) => ChartPoint(label: labels[i], value: buckets[i]));
  }

  String _shortMonth(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  void _handleTouch(Offset pos, BuildContext ctx, List<ChartPoint> points) {
    if (points.isEmpty) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width;
    final n = points.length;
    final segW = n > 1 ? w / (n - 1) : w;
    final idx = (pos.dx / segW).round().clamp(0, n - 1);
    setState(() => _touchedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final points =
    _mode == TrendMode.monthly ? _monthlyPoints() : _weeklyPoints();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Inline label: "April : ₹500" ───────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _touchedIndex != null
                    ? _InlineLabel(
                  key: ValueKey(_touchedIndex),
                  label: points[_touchedIndex!].label,
                  amount: points[_touchedIndex!].value,
                )
                    : Text(
                  'Tap any point',
                  key: const ValueKey('hint'),
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // ── Mode pill toggle ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  _PillBtn(
                    label: 'Weekly',
                    selected: _mode == TrendMode.weekly,
                    onTap: () => _switchMode(TrendMode.weekly),
                  ),
                  _PillBtn(
                    label: 'Monthly',
                    selected: _mode == TrendMode.monthly,
                    onTap: () => _switchMode(TrendMode.monthly),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Chart canvas ────────────────────────────────────────
        SizedBox(
          height: 140,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (ctx, _) => GestureDetector(
              onTapDown: (d) => _handleTouch(d.localPosition, ctx, points),
              onPanUpdate: (d) => _handleTouch(d.localPosition, ctx, points),
              child: CustomPaint(
                size: const Size(double.infinity, 140),
                painter: AreaLinePainter(
                  c: c,
                  points: points,
                  progress: CurvedAnimation(
                    parent: _anim,
                    curve: Curves.easeOutCubic,
                  ).value,
                  touchedIndex: _touchedIndex,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── X-axis labels ───────────────────────────────────────
        Row(
          children: points
              .map((p) => Expanded(
            child: Text(
              p.label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption
                  .copyWith(fontSize: 10, color: c.textMuted),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Inline label widget ──────────────────────────────────────
// Renders: "April : ₹500" on a single line, left-aligned
class _InlineLabel extends StatelessWidget {
  final String label;
  final double amount;

  const _InlineLabel({super.key, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: c.textDark,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: '  :  ',
            style: TextStyle(
              color: c.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: c.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pill button ──────────────────────────────────────────────
class _PillBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.textDark : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? c.bg : c.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Custom painter ───────────────────────────────────────────
class AreaLinePainter extends CustomPainter {
  final AppColorScheme c;
  final List<ChartPoint> points;
  final double progress;
  final int? touchedIndex;

  const AreaLinePainter({
    required this.c,
    required this.points,
    required this.progress,
    required this.touchedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final maxVal =
    points.map((p) => p.value).fold(0.0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final w = size.width;
    final h = size.height;
    final n = points.length;
    final segW = w / (n - 1);

    final pts = List.generate(n, (i) {
      final x = i * segW;
      final y = h - (points[i].value / maxVal) * h * 0.82 * progress;
      return Offset(x, y);
    });

    // Build smooth curve path
    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }

    // Fill area under line
    final fillPath = Path()
      ..addPath(linePath, Offset.zero)
      ..lineTo(pts.last.dx, h)
      ..lineTo(pts.first.dx, h)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            c.textDark.withOpacity(0.10),
            c.textDark.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.fill,
    );

    // Guide lines
    final guidePaint = Paint()
      ..color = c.border
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = h - h * 0.82 * i / 3;
      canvas.drawLine(Offset(0, y), Offset(w, y), guidePaint);
    }

    // Line stroke
    canvas.drawPath(
      linePath,
      Paint()
        ..color = c.textDark
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Data point dots
    for (var i = 0; i < n; i++) {
      final isTouched = touchedIndex == i;
      if (isTouched) {
        canvas.drawCircle(
            pts[i], 12, Paint()..color = c.textDark.withOpacity(0.08));
        canvas.drawLine(
          Offset(pts[i].dx, pts[i].dy + 14),
          Offset(pts[i].dx, h),
          Paint()
            ..color = c.textDark.withOpacity(0.12)
            ..strokeWidth = 1,
        );
        canvas.drawCircle(pts[i], 6, Paint()..color = c.textDark);
        canvas.drawCircle(pts[i], 3, Paint()..color = c.bg);
      } else {
        canvas.drawCircle(pts[i], 3, Paint()..color = c.textDark);
        canvas.drawCircle(pts[i], 1.5, Paint()..color = c.bg);
      }
    }
  }

  @override
  bool shouldRepaint(AreaLinePainter old) =>
      old.progress != progress ||
          old.touchedIndex != touchedIndex ||
          old.points.length != points.length ||
          old.c != c;
}