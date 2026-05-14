import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DiabetesRiskService {
  Interpreter? _interpreter;

  // Load the classification model from assets into memory
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/Diabetes_Risk_Classifier.tflite');
      debugPrint('Diabetes Risk Model loaded successfully.');
    } catch (e) {
      debugPrint('Failed to load Diabetes Risk model: $e');
    }
  }

  // Predict diabetes risk probability based on 7 medical inputs
  Future<double?> predictDiabetesRisk({
    required double age,
    required double bmi,
    required double bloodGlucose,
    required double gender,         // 0.0: Female, 1.0: Male
    required double hypertension,   // 0.0: No, 1.0: Yes
    required double heartDisease,   // 0.0: No, 1.0: Yes
    required double smokingHistory, // 0.0: Never, 1.0: Former, 2.0: Current
  }) async {
    if (_interpreter == null) {
      debugPrint('Diabetes Risk Model is not loaded.');
      return null;
    }

    try {
      // Prepare the input matrix matching the exact feature order from Python
      var input = [
        [age, bmi, bloodGlucose, gender, hypertension, heartDisease, smokingHistory]
      ];

      // Prepare a 1x1 matrix to store the sigmoid output (probability between 0 and 1)
      var output = List.filled(1, 0.0).reshape([1, 1]);

      // Execute the model inference
      _interpreter!.run(input, output);

      // Extract the probability result
      double riskProbability = output[0][0];
      
      debugPrint('Predicted Diabetes Risk Probability: $riskProbability');
      return riskProbability;
      
    } catch (e) {
      debugPrint('Error running diabetes risk prediction: $e');
      return null;
    }
  }
  
  // Close the interpreter to free up memory when no longer needed
  void dispose() {
    _interpreter?.close();
  }
}