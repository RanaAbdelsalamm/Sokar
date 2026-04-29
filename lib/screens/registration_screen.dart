import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart'; // To navigate to login
import 'verification_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // State for Gender Selection (0 = Male, 1 = Female)
  int selectedGender = -1; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBackground,
      appBar: AppBar(
        backgroundColor: AppColors.whiteBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header Section
              const Text(
                'Join Sokar',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Start your personalized health journey today.\nYour data is encrypted and used only for\nyour insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textDarkBlue,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // 2. Account Security Section
              Row(
                children: const [
                  Icon(Icons.lock_outline, color: AppColors.textDarkBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ACCOUNT SECURITY',
                    style: TextStyle(
                      color: AppColors.textDarkBlue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const CustomTextField(label: 'Full Name', hint: 'Rana Abdelsalam'),
              const SizedBox(height: 16),
              const CustomTextField(
                label: 'Email Address', 
                hint: 'ranawaayy@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const CustomTextField(
                label: 'Password', 
                hint: '........',
                isPassword: true,
              ),
              const SizedBox(height: 32),

              // 3. Clinical Data Section
              Row(
                children: const [
                  Icon(Icons.show_chart, color: AppColors.textDarkBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'CLINICAL DATA',
                    style: TextStyle(
                      color: AppColors.textDarkBlue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(
                    child: CustomTextField(
                      label: 'Age', 
                      hint: '24', 
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Weight (kg)', 
                      hint: '70', 
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Gender Selection
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gender Identity',
                  style: TextStyle(
                    color: AppColors.textDarkGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildGenderButton('Male', 0)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildGenderButton('Female', 1)),
                ],
              ),
              const SizedBox(height: 40),

              // 4. Create Account Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Verification Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VerificationScreen()),
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
                    'Create Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.textDarkBlue)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for gender selection
  Widget _buildGenderButton(String title, int index) {
    bool isSelected = selectedGender == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = index;
        });
      },
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDarkBlue,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}