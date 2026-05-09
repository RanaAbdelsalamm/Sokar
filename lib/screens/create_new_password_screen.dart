import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'login_screen.dart';

class CreateNewPasswordScreen extends StatelessWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Reset Password', 
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
                            'We\'ve sent a secure link to your email.\nPlease click it to set a new password, then come back here to log in.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: AppColors.textSubtitle, height: 1.5),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate back to login screen securely
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                                elevation: 0
                              ),
                              child: const Text('Back to Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
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