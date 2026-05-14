import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_colors.dart';
import '../services/database_service.dart';
import '../services/ocr_service.dart'; 
import 'dashboard_screen.dart';

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({super.key});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  bool _isFileSelected = false;
  bool _isProcessing = false; 
  String _fileName = '';
  String _fileSize = '';
  File? _selectedFile;
  
  final ImagePicker _picker = ImagePicker();

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied && mounted) _showSettingsDialog();
    return false;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please enable access in settings to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => openAppSettings(), child: const Text('Settings')),
        ],
      ),
    );
  }

  void _showUploadOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Source', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryBlue),
                title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _requestPermission(Permission.camera)) _pickImage(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBlue),
                title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _requestPermission(Permission.photos)) _pickImage(ImageSource.gallery);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined, color: AppColors.primaryBlue),
                title: const Text('Files (PDF/Images)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  _pickDocument(); 
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      setState(() {
        _isFileSelected = true;
        _selectedFile = file;
        _fileName = pickedFile.name;
        _fileSize = '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB';
      });
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _isFileSelected = true;
        _selectedFile = file;
        _fileName = result.files.first.name;
        _fileSize = '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB';
      });
    }
  }

  void _removeFile() {
    setState(() {
      _isFileSelected = false;
      _selectedFile = null;
      _fileName = '';
      _fileSize = '';
    });
  }

  Future<void> _processFileWithOCR() async {
    if (_selectedFile == null) return;
    if (_fileName.toLowerCase().endsWith('.pdf')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-scan is only available for Images.'), backgroundColor: Colors.orange));
      _showManualEntrySheet();
      return;
    }

    setState(() => _isProcessing = true);
    final resultMap = await OcrService().processMedicalImage(_selectedFile!);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (resultMap != null) {
      _showOCRConfirmationDialog(resultMap);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not detect exact results.'), backgroundColor: Colors.orange));
      _showManualEntrySheet();
    }
  }

  void _showOCRConfirmationDialog(Map<String, dynamic> resultMap) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog( 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Result Found! ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: AppColors.textSubtitle, fontSize: 15, height: 1.5),
            children: [
              const TextSpan(text: 'We scanned your document and found:\n\n'),
              TextSpan(text: '${resultMap['testType']}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
              TextSpan(text: '${resultMap['result']} ${resultMap['unit']}\n\n', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 18)),
              const TextSpan(text: 'Is this correct?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); 
              _showManualEntrySheet(); 
            },
            child: const Text('No, Edit', style: TextStyle(color: AppColors.textSubtitle, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); 
              setState(() => _isProcessing = true);
              
              bool success = await DatabaseService().saveManualReading(
                testType: resultMap['testType'],
                result: resultMap['result'],
                source: 'OCR Scanner', 
              );

              if (!mounted) return; 
              setState(() => _isProcessing = false);
              if (success) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save to database.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Yes, Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showManualEntrySheet() {
    String selectedTest = 'HbA1C'; 
    final TextEditingController valueController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String unitText = selectedTest == 'HbA1C' ? '%' : 'mg/dL';
            String hintText = selectedTest == 'HbA1C' ? 'Enter HbA1c' : 'Enter Fasting Sugar';

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
                              child: Text('Fasting Sugar', style: TextStyle(fontWeight: FontWeight.bold, color: selectedTest == 'Fasting Blood Sugar' ? Colors.white : AppColors.textMainTitle, fontSize: 13)),
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
                              child: Text('HbA1C', style: TextStyle(fontWeight: FontWeight.bold, color: selectedTest == 'HbA1C' ? Colors.white : AppColors.textMainTitle, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('TEST RESULT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(color: AppColors.textSubtitle.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.bgBlueCard, borderRadius: BorderRadius.circular(8)),
                          child: Text(unitText, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, 
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (valueController.text.isNotEmpty) {
                            setSheetState(() => isSaving = true);
                            bool success = await DatabaseService().saveManualReading(
                              testType: selectedTest,
                              result: double.parse(valueController.text),
                            );
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.pop(context);
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
                            } else {
                              setSheetState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save.')));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: isSaving 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        backgroundColor: AppColors.backgroundLight, elevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMainTitle),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
        )
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload Your File', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
              const SizedBox(height: 12),
              const Text('Please upload a JPG, PNG, or PDF of your blood test results.', style: TextStyle(fontSize: 15, color: AppColors.textSubtitle, height: 1.5)),
              const SizedBox(height: 32),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderDashed, width: 1.5)),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: AppColors.textMainTitle, size: 40),
                    const SizedBox(height: 16),
                    const Text('Tap to Select File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMainTitle)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _showUploadOptionsSheet,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.iconBgLight, foregroundColor: AppColors.primaryBlue, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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
                    child: const Text('Enter Manually', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationColor: AppColors.primaryBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              if (_isFileSelected) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.bgFileBlue, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primaryBlue)),
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
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textErrorRed), onPressed: _removeFile),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isFileSelected && !_isProcessing ? _processFileWithOCR : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: _isProcessing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Security Note centered under the button
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: AppColors.textSubtitle, size: 16),
                  SizedBox(width: 6),
                  Text('Your data is encrypted and secure.', style: TextStyle(color: AppColors.textSubtitle, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}