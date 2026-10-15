import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';

/// Screen-size breakpoints (Material 3 window size classes).
class Breakpoints {
  Breakpoints._();
  static const double medium = 600; // tablets portrait / large phones landscape
  static const double expanded = 1024; // tablets landscape / desktops

  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < medium;
}

/// Horizontal padding that grows with the screen.
double pagePadding(double width) {
  if (width >= Breakpoints.expanded) return 32;
  if (width >= Breakpoints.medium) return 24;
  if (width < 360) return 12;
  return 16;
}

/// Scrollable page body, centred and width-limited so text never runs edge to
/// edge on tablets.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.maxWidth = 720,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.controller,
    this.physics,
  });

  final List<Widget> children;
  final double maxWidth;
  final CrossAxisAlignment crossAxisAlignment;
  final ScrollController? controller;

  /// Use [AlwaysScrollableScrollPhysics] inside a [RefreshIndicator].
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double pad = pagePadding(c.maxWidth);
        return SingleChildScrollView(
          controller: controller,
          physics: physics,
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(crossAxisAlignment: crossAxisAlignment, children: children),
            ),
          ),
        );
      },
    );
  }
}

/// Large section title in the station's display font.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: t.headlineMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 46,
            height: 4,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: t.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// White rounded card with consistent padding.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Card heading used inside [SectionCard]s.
class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key, this.icon, this.color = AppColors.primary});

  final String text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, color: color), const SizedBox(width: 10)],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Station logo image.
class StationLogo extends StatelessWidget {
  const StationLogo({super.key, this.height = 72});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Wantok Radio Light logo',
    );
  }
}

/// Green gradient app bar used across the app.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, required this.title, this.leading, this.actions});

  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      actions: actions,
      foregroundColor: Colors.white,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 1.5,
            width: double.infinity,
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.goldLine)),
          ),
        ),
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.displayFont,
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: 2.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// "Built & Design: Meltronics Info-Tech" credit line.
class DeveloperCredit extends StatelessWidget {
  const DeveloperCredit({super.key, this.color = AppColors.onSurfaceVariant, this.size = 12});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppConfig.developerCredit,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(text: 'Built & Design: '),
            TextSpan(
              text: 'Meltronics Info-Tech',
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: size,
          letterSpacing: 0.3,
          color: color.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Frosted-glass panel used on the dark "on air" screens.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = BorderRadius.circular(radius);
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Big gold call-to-action button with a soft glow.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(height / 2),
            onTap: onPressed,
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, color: AppColors.night, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                        color: AppColors.night,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
