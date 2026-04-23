import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;

  // Load model from assets folder
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/sokar_model.tflite');
      debugPrint('ML Model loaded successfully.');
    } catch (e) {
      debugPrint('Error loading ML model: $e');
    }
  }

  // Predict diabetes risk based on 8 medical features
  Future<double> predictDiabetes(List<double> inputFeatures) async {
    if (_interpreter == null) {
      debugPrint('Warning: Model not loaded yet.');
      return 0.0;
    }

    // Format input for the model (1 row, 8 columns)
    var input = [inputFeatures];
    
    // Prepare output shape (1 row, 1 column)
    var output = List.filled(1, 0.0).reshape([1, 1]);

    // Run inference
    _interpreter!.run(input, output);

    return output[0][0];
  }
}