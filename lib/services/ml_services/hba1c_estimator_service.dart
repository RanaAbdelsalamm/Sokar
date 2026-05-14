import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HbA1cEstimatorService {
  Interpreter? _interpreter;

  // Load the regression model from assets into memory
  Future<void> loadModel() async {
    try {
      // Ensure the file name exactly matches the one in your assets folder
      _interpreter = await Interpreter.fromAsset('assets/models/HbA1c_Final_Estimator.tflite');
      debugPrint('HbA1c Model loaded successfully.');
    } catch (e) {
      debugPrint('Failed to load HbA1c model: $e');
    }
  }

  // Predict HbA1c percentage based on 7 medical inputs
  Future<double?> predictHbA1c({
    required double age,
    required double bmi,
    required double bloodGlucose,
    required double gender,         // 0.0: Female, 1.0: Male
    required double hypertension,   // 0.0: No, 1.0: Yes
    required double heartDisease,   // 0.0: No, 1.0: Yes
    required double smokingHistory, // 0.0: Never, 1.0: Former, 2.0: Current
  }) async {
    if (_interpreter == null) {
      debugPrint('HbA1c Model is not loaded.');
      return null;
    }

    try {
      // Prepare the input matrix matching the exact feature order from Python
      var input = [
        [age, bmi, bloodGlucose, gender, hypertension, heartDisease, smokingHistory]
      ];

      // Prepare a 1x1 matrix to store the regression output
      var output = List.filled(1, 0.0).reshape([1, 1]);

      // Execute the model inference
      _interpreter!.run(input, output);

      // Extract the predicted HbA1c result
      double predictedHbA1c = output[0][0];
      
      debugPrint('Predicted HbA1c: $predictedHbA1c');
      return predictedHbA1c;
      
    } catch (e) {
      debugPrint('Error running HbA1c prediction: $e');
      return null;
    }
  }
  
  // Close the interpreter to free up memory when no longer needed
  void dispose() {
    _interpreter?.close();
  }
}