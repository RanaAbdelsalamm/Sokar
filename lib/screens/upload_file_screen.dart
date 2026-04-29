import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dashboard_screen.dart'; // سطر الاستدعاء للداشبورد

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({super.key});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  bool _isFileSelected = false;

  void _simulateFileSelection() {
    setState(() {
      _isFileSelected = true;
    });
  }

  void _removeFile() {
    setState(() {
      _isFileSelected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload Your File', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
              const SizedBox(height: 12),
              const Text('Please upload a JPG, or PNG of your\nblood test results. Your privacy is our priority.', style: TextStyle(fontSize: 15, color: AppColors.textSubtitle, height: 1.5)),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderDashed, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: AppColors.textMainTitle, size: 40),
                    const SizedBox(height: 16),
                    const Text('Tap to Select File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                    const SizedBox(height: 8),
                    const Text('Choose a document from your device', style: TextStyle(fontSize: 13, color: AppColors.textSubtitle)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _simulateFileSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.iconBgLight, 
                        foregroundColor: AppColors.primaryBlue, 
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Select File', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              if (_isFileSelected) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.bgFileBlue, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('blood_test_results_q4.png', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMainTitle), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 4),
                            Text('1.2 MB', style: TextStyle(fontSize: 12, color: AppColors.textSubtitle)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textErrorRed),
                        onPressed: _removeFile,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Row(
                children: const [
                  Icon(Icons.lock_outline, color: AppColors.textSubtitle, size: 18),
                  SizedBox(width: 8),
                  Text('Your data is encrypted and secure.', style: TextStyle(color: AppColors.textSubtitle, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isFileSelected ? () {
                    // الكود ده هو اللي بينقلنا للداشبورد لما تدوسي Submit
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Submit Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}