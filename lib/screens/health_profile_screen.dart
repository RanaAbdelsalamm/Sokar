import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'verification_screen.dart';

class HealthProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const HealthProfileScreen({super.key, required this.name, required this.email, required this.password});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  int? selectedGender; 
  int? selectedSmoking; 
  int? selectedHypertension; 
  int? selectedHeartDisease; 

  DateTime? _selectedDate;
  bool _isLoading = false; 

  bool _weightError = false;
  bool _heightError = false;
  bool _dateError = false;
  bool _genderError = false;
  bool _smokingError = false;
  bool _hypertensionError = false;
  bool _heartDiseaseError = false;

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

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

  Future<void> _createAccount() async {
    setState(() {
      _weightError = _weightController.text.trim().isEmpty;
      _heightError = _heightController.text.trim().isEmpty;
      _dateError = _selectedDate == null;
      _genderError = selectedGender == null;
      _smokingError = selectedSmoking == null;
      _hypertensionError = selectedHypertension == null;
      _heartDiseaseError = selectedHeartDisease == null;
    });

    if (_weightError || _heightError || _dateError || _genderError || _smokingError || _hypertensionError || _heartDiseaseError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required health fields.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    String res = await AuthService().signUpUser(
      name: widget.name,
      email: widget.email,
      password: widget.password,
      weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      height: double.tryParse(_heightController.text.trim()) ?? 0.0,
      birthDate: _selectedDate!,
      gender: selectedGender!, 
      smokingHistory: selectedSmoking!,
      hypertension: selectedHypertension!,
      heartDisease: selectedHeartDisease!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res == "Success") {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const VerificationScreen()),
        (route) => false
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.redAccent));
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Center(child: Text('Health Profile', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textMainTitle))),
                      const SizedBox(height: 8),
                      const Center(child: Text('Step 2 of 2: Medical Details', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSubtitle))),
                      const SizedBox(height: 40),
                      
                      // Date of Birth
                      _buildRequiredLabel('Date of Birth'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue, onPrimary: Colors.white, onSurface: AppColors.textMainTitle)),
                              child: child!,
                            ),
                          );
                          if (picked != null) setState(() { _selectedDate = picked; _dateError = false; });
                        },
                        child: Container(
                          height: 56, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _dateError ? Colors.red : AppColors.borderLight, width: 1.5)),
                          child: Text(_selectedDate == null ? 'DD/MM/YYYY' : _formatDate(_selectedDate!), style: TextStyle(color: _selectedDate == null ? AppColors.textSubtitle.withValues(alpha: 0.7) : AppColors.textMainTitle, fontSize: 15)),
                        ),
                      ),
                      if (_dateError) const Padding(padding: EdgeInsets.only(top: 8.0, left: 12.0), child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 12))),
                      const SizedBox(height: 20),
                      
                      // Weight & Height
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRequiredLabel('Weight'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _weightController, keyboardType: TextInputType.number,
                                  onChanged: (val) { if(_weightError) setState(() => _weightError = false); },
                                  decoration: _buildInputDecoration('Weight (kg)', _weightError),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRequiredLabel('Height'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _heightController, keyboardType: TextInputType.number,
                                  onChanged: (val) { if(_heightError) setState(() => _heightError = false); },
                                  decoration: _buildInputDecoration('Height (cm)', _heightError),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Gender
                      _buildRequiredLabel('Gender'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildOptionButton('Female', 0, selectedGender, (val) => setState(() { selectedGender = val; _genderError = false; }), _genderError, Icons.female)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildOptionButton('Male', 1, selectedGender, (val) => setState(() { selectedGender = val; _genderError = false; }), _genderError, Icons.male)),
                        ],
                      ),
                      if (_genderError) const Padding(padding: EdgeInsets.only(top: 8.0, left: 12.0), child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 12))),
                      const SizedBox(height: 20),

                      // Smoking
                      _buildRequiredLabel('Smoking History'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildOptionButton('Never', 0, selectedSmoking, (val) => setState(() { selectedSmoking = val; _smokingError = false; }), _smokingError, null)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildOptionButton('Former', 1, selectedSmoking, (val) => setState(() { selectedSmoking = val; _smokingError = false; }), _smokingError, null)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildOptionButton('Current', 2, selectedSmoking, (val) => setState(() { selectedSmoking = val; _smokingError = false; }), _smokingError, null)),
                        ],
                      ),
                      if (_smokingError) const Padding(padding: EdgeInsets.only(top: 8.0, left: 12.0), child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 12))),
                      const SizedBox(height: 20),

                      // Hypertension
                      _buildRequiredLabel('Do you have Blood Pressure issues?'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildOptionButton('No', 0, selectedHypertension, (val) => setState(() { selectedHypertension = val; _hypertensionError = false; }), _hypertensionError, null)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildOptionButton('Yes', 1, selectedHypertension, (val) => setState(() { selectedHypertension = val; _hypertensionError = false; }), _hypertensionError, null)),
                        ],
                      ),
                      if (_hypertensionError) const Padding(padding: EdgeInsets.only(top: 8.0, left: 12.0), child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 12))),
                      const SizedBox(height: 20),

                      // Heart Disease
                      _buildRequiredLabel('Do you have Heart Disease?'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildOptionButton('No', 0, selectedHeartDisease, (val) => setState(() { selectedHeartDisease = val; _heartDiseaseError = false; }), _heartDiseaseError, null)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildOptionButton('Yes', 1, selectedHeartDisease, (val) => setState(() { selectedHeartDisease = val; _heartDiseaseError = false; }), _heartDiseaseError, null)),
                        ],
                      ),
                      if (_heartDiseaseError) const Padding(padding: EdgeInsets.only(top: 8.0, left: 12.0), child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 12))),
                      
                      // Extra space before the button
                      const SizedBox(height: 48), 
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createAccount,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      
                      // Security Text with Lock Icon
                      const Padding(
                        padding: EdgeInsets.only(top: 20.0, bottom: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 14, color: AppColors.textSubtitle),
                            SizedBox(width: 6),
                            Text(
                              'Your data is secure and used only for your insights.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSubtitle),
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

  InputDecoration _buildInputDecoration(String hint, bool hasError) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: AppColors.textSubtitle.withValues(alpha: 0.7), fontSize: 15),
      filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorText: hasError ? 'Required' : null, 
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _buildOptionButton(String title, int value, int? groupValue, ValueChanged<int> onChanged, bool hasError, IconData? icon) {
    bool isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56, 
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4), 
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError && !isSelected 
                ? Colors.red 
                : isSelected ? AppColors.primaryBlue : AppColors.borderLight, 
            width: 1.5
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))] 
            : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: isSelected ? Colors.white : AppColors.textMainTitle, size: 18), 
              const SizedBox(width: 6)
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title, 
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMainTitle, 
                    fontWeight: FontWeight.w600, 
                    fontSize: 14
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}