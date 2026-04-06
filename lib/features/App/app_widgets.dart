// lib/core/widgets/app_widgets.dart
//
// Context-aware reusable widgets — automatically adapt to
// light OR dark theme. No if/else needed in your screen code.
//
// Imports needed in every screen:
//   import 'package:your_app/core/theme/app_theme.dart';
//   import 'package:your_app/core/widgets/app_widgets.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

// ═══════════════════════════════════════════════════════════════
//  1. APP GLASS CARD
// ═══════════════════════════════════════════════════════════════
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final c  = context.appColors;
    final br = BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: c.glassFill,
            borderRadius: br,
            border: Border.all(color: c.glassBorder, width: 1),
            boxShadow: context.glassShadow,
          ),
          child: c.isDark
              ? Stack(children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                    gradient: AppGradients.glassShimmer),
              ),
            ),
            child,
          ])
              : child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  2. APP GLASS TRACK
// ═══════════════════════════════════════════════════════════════
class AppGlassTrack extends StatelessWidget {
  final double percent;
  final Color? color;
  final Gradient? gradient;
  final Color notchBg;

  const AppGlassTrack({
    super.key,
    required this.percent,
    this.color,
    this.gradient,
    required this.notchBg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      return SizedBox(
        height: 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: gradient == null ? color : null,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: (isDark && gradient != null)
                      ? [
                    BoxShadow(
                      color:
                      (color ?? AppColors.emerald).withOpacity(0.45),
                      blurRadius: 6,
                    )
                  ]
                      : null,
                ),
              ),
            ),
            Positioned(
              left: w * 0.6, top: -2, bottom: -2,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                    color: notchBg, borderRadius: BorderRadius.circular(1)),
              ),
            ),
            Positioned(
              left: w * 0.9, top: -2, bottom: -2,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                    color: notchBg, borderRadius: BorderRadius.circular(1)),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════
//  3. APP GRADIENT BUTTON
// ═══════════════════════════════════════════════════════════════
class AppGradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Gradient? gradientOverride;
  final List<BoxShadow>? shadowOverride;

  const AppGradientButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onPressed,
    this.gradientOverride,
    this.shadowOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: gradientOverride ?? context.ctaGradient,
        boxShadow: shadowOverride ?? context.ctaShadow,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24, width: 24,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        )
            : Text(label, style: AppTextStyles.buttonPrimary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  4. APP PIN BOXES
// ═══════════════════════════════════════════════════════════════
class AppPinBoxes extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  const AppPinBoxes({
    super.key,
    required this.controller,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final pinLength = controller.text.length;

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
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isFocused ? AppColors.gradientStart : c.border,
                      width: isFocused ? 2 : 1,
                    ),
                    boxShadow: (isFocused && c.isDark)
                        ? [
                      BoxShadow(
                        color: AppColors.gradientStart.withOpacity(0.35),
                        blurRadius: 10,
                      )
                    ]
                        : null,
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
              controller: controller,
              autofocus: false,
              keyboardType: TextInputType.number,
              cursorColor: Colors.transparent,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                  border: InputBorder.none, counterText: ''),
              onSubmitted: (_) => onSubmitted?.call(),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  5. APP ERROR BANNER
// ═══════════════════════════════════════════════════════════════
class AppErrorBanner extends StatelessWidget {
  final String message;
  final EdgeInsets margin;

  const AppErrorBanner({
    super.key,
    required this.message,
    this.margin = const EdgeInsets.only(bottom: 24),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.rose.withOpacity(isDark ? 0.08 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.rose.withOpacity(isDark ? 0.25 : 0.30)),
        boxShadow: isDark ? AppShadows.roseGlow : null,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.rose.withOpacity(0.85), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.rose,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  6. APP SECTION LABEL
// ═══════════════════════════════════════════════════════════════
class AppSectionLabel extends StatelessWidget {
  final String title;
  final EdgeInsets padding;
  final bool showAccent;

  const AppSectionLabel({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.only(left: 8),
    this.showAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAccent && c.isDark) ...[
            Container(
              width: 3, height: 12,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(title.toUpperCase(),
              style: AppTextStyles.sectionLabel.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  7. APP TILE DIVIDER
// ═══════════════════════════════════════════════════════════════
class AppTileDivider extends StatelessWidget {
  final double indent;
  const AppTileDivider({super.key, this.indent = 56});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent),
    child: Divider(
      height: 1, thickness: 1,
      color: context.appColors.border.withOpacity(0.6),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  8. APP INFO FIELD
// ═══════════════════════════════════════════════════════════════
class AppInfoField extends StatelessWidget {
  final String label;
  final String value;
  const AppInfoField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.sectionLabel.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: c.border),
          ),
          child: Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textDark)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  9. APP BACK BUTTON
// ═══════════════════════════════════════════════════════════════
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const AppBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap ?? () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.surface2,
          border: Border.all(color: c.border),
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            color: c.textDark, size: 20),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  10. APP CIRCLE ICON  (flat tinted — low visual weight)
// ═══════════════════════════════════════════════════════════════
class AppCircleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double padding;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final double opacity;

  const AppCircleIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 22,
    this.padding = 12,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color.withOpacity(opacity),
      shape: shape,
      borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
      border: Border.all(color: color.withOpacity(opacity * 1.5)),
    ),
    child: Icon(icon, color: color, size: size),
  );
}

// ═══════════════════════════════════════════════════════════════
//  10b. APP GRADIENT ICON  (gradient badge — hero use)
// ═══════════════════════════════════════════════════════════════
class AppGradientIcon extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final Color? glowColor;
  final double size;
  final double padding;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const AppGradientIcon({
    super.key,
    required this.icon,
    required this.gradient,
    this.glowColor,
    this.size = 22,
    this.padding = 12,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    Color resolvedGlow = glowColor ?? AppColors.gradientStart;
    if (gradient is LinearGradient) {
      final lg = gradient as LinearGradient;
      if (lg.colors.isNotEmpty) resolvedGlow = lg.colors[0];
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: gradient,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: isDark
            ? [
          BoxShadow(
            color: resolvedGlow.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  11. APP GLASS SHEET
// ═══════════════════════════════════════════════════════════════
class AppGlassSheet extends StatelessWidget {
  final Widget child;
  const AppGlassSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: c.isDark
                ? Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: BorderRadius.circular(2),
              ),
            )
                : Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  12. APP COMING SOON SHEET
// ═══════════════════════════════════════════════════════════════
class AppComingSoonSheet extends StatelessWidget {
  final String title;
  const AppComingSoonSheet({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppGlassSheet(
      child: Column(
        children: [
          c.isDark
              ? AppGradientIcon(
              icon: Icons.build_circle_outlined,
              gradient: AppGradients.violet,
              size: 36, padding: 16)
              : AppCircleIcon(
              icon: Icons.build_circle_outlined,
              color: AppColors.textDarkL,
              opacity: 0.05, size: 36, padding: 16),
          const SizedBox(height: 20),
          Text(title,
              style:
              AppTextStyles.sectionHeading.copyWith(color: c.textDark)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: c.border),
            ),
            child: Text(
              'This feature is currently under construction and will be available in a future update. Stay tuned!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: c.textMuted, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  13. APP PROFILE TILE
// ═══════════════════════════════════════════════════════════════
class AppProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;
  final Gradient? iconGradient;

  const AppProfileTile({
    super.key,
    required this.icon,
    required this.label,
    this.trailingText,
    required this.onTap,
    this.iconGradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: AppColors.gradientStart.withOpacity(0.08),
        highlightColor: AppColors.gradientStart.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              (iconGradient != null && c.isDark)
                  ? AppGradientIcon(
                  icon: icon, gradient: iconGradient!,
                  size: 18, padding: 8,
                  shape: BoxShape.rectangle,
                  borderRadius:
                  BorderRadius.circular(AppRadius.xs + 2))
                  : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius:
                    BorderRadius.circular(AppRadius.xs + 2),
                    border: Border.all(color: c.border),
                  ),
                  child:
                  Icon(icon, color: c.textMuted, size: 18)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textDark)),
              ),
              if (trailingText != null) ...[
                Text(trailingText!,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.textMuted)),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right_rounded,
                  color: c.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  14. APP STAT BADGE
// ═══════════════════════════════════════════════════════════════
class AppStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Gradient? gradient;

  const AppStatBadge({
    super.key,
    required this.label,
    required this.value,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final useGradient = gradient != null && c.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: useGradient ? gradient : null,
        color: useGradient ? null : c.surface2,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: useGradient ? null : Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: useGradient
                  ? Colors.white.withOpacity(0.75)
                  : c.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: useGradient ? Colors.white : c.textDark,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  15. APP GRADIENT CARD  (hero / balance card)
// ═══════════════════════════════════════════════════════════════
class AppGradientCard extends StatelessWidget {
  final Widget child;
  final Gradient? darkGradient;
  final EdgeInsets padding;
  final double radius;

  const AppGradientCard({
    super.key,
    required this.child,
    this.darkGradient,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final br = BorderRadius.circular(radius);
    final useGradient = c.isDark && darkGradient != null;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: useGradient ? darkGradient : null,
        color: useGradient ? null : c.surface,
        borderRadius: br,
        border: Border.all(color: c.glassBorder),
        boxShadow: context.glassShadow,
      ),
      child: useGradient
          ? Stack(children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
                gradient: AppGradients.glassShimmer),
          ),
        ),
        child,
      ])
          : child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  16. APP SUCCESS STRIP
// ═══════════════════════════════════════════════════════════════
class AppSuccessStrip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;

  const AppSuccessStrip({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.check_circle_rounded,
    this.gradient = AppGradients.emerald,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          c.isDark
              ? AppGradientIcon(
              icon: icon, gradient: gradient, size: 20, padding: 10)
              : AppCircleIcon(
              icon: icon, color: AppColors.emerald,
              size: 20, padding: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: c.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}