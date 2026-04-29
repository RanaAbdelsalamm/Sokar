import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'upload_file_screen.dart';

class VerificationSuccessScreen extends StatefulWidget {
  const VerificationSuccessScreen({super.key});

  @override
  State<VerificationSuccessScreen> createState() => _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    // Auto-navigate to upload screen after 5 seconds
    _redirectTimer = Timer(const Duration(seconds: 5), () {
      _navigateToDashboard();
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  // Method to handle navigation and clear history
  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const UploadFileScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(backgroundColor: AppColors.backgroundLight, elevation: 0, centerTitle: true, title: const Text('Verification', style: TextStyle(color: AppColors.textMainTitle, fontWeight: FontWeight.bold)), automaticallyImplyLeading: false),
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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)]),
                      child: Column(
                        children: [
                          Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 40)),
                          const SizedBox(height: 24),
                          const Text('Account Verified!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                          const SizedBox(height: 12),
                          const Text('Success! Your account is ready.\nLet\'s start your health journey.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textSubtitle, height: 1.5)),
                          const SizedBox(height: 32),
                          // Pagination-style indicators
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _buildDash(false), const SizedBox(width: 8), _buildDash(true), const SizedBox(width: 8), _buildDash(false)
                          ]),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity, 
                            height: 56, 
                            child: ElevatedButton(
                              onPressed: () {
                                _redirectTimer?.cancel();
                                _navigateToDashboard();
                              }, 
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), 
                              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
                            )
                          ),
                          const SizedBox(height: 24),
                          const Text('Redirecting automatically in 5 seconds...', style: TextStyle(color: AppColors.textSubtitle, fontSize: 13)),
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

  Widget _buildDash(bool active) => Container(width: 24, height: 4, decoration: BoxDecoration(color: active ? AppColors.primaryBlue : AppColors.primaryBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)));
}