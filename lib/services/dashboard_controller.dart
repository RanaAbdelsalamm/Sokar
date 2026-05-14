import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import 'ml_services/hba1c_estimator_service.dart';
import 'ml_services/diabetes_risk_service.dart';

class DashboardController {
  final DatabaseService _db = DatabaseService();
  final HbA1cEstimatorService _hba1cAI = HbA1cEstimatorService();
  final DiabetesRiskService _riskAI = DiabetesRiskService();

  Future<void> initAI() async {
    await _hba1cAI.loadModel();
    await _riskAI.loadModel();
  }

  int _calculateAge(dynamic birthDate) {
    if (birthDate != null && birthDate is Timestamp) {
      DateTime dob = birthDate.toDate();
      DateTime today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    }
    return 40; 
  }

  double _parseNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<Map<String, dynamic>> getDashboardState(int chartDays) async {
    final profile = await _db.getUserProfile();
    final latestHbA1c = await _db.getLatestHbA1c();
    final glucoseAvg = await _db.getBloodGlucoseAverage();
    final recentReadings = await _db.getRecentGlucoseReadings(chartDays);
    
    double? finalHbA1c = latestHbA1c;
    bool isPredicted = false;
    double? latestGlucose;
    DateTime? latestGlucoseTime;

    if (recentReadings.isNotEmpty) {
      var lastDoc = recentReadings.last.data() as Map<String, dynamic>;
      latestGlucose = lastDoc['result']?.toDouble();
      latestGlucoseTime = (lastDoc['timestamp'] as Timestamp?)?.toDate();
    }

    double mappedAge = _calculateAge(profile?['birthDate']).toDouble();
    double mappedBmi = _parseNumber(profile?['bmi'] ?? 25.0);
    double mappedGender = _parseNumber(profile?['gender']);
    double mappedHypertension = _parseNumber(profile?['hypertension']);
    double mappedHeartDisease = _parseNumber(profile?['heart_disease'] ?? profile?['heartDisease']);
    double mappedSmoking = _parseNumber(profile?['smoking_history'] ?? _mapSmoking(profile?['smokingStatus'] ?? 'never'));

    if (finalHbA1c == null && latestGlucose != null) {
      finalHbA1c = await _hba1cAI.predictHbA1c(
        age: mappedAge,
        bmi: mappedBmi,
        bloodGlucose: latestGlucose,
        gender: mappedGender,
        hypertension: mappedHypertension,
        heartDisease: mappedHeartDisease,
        smokingHistory: mappedSmoking,
      );
      if (finalHbA1c != null) {
        finalHbA1c = double.parse(finalHbA1c.toStringAsFixed(1));
        isPredicted = true;
      }
    }

    double timeInRange = 0.0;
    if (recentReadings.isNotEmpty) {
      int inRangeCount = 0;
      for (var doc in recentReadings) {
        double val = (doc.data() as Map<String, dynamic>)['result'].toDouble();
        if (val >= 70 && val <= 140) inRangeCount++;
      }
      timeInRange = (inRangeCount / recentReadings.length) * 100;
    }

    return {
      'latestHbA1c': finalHbA1c,
      'isPredicted': isPredicted,
      'glucoseAvg': glucoseAvg,
      'latestGlucose': latestGlucose,
      'latestGlucoseTime': latestGlucoseTime,
      'timeInRange': timeInRange,
      'chartData': recentReadings,
      'profile': profile,
    };
  }

  Future<double?> calculateDiabetesRisk() async {
    final profile = await _db.getUserProfile();
    final glucoseAvg = await _db.getBloodGlucoseAverage();
    final latestHbA1c = await _db.getLatestHbA1c();

    final recentReadings = await _db.getRecentGlucoseReadings(1);
    double? latestGlucose;
    if (recentReadings.isNotEmpty) {
      latestGlucose = (recentReadings.last.data() as Map<String, dynamic>)['result']?.toDouble();
    }

    // Clinical Override Logic
    if ((latestGlucose != null && latestGlucose > 200) || (latestHbA1c != null && latestHbA1c >= 6.5)) {
      return 0.99; 
    }

    double mappedAge = _calculateAge(profile?['birthDate']).toDouble();
    double mappedBmi = _parseNumber(profile?['bmi'] ?? 25.0);
    double mappedGender = _parseNumber(profile?['gender']);
    double mappedHypertension = _parseNumber(profile?['hypertension']);
    double mappedHeartDisease = _parseNumber(profile?['heart_disease'] ?? profile?['heartDisease']);
    double mappedSmoking = _parseNumber(profile?['smoking_history'] ?? _mapSmoking(profile?['smokingStatus'] ?? 'never'));

    return await _riskAI.predictDiabetesRisk(
      age: mappedAge,
      bmi: mappedBmi,
      bloodGlucose: glucoseAvg == 0.0 ? 100.0 : glucoseAvg,
      gender: mappedGender,
      hypertension: mappedHypertension,
      heartDisease: mappedHeartDisease,
      smokingHistory: mappedSmoking,
    );
  }

  double _mapSmoking(String status) {
    switch (status.toLowerCase()) {
      case 'never': return 0.0;
      case 'former': return 1.0;
      case 'current': return 2.0;
      default: return 0.0;
    }
  }

  void dispose() {
    _hba1cAI.dispose();
    _riskAI.dispose();
  }
}