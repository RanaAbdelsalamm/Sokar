import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/feature_card.dart';
import 'registration_screen.dart';
import 'login_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Main Title
                const Text(
                  'Your Smart Partner in\nDiabetes Care.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMainTitle,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 2. Subtitle
                const Text(
                  'Personalized AI insights to help you manage\nyour health with confidence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSubtitle,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                
                // 3. Grid of Features
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, 
                  physics: const NeverScrollableScrollPhysics(), 
                  children: const [
                    FeatureCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Smart Tracking',
                      description: 'Effortlessly log glucose, meals, and activity.',
                    ),
                    FeatureCard(
                      icon: Icons.psychology_outlined,
                      title: 'AI-Powered\nInsights',
                      description: 'Get personalized feedback and predict trends.',
                    ),
                    FeatureCard(
                      icon: Icons.assignment_outlined,
                      title: 'Personalized\nPlans',
                      description: 'Receive custom meal and activity recommendations.',
                    ),
                    FeatureCard(
                      icon: Icons.monitor_heart_outlined,
                      title: 'Daily\nReminders',
                      description: 'Gentle nudges for your meds, insulin, and check-ups.',
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                // 4. Primary Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Create Your Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 5. Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.textSubtitle),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 6. Terms & Privacy
                const Text(
                  'By creating an account, you agree to our Terms of Service and\nPrivacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}