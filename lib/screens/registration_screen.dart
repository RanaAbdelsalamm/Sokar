import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'login_screen.dart';
import 'landing_page.dart';
import 'health_profile_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Validation Error States
  bool _nameError = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;

  // Non-breaking space (\u00A0) keeps the star attached to the label
  Widget _buildRequiredLabel(String text) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.textMainTitle, fontSize: 14, fontWeight: FontWeight.w600),
        children: const [
          TextSpan(
            text: '\u00A0*', 
            style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty;
      _emailError = _emailController.text.trim().isEmpty;
      // Also validate length for UI (at least 8 characters)
      _passwordError = _passwordController.text.trim().length < 8;
      // Check if passwords match and are not empty
      _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty || 
                              _passwordController.text != _confirmPasswordController.text;
    });

    if (_nameError || _emailError || _passwordError || _confirmPasswordError) {
      if (_passwordController.text != _confirmPasswordController.text && !_passwordError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.redAccent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields correctly.'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    // Move to next screen and pass the basic data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthProfileScreen(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBackground,
      appBar: AppBar(
        backgroundColor: AppColors.whiteBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMainTitle),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LandingPage()));
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Center(child: Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textMainTitle))),
              const SizedBox(height: 12),
              const Center(child: Text('Step 1 of 2: Basic Information', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSubtitle))),
              const SizedBox(height: 48),
              
              // Name
              _buildRequiredLabel('Full Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                onChanged: (val) { if(_nameError) setState(() => _nameError = false); },
                decoration: _buildInputDecoration('Enter your name', _nameError),
              ),
              const SizedBox(height: 16),
              
              // Email
              _buildRequiredLabel('Email Address'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) { if(_emailError) setState(() => _emailError = false); },
                decoration: _buildInputDecoration('Enter your email', _emailError),
              ),
              const SizedBox(height: 16),
              
              // Password (Label now includes at least 8 chars note)
              _buildRequiredLabel('Password (at least 8 characters)'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (val) { if(_passwordError) setState(() => _passwordError = false); },
                decoration: _buildInputDecoration('Enter password', _passwordError).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSubtitle),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              _buildRequiredLabel('Confirm Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onChanged: (val) { if(_confirmPasswordError) setState(() => _confirmPasswordError = false); },
                decoration: _buildInputDecoration('Re-enter password', _confirmPasswordError).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSubtitle),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              
              // Define a large gap to center the fields better on the screen
              const SizedBox(height: 60), 
              
              // Continue Button
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _goToNextStep,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: AppColors.textSubtitle)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                      child: const Text('Log In', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationColor: AppColors.primaryBlue)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Common Input Decoration for TextFields
  InputDecoration _buildInputDecoration(String hint, bool hasError) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: AppColors.textSubtitle.withValues(alpha: 0.7), fontSize: 15),
      filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorText: hasError ? (hint.contains('Re-enter') ? 'Passwords do not match or empty' : (hint.contains('email') ? 'Bad formatted email' : (hint.contains('password') ? 'Invalid or non-matching password' : 'Required'))) : null, 
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }
}