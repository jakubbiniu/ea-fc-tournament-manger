import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  final FirebaseAuth auth;
  const SplashScreen({Key? key, required this.auth}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _positionAnimation;
  bool _animationStarted = false;
  bool _showCrackedScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(40, 40), // Set initial offset
      end: Offset.zero, // End at the center
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Show cracked screen and navigate to LoginPage after the animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showCrackedScreen = true;
        });
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginPage(auth: widget.auth)),
          );
        });
      }
    });
  }

  void _startAnimation() {
    if (!_animationStarted) {
      setState(() {
        _animationStarted = true;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _startAnimation,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset('assets/grass.jpg', fit: BoxFit.cover),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _animationStarted
                        ? _positionAnimation.value
                        : const Offset(40, 40), // Set initial offset
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: RotationTransition(
                        turns: _rotationAnimation,
                        child: Image.asset('assets/ball.png', width: 200, height: 200),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showCrackedScreen)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.9, // Adjust the opacity as needed
                  child: Image.asset('assets/broken.png', fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
