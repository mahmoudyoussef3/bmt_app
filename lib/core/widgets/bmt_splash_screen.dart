import 'package:flutter/material.dart';

class BmtSplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const BmtSplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<BmtSplashScreen> createState() => _BmtSplashScreenState();
}

class _BmtSplashScreenState extends State<BmtSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Simulate initialization time (or wait for cubits)
    // plus the duration of the animation.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      // Add a slight delay after animation before navigating
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onInitializationComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The background color matches the native splash configuration
    // to ensure a seamless transition.
    final brightness = Theme.of(context).brightness;
    final backgroundColor = brightness == Brightness.light 
        ? const Color(0xFFFAFAF5) 
        : const Color(0xFF1F1F1F);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}
