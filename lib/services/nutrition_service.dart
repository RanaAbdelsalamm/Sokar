import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'database_service.dart';
import '../constants/api_keys.dart';

class NutritionService {
  final DatabaseService _db = DatabaseService();

  static Map<String, dynamic> get _fallbackPlan => {
        'target_carbs': 180,
        'target_calories': 1800,
        'breakfast': {
          'description': 'Oatmeal with fresh berries, a handful of walnuts, and a sprinkle of cinnamon',
          'calories': 350,
          'carbs': 45
        },
        'lunch': {
          'description': 'Grilled chicken breast with roasted vegetables and a small portion of brown rice',
          'calories': 550,
          'carbs': 50
        },
        'dinner': {
          'description': 'Baked salmon with steamed broccoli and quinoa salad',
          'calories': 600,
          'carbs': 55
        },
        'foods_to_eat': [
          'Leafy greens (spinach, kale)',
          'Non-starchy vegetables',
          'Lean proteins (chicken, fish)',
          'Whole grains in moderation'
        ],
        'foods_to_avoid': [
          'Sugary beverages and juices',
          'White bread and refined carbs',
          'Fried and processed foods',
          'High-sugar desserts'
        ],
      };

  Future<Map<String, dynamic>> generateDailyPlan() async {
    try {
      final results = await Future.wait([
        _db.getUserProfile(),
        _db.getRecentGlucoseReadings(1), 
        _db.getDailyNutrition(),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final glucoseDocs = results[1] as List<QueryDocumentSnapshot>;
      final todayNutrition = results[2] as Map<String, double>;

      String glucoseTrend;
      if (glucoseDocs.isEmpty) {
        glucoseTrend = 'No glucose readings available in the last 24 hours.';
      } else {
        final readings = glucoseDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final value = (data['result'] as num?)?.toDouble() ?? 0.0;
          final ts = data['timestamp'] as Timestamp?;
          final time = ts != null
              ? ts.toDate().toLocal().toString()
              : 'unknown time';
          return '  - $value mg/dL at $time';
        }).join('\n');
        glucoseTrend =
            'Glucose readings from the last 24 hours (oldest -> newest):\n$readings';
      }

      final name = profile?['name'] ?? 'User';
      final age = profile?['age'] ?? 'unknown';
      final gender = profile?['gender'] ?? 'unknown';
      final weight = profile?['weight'] ?? 'unknown';
      final height = profile?['height'] ?? 'unknown';
      final diabetesType = profile?['diabetes_type'] ?? 'Type 2';
      final hypertension = profile?['hypertension'] == 1 ? 'Yes' : 'No';
      final heartDisease = profile?['heart_disease'] == 1 ? 'Yes' : 'No';

      final consumedCarbs = todayNutrition['carbs'] ?? 0.0;
      final consumedCalories = todayNutrition['calories'] ?? 0.0;

      final today = DateTime.now();
      final daySeed = '${today.year}-${today.month}-${today.day}';

      final systemPrompt = '''
You are an expert clinical nutritionist who specializes in diabetes management.
Your task is to generate a UNIQUE, highly personalized daily meal plan.

==== PATIENT DATA ====
- Name: $name
- Age: $age | Gender: $gender
- Weight: $weight kg | Height: $height cm
- Diabetes type: $diabetesType
- Comorbidities: Hypertension: $hypertension, Heart Disease: $heartDisease

==== 24-HOUR GLUCOSE TREND ====
$glucoseTrend

==== TODAY'S CONSUMED NUTRITION SO FAR ====
- Carbs consumed today: ${consumedCarbs.toStringAsFixed(1)} g
- Calories consumed today: ${consumedCalories.toStringAsFixed(1)} kcal

==== CRITICAL ANALYSIS INSTRUCTIONS ====
1. Carefully analyze the 24-hour glucose trend above.
   - If readings are consistently HIGH (>180 mg/dL): prescribe a VERY LOW-CARB plan, prioritize non-starchy vegetables, lean proteins, and healthy fats. Target carbs should be significantly reduced.
   - If readings are LOW (<70 mg/dL): include moderate complex carbs with each meal to stabilize levels. Add snacks between meals.
   - If readings are STABLE (70-140 mg/dL): provide a balanced diabetic-friendly plan.
   - If NO readings exist: create a moderate, safe plan.
2. Account for the carbs and calories ALREADY consumed today when setting targets.
3. Meals MUST be culturally diverse and variable. Today's seed is "$daySeed" — use it as inspiration to pick a cuisine or regional style. Do NOT repeat the same generic "grilled chicken and vegetables" meals. Think Egyptian, Mediterranean, Asian, Latin American, Indian, etc.

==== OUTPUT FORMAT (STRICTLY ENFORCED) ====
Respond with ONLY a valid JSON object. Do NOT wrap it in markdown code fences. Do NOT add any text before or after the JSON. 

{
  "target_carbs": <number: calculated daily carb target in grams>,
  "target_calories": <number: calculated daily calorie target in kcal>,
  "breakfast": {
    "description": "<string: detailed meal description with portions>",
    "calories": <number: estimated calories>,
    "carbs": <number: estimated carbs>
  },
  "lunch": {
    "description": "<string: detailed meal description with portions>",
    "calories": <number: estimated calories>,
    "carbs": <number: estimated carbs>
  },
  "dinner": {
    "description": "<string: detailed meal description with portions>",
    "calories": <number: estimated calories>,
    "carbs": <number: estimated carbs>
  },
  "foods_to_eat": ["<food 1>", "<food 2>", "<food 3>", "<food 4>"],
  "foods_to_avoid": ["<food 1>", "<food 2>", "<food 3>", "<food 4>"]
}

Remember: Every value must be dynamically calculated based on the patient data.
''';

      final apiKey = ApiKeys.groqKey;

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {
              "role": "user", 
              "content": "Generate my personalized meal plan for today based on all the data you have about me. Return strictly JSON."
            }
          ],
          "response_format": {"type": "json_object"},
          "temperature": 0.7,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Groq API Error: ${response.statusCode}');
        return _fallbackPlan;
      }

      final data = jsonDecode(response.body);
      final rawText = data['choices'][0]['message']['content'];

      if (rawText == null || rawText.trim().isEmpty) {
        debugPrint('NutritionService: Empty response from Groq.');
        return _fallbackPlan;
      }

      String cleaned = rawText.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'\s*```$'), '');
      }

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      final requiredKeys = [
        'target_carbs',
        'target_calories',
        'breakfast',
        'lunch',
        'dinner',
        'foods_to_eat',
        'foods_to_avoid',
      ];
      
      for (final key in requiredKeys) {
        if (!parsed.containsKey(key)) {
          debugPrint('NutritionService: Missing key in AI response.');
          return _fallbackPlan;
        }
      }

      return parsed;
    } catch (e) {
      debugPrint('NutritionService error: $e');
      return _fallbackPlan;
    }
  }
}