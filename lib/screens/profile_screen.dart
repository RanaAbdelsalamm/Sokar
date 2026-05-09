import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'upload_file_screen.dart'; 
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variables to hold dynamic data
  bool _isLoading = true;
  String _firstName = "";
  String _fullName = "";
  String _gender = "";
  int _age = 0; 
  int _weight = 0;
  
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Fetch data when screen opens
  }

  // Fetch data from Firebase
  Future<void> _loadProfileData() async {
    Map<String, dynamic>? data = await AuthService().getUserData();
    
    if (data != null && mounted) {
      setState(() {
        _fullName = data['name'] ?? 'Unknown User';
        _firstName = _fullName.split(' ').first; // Extract first name
        _gender = data['gender'] ?? 'Not Specified';
        _weight = (data['weight'] ?? 0).toInt();

        // Calculate age from birthDate Timestamp
        if (data['birthDate'] != null) {
          DateTime birthDate = (data['birthDate'] as Timestamp).toDate();
          _age = _calculateAge(birthDate);
        }
        
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to calculate accurate age
  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _showEditDialog(String title, int currentValue, String unit, Function(int) onSave) {
    final TextEditingController controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit $title', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter your $title',
              suffixText: unit,
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSubtitle)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSave(int.parse(controller.text));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: AppColors.textSubtitle, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No', style: TextStyle(color: AppColors.textSubtitle, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut(); // Actual Firebase Signout
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()), 
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openGallery() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _profileImage = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading screen while fetching data
      return Container(
        color: AppColors.backgroundLight,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.textMainTitle, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ),
                
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        image: _profileImage != null
                            ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImage == null
                          ? const Icon(Icons.person, size: 60, color: AppColors.primaryBlue)
                          : null,
                    ),
                    GestureDetector(
                      onTap: _openGallery,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue, 
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _firstName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMainTitle),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(title: 'FULL NAME', value: _fullName, icon: Icons.badge_outlined, isEditable: false),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.bgTabInactive, height: 1)),
                      
                      // Age is not editable because it depends on the birth date
                      _buildInfoRow(
                        title: 'AGE', value: '$_age', unit: 'years', icon: Icons.calendar_month_outlined, isEditable: false,
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.bgTabInactive, height: 1)),
                      
                      // Weight is editable, and it saves to Firebase!
                      _buildInfoRow(
                        title: 'WEIGHT', value: '$_weight', unit: 'kg', icon: Icons.monitor_weight_outlined, isEditable: true,
                        onTap: () => _showEditDialog('Weight', _weight, 'kg', (val) async {
                          setState(() => _weight = val); // Update UI locally
                          await AuthService().updateUserData({'weight': val}); // Update Database
                        }),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.bgTabInactive, height: 1)),
                      
                      _buildInfoRow(
                        title: 'GENDER', 
                        value: _gender, 
                        icon: _gender.toLowerCase() == 'female' ? Icons.female : Icons.male, 
                        isEditable: false
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),

                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadFileScreen()));
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(color: AppColors.chartLineBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      const Text('Upload New Test', style: TextStyle(color: AppColors.chartLineBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text(
                        'Your data is encrypted and used only for your insights.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textSubtitle),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40), 
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String title, required String value, String unit = '', IconData? icon, required bool isEditable, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: isEditable ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(unit, style: const TextStyle(fontSize: 14, color: AppColors.textSubtitle)),
                    ]
                  ],
                ),
              ],
            ),
          ),
          if (icon != null)
            Icon(icon, color: AppColors.textSubtitle, size: 20),
        ],
      ),
    );
  }
}