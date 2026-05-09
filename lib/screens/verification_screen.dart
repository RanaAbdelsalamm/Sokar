import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'verification_success_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool isLoading = false;
  Timer? _countdownTimer;
  Timer? _autoCheckTimer;
  int _start = 59;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    // Automatically check verification status every 3 seconds
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _autoCheckVerification();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  // Logic to check verification in the background
  void _autoCheckVerification() async {
    bool isVerified = await AuthService().checkEmailVerified();
    if (isVerified) {
      _autoCheckTimer?.cancel();
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void startTimer() async {
    setState(() {
      _canResend = false;
      _start = 59;
    });

    try {
      // Actually trigger Firebase to resend the email
      await AuthService().sendVerificationEmail();

      if (!mounted) return; 
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Verification email resent successfully!', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
          ),
          backgroundColor: AppColors.textMainTitle.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      _countdownTimer?.cancel(); // Cancel any existing timer safely
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (Timer timer) {
          if (_start == 0) {
            setState(() {
              _canResend = true;
              timer.cancel();
            });
          } else {
            setState(() {
              _start--;
            });
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      // Catch Firebase rate-limiting or any network error without freezing the app
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait a moment before requesting another link.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Reset the button so the user isn't stuck
      setState(() {
        _canResend = true;
      });
    }
  }

  void handleVerificationCheck() async {
    setState(() => isLoading = true);
    
    // Manual check when user clicks the button
    bool isVerified = await AuthService().checkEmailVerified();
    
    if (mounted) {
      setState(() => isLoading = false);
      
      if (isVerified) {
        _autoCheckTimer?.cancel();
        _navigateToNextScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not verified yet. Please check your inbox.')),
        );
      }
    }
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const VerificationSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Verification', 
          style: TextStyle(color: AppColors.textMainTitle, fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSubtitle),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72, 
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.iconBgLight, 
                              borderRadius: BorderRadius.circular(16)
                            ),
                            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryBlue, size: 32),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Check your Inbox', 
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We\'ve sent a verification link to your\nemail. Please verify to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: AppColors.textSubtitle, height: 1.5),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : handleVerificationCheck,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                                elevation: 0
                              ),
                              child: isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('I have verified my email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Didn\'t receive the email? ', 
                                style: TextStyle(color: AppColors.textSubtitle, fontSize: 13)
                              ),
                              _canResend
                                  ? GestureDetector(
                                      onTap: () {
                                        startTimer();
                                      },
                                      child: const Text(
                                        'Resend Link',
                                        style: TextStyle(
                                          color: AppColors.primaryBlue, 
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 13
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Wait 00:${_start.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: AppColors.textSubtitle, 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: AppColors.iconBgLight.withValues(alpha: 0.5), 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: AppColors.iconBgLight)
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Verification ensures your medical data remains private and secure. Check your spam folder if you don\'t see it within 2 minutes.', 
                              style: TextStyle(color: AppColors.textSubtitle, fontSize: 13, height: 1.5)
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}