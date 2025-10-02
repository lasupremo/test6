import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:rekindle/pages/auth/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideIconAnimation;
  late Animation<Offset> _slideTextAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _finalScaleAnimation;
  late Animation<double> _finalFadeOutAnimation;

  @override
  void initState() {
    super.initState();

    // Set a much faster total duration for the animation.
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    // Wait for 1 second before starting the animations to show the static logo in the center.
    Timer(const Duration(seconds: 1), () {
      _controller.forward();
    });

    // Step 1: Initial zoom in and out, now happening in the first 20% of the total animation time.
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.5)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.5, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2)));

    // Step 2: Slide the icon to the side. This animation now runs independently.
    _slideIconAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(-1, 0.0), // A larger, more noticeable slide to the left.
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic)));

    // Step 3: Fade in and slide the app name. This happens after the icon's slide is complete.
    _slideTextAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0), // Start from slightly to the right of its final position
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn))); // This animation now starts after the icon's slide.

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 0.8, curve: Curves.easeIn))); // Synchronized with the text slide.

    // Step 4: Final zoom + fade out of everything.
    _finalScaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.9, 1.0, curve: Curves.easeIn)));
    _finalFadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.9, 1.0, curve: Curves.easeOut)));

    // Navigate to the next screen after the total animation duration plus the delay.
    Future.delayed(const Duration(seconds:5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F3EB),
              Color(0xFFF8F3EB),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Apply final scale and opacity to the whole row
              return Transform.scale(
                scale: _finalScaleAnimation.value,
                child: Opacity(
                  opacity: _finalFadeOutAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Logo animation: initial scale and slide - now only shows the main logo
                      SlideTransition(
                        position: _slideIconAnimation,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Image.asset(
                            "assets/images/flame_logo.png",
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ),
                      // Text animation: slide and fade in
                      if (_fadeInAnimation.value > 0)
                        SlideTransition(
                          position: _slideTextAnimation,
                          child: FadeTransition(
                            opacity: _fadeInAnimation,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 150.0, top: 20.0), // Added top padding to move it down
                              child: Text(
                                "Rekindle",
                                style: GoogleFonts.inter(
                                  fontSize: 50,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  shadows: const [],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
