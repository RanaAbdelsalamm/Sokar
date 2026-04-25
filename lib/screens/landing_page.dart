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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
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
              const SizedBox(height: 32),
              
              // 3. Grid of Features
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, // Adjust to make cards taller or shorter
                  physics: const NeverScrollableScrollPhysics(), // Disable internal scroll
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
              ),
              
              // 4. Primary Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // 1. The onPressed goes right here
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                    );
                  },
                  // 2. Then the style
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  // 3. Then the child (text)
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
              
              // 6. Terms & Privacy
              const Text(
                'By creating an account, you agree to our Terms of Service and\nPrivacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}