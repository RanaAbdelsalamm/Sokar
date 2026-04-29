import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'upload_file_screen.dart'; 
import 'login_screen.dart'; // <--- الاستدعاء بتاع صفحة اللوجين

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _firstName = "Rana";
  final String _fullName = "Rana Abdelsalam";
  final String _gender = "Female";
  
  // الأرقام اتحدثت لتطابق التصميم
  int _age = 22; 
  int _weight = 63;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.chartLineBlue, 
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
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
                    
                    _buildInfoRow(
                      title: 'AGE', value: '$_age', unit: 'years', icon: Icons.calendar_month_outlined, isEditable: true,
                      onTap: () => _showEditDialog('Age', _age, 'years', (val) => setState(() => _age = val)),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.bgTabInactive, height: 1)),
                    
                    _buildInfoRow(
                      title: 'WEIGHT', value: '$_weight', unit: 'kg', icon: Icons.monitor_weight_outlined, isEditable: true,
                      onTap: () => _showEditDialog('Weight', _weight, 'kg', (val) => setState(() => _weight = val)),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.bgTabInactive, height: 1)),
                    
                    _buildInfoRow(title: 'GENDER', value: _gender, icon: null, isEditable: false),
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
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: AppColors.chartLineBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text('Upload New Test / Reading', style: TextStyle(color: AppColors.chartLineBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // تعديل اللينك عشان يودي لصفحة اللوجين الصح
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()), 
                    (Route<dynamic> route) => false,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: AppColors.textMainTitle),
                    SizedBox(width: 8),
                    Text('Log Out', style: TextStyle(color: AppColors.textMainTitle, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 120), 
            ],
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