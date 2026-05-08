import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import 'dashboard_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({super.key});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  bool _isFileSelected = false;
  String _fileName = '';
  String _fileSize = '';

  Future<void> _pickFile() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,   
      Permission.storage,  
      Permission.camera,   
    ].request();

    if (statuses[Permission.photos]!.isGranted || 
        statuses[Permission.storage]!.isGranted || 
        statuses[Permission.photos]!.isLimited) {
          
       FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        final file = result.files.first;
        
        final double sizeInMb = file.size / (1024 * 1024);
        
        setState(() {
          _isFileSelected = true;
          _fileName = file.name;
          _fileSize = '${sizeInMb.toStringAsFixed(2)} MB';
        });
      }
      
    } else if (statuses[Permission.photos]!.isPermanentlyDenied || 
               statuses[Permission.storage]!.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _removeFile() {
    setState(() {
      _isFileSelected = false;
      _fileName = '';
      _fileSize = '';
    });
  }

  void _showManualEntrySheet() {
    String selectedTest = 'Fasting Blood Sugar';
    final TextEditingController valueController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String unitText = selectedTest == 'HbA1C' ? '%' : 'mg/dL';
            String hintText = selectedTest == 'HbA1C' ? 'e.g. 5.7' : 'e.g. 95';

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Manual Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textMainTitle)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('TEST TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedTest = 'Fasting Blood Sugar'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedTest == 'Fasting Blood Sugar' ? AppColors.primaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selectedTest == 'Fasting Blood Sugar' ? AppColors.primaryBlue : AppColors.borderLight),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Fasting Sugar', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: selectedTest == 'Fasting Blood Sugar' ? Colors.white : AppColors.textMainTitle,
                                  fontSize: 13
                                )
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedTest = 'HbA1C'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedTest == 'HbA1C' ? AppColors.primaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selectedTest == 'HbA1C' ? AppColors.primaryBlue : AppColors.borderLight),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'HbA1C', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: selectedTest == 'HbA1C' ? Colors.white : AppColors.textMainTitle,
                                  fontSize: 13
                                )
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('TEST RESULT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
                      child: TextField(
                        controller: valueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: TextStyle(color: AppColors.textSubtitle.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.bgBlueCard, borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(unitText, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, 
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (valueController.text.isNotEmpty) {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                          elevation: 0
                        ),
                        child: const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
              const Text('Please upload a JPG, PNG, or PDF of your\nblood test results. Your privacy is our priority.', style: TextStyle(fontSize: 15, color: AppColors.textSubtitle, height: 1.5)),
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
                      onPressed: _pickFile,
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have a file? ', style: TextStyle(color: AppColors.textSubtitle)),
                  GestureDetector(
                    onTap: _showManualEntrySheet,
                    child: const Text(
                      'Enter Manually',
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
                          children: [
                            Text(_fileName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMainTitle), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(_fileSize, style: const TextStyle(fontSize: 12, color: AppColors.textSubtitle)),
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