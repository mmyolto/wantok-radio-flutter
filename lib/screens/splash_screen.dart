import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(
    begin: 0.85,
    end: 1,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: 2300), widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double logoWidth = (size.width * 0.8).clamp(200.0, 480.0);
    return Scaffold(
      backgroundColor: AppColors.night,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  // Scales down on short screens (phone landscape, large text).
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.gold.withValues(alpha: 0.45),
                                      blurRadius: 40,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: logoWidth,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Wantok Radio Light logo',
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'YOUR INSPIRATION STATION',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  color: AppColors.gold,
                                ),
                              ),
                              const SizedBox(height: 40),
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: DeveloperCredit(onDark: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
