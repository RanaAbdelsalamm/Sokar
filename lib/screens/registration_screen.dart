import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'verification_screen.dart';
import 'landing_page.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  int selectedGender = -1;
  bool _obscurePassword = true;
  DateTime? _selectedDate;
  bool _isLoading = false; 

  // Validation Error States
  bool _nameError = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _weightError = false;
  bool _dateError = false;
  bool _genderError = false;

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // Helper widget for required labels (adds a red asterisk)
  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.textMainTitle, fontSize: 14, fontWeight: FontWeight.w600),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _signUp() async {
    // 1. Check for empty fields and trigger UI error states
    setState(() {
      _nameError = _nameController.text.trim().isEmpty;
      _emailError = _emailController.text.trim().isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
      _weightError = _weightController.text.trim().isEmpty;
      _dateError = _selectedDate == null;
      _genderError = selectedGender == -1;
    });

    // 2. If any error exists, stop the process
    if (_nameError || _emailError || _passwordError || _weightError || _dateError || _genderError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String res = await AuthService().signUpUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      birthDate: _selectedDate!,
      gender: selectedGender == 0 ? 'Male' : 'Female',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res == "Success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VerificationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LandingPage()),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Join Sokar',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMainTitle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Your data is encrypted and used only for your insights.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSubtitle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      _buildRequiredLabel('Full Name'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        onChanged: (val) { if(_nameError) setState(() => _nameError = false); },
                        decoration: _buildInputDecoration('Enter your name', _nameError),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildRequiredLabel('Email Address'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (val) { if(_emailError) setState(() => _emailError = false); },
                        decoration: _buildInputDecoration('Enter your email', _emailError),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildRequiredLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (val) { if(_passwordError) setState(() => _passwordError = false); },
                        decoration: _buildInputDecoration('Enter password', _passwordError).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSubtitle,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRequiredLabel('Date of Birth'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.light(
                                              primary: AppColors.primaryBlue,
                                              onPrimary: Colors.white,
                                              onSurface: AppColors.textMainTitle,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedDate = picked;
                                        _dateError = false;
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _dateError ? Colors.red : AppColors.borderLight, 
                                        width: 1.5
                                      ),
                                    ),
                                    child: Text(
                                      _selectedDate == null ? 'dd/mm/yyyy' : _formatDate(_selectedDate!),
                                      style: TextStyle(
                                        color: _selectedDate == null ? AppColors.textSubtitle.withValues(alpha: 0.7) : AppColors.textMainTitle,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_dateError)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0, left: 12.0),
                                    child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  )
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRequiredLabel('Weight'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) { if(_weightError) setState(() => _weightError = false); },
                                  decoration: _buildInputDecoration('Weight (kg)', _weightError),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildRequiredLabel('Your gender'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildGenderButton('Male', 0, Icons.male)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildGenderButton('Female', 1, Icons.female)),
                        ],
                      ),
                      if (_genderError)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0, left: 12.0),
                          child: Text('Please select your gender', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                        
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading 
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? ', style: TextStyle(color: AppColors.textSubtitle)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context, 
                                  MaterialPageRoute(builder: (context) => const LoginScreen())
                                );
                              },
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  color: AppColors.primaryBlue, 
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primaryBlue,
                                ),
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
          }
        ),
      ),
    );
  }

  // Extracted input decoration to keep the code clean and handle error UI automatically
  InputDecoration _buildInputDecoration(String hint, bool hasError) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSubtitle.withValues(alpha: 0.7), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorText: hasError ? 'This field is required' : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildGenderButton(String title, int index, IconData icon) {
    bool isSelected = selectedGender == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = index;
          _genderError = false; // Remove error if selected
        });
      },
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _genderError && !isSelected 
                ? Colors.red 
                : isSelected ? AppColors.primaryBlue : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textMainTitle,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMainTitle,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}