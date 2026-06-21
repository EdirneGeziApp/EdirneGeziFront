import 'dart:async';
import 'package:flutter/material.dart';

import 'login_page.dart';
import 'main_page.dart';
import 'admin_page.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  final bool isAdmin;

  const SplashScreen({
    super.key,
    required this.isLoggedIn,
    required this.isAdmin,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;

      Widget nextPage;

      if (widget.isLoggedIn) {
        nextPage = widget.isAdmin ? const AdminPage() : const MainPage();
      } else {
        nextPage = const LoginPage();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => nextPage,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/splash.png',
                  height: screenHeight,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.center,
                ),
              ),

              const Positioned(
                bottom: 75,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      color: Color(0xFF9E1111),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}