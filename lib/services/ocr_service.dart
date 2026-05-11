import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  Future<Map<String, dynamic>?> processMedicalImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String fullText = recognizedText.text.toLowerCase();
      textRecognizer.close();

      fullText = fullText.replaceAll('*', '');
      fullText = fullText.replaceAllMapped(RegExp(r'(\d)\s*[.,]\s*(\d)'), (match) => '${match.group(1)}.${match.group(2)}');

      debugPrint("====== OCR FULL TEXT ======\n$fullText\n===========================");

      bool isHbA1c = RegExp(r'(hba1c|a1c|a1-c|glycosylated|prediabetic|diabetic)').hasMatch(fullText);
      bool isFasting = RegExp(r'(fasting|fbs|glucose|sugar)').hasMatch(fullText);

      // The Golden Key: Find where 'result' starts and ignore everything before it
      int anchorIdx = _indexOfKeyword(fullText, ['result', 'results', 'value']);
      String targetText = anchorIdx != -1 ? fullText.substring(anchorIdx) : fullText;

      if (isHbA1c) {
        Iterable<Match> matches = RegExp(r'(?<!\d)([4-9]\.\d{1,2}|1[0-5]\.\d{1,2})(?!\d)').allMatches(targetText);
        List<String> ignoreRanges = ['4.4', '4.40', '4.5', '4.6', '4.60', '5.4', '5.5', '5.50', '5.6', '5.60', '5.7', '5.70', '6.4', '6.40', '6.5', '6.50', '6.8', '6.80', '7.6', '7.60'];

        for (Match m in matches) {
          String numStr = m.group(1)!;
          if (anchorIdx != -1 || !ignoreRanges.contains(numStr)) {
            debugPrint("SUCCESS: Extracted HbA1c -> $numStr");
            return {'testType': 'HbA1C', 'result': double.parse(numStr), 'unit': '%'};
          }
        }
      }

      if (isFasting) {
        Iterable<Match> matches = RegExp(r'(?<!-\s*)(?<!\d)([4-9]\d|[1-4]\d{2}(?:\.\d{1,2})?)(?!\d)(?!\s*-|\s*[y]\b|\s*/)').allMatches(targetText);
        List<String> ignoreRanges = ['70', '70.0', '99', '99.0', '100', '100.0', '110', '125', '126', '140', '140.0'];

        for (Match m in matches) {
          String numStr = m.group(1)!;
          if (anchorIdx != -1 || !ignoreRanges.contains(numStr)) {
            debugPrint("SUCCESS: Extracted Fasting -> $numStr");
            return {'testType': 'Fasting Blood Sugar', 'result': double.parse(numStr), 'unit': 'mg/dL'};
          }
        }
      }

      debugPrint("FAILED: Could not extract result.");
      return null;
    } catch (e) {
      debugPrint("OCR Error: $e");
      return null;
    }
  }

  int _indexOfKeyword(String text, List<String> keywords) {
    int earliestIndex = -1;
    for (String kw in keywords) {
      int idx = text.indexOf(kw);
      if (idx != -1 && (earliestIndex == -1 || idx < earliestIndex)) {
        earliestIndex = idx;
      }
    }
    return earliestIndex;
  }
}