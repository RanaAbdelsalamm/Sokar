import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dart:async';
import 'landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
@override
  void initState() {
    super.initState();
    // Navigate to landing page after 3 seconds
    Timer(
      const Duration(seconds: 3),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Image.asset(
          'assets/images/sokar_logo.png',
          width: 280, 
        ),
      ),
    );
  }
}