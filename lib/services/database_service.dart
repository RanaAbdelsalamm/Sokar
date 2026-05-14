import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 01. Save manual test reading to Firestore
  Future<bool> saveManualReading({
    required String testType, 
    required double result, 
    String source = 'Manual'
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('readings')
            .add({
          'testType': testType, 
          'result': result,
          'timestamp': FieldValue.serverTimestamp(),
          'source': source, 
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error saving reading: $e");
      return false;
    }
  }

  // 02. Fetch the LATEST HbA1c reading
  Future<double?> getLatestHbA1c() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot query = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('readings')
            .orderBy('timestamp', descending: true)
            .limit(30)
            .get();

        for (var doc in query.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String type = data['testType'] ?? '';
          if (type == 'HbA1c' || type == 'HbA1C') {
            return data['result']?.toDouble();
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching latest HbA1c: $e");
      return null;
    }
  }

  // 03. Fetch Blood Glucose Average
  Future<double> getBloodGlucoseAverage() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot query = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('readings')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();

        List<double> glucoseReadings = [];
        for (var doc in query.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String type = data['testType'] ?? '';
          if (type == 'BloodGlucose' || type == 'Fasting Blood Sugar' || type == 'Fasting Sugar') {
            glucoseReadings.add(data['result']?.toDouble() ?? 0.0);
            if (glucoseReadings.length == 10) break;
          }
        }

        if (glucoseReadings.isNotEmpty) {
          double total = glucoseReadings.fold(0.0, (currentTotal, item) => currentTotal + item);          
          return double.parse((total / glucoseReadings.length).toStringAsFixed(2));
        }
      }
      return 0.0; 
    } catch (e) {
      debugPrint("Error fetching glucose average: $e");
      return 0.0;
    }
  }

  // 04. Fetch User Profile for AI Models
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      return null;
    }
  }

  // 05. Fetch Recent Glucose Readings for Chart
  Future<List<QueryDocumentSnapshot>> getRecentGlucoseReadings(int days) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DateTime startDate = DateTime.now().subtract(Duration(days: days));
        QuerySnapshot query = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('readings')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .orderBy('timestamp', descending: false)
            .get();

        List<QueryDocumentSnapshot> filteredDocs = [];
        for (var doc in query.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String type = data['testType'] ?? '';
          if (type == 'BloodGlucose' || type == 'Fasting Blood Sugar' || type == 'Fasting Sugar' || type == 'Fasting & PP Sugar') {
            filteredDocs.add(doc);
          }
        }
        return filteredDocs;
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching chart readings: $e");
      return [];
    }
  }

  // 06. Save or update daily consumed carbohydrates and calories
  Future<bool> saveDailyNutrition(double carbs, double calories) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('daily_nutrition')
            .doc(dateKey)
            .set({
          'carbs': carbs,
          'calories': calories,
          'date': dateKey,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error saving daily nutrition: $e");
      return false;
    }
  }

  // 07. Fetch today's consumed carbohydrates and calories
  Future<Map<String, double>> getDailyNutrition() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('daily_nutrition')
            .doc(dateKey)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'carbs': (data['carbs'] as num?)?.toDouble() ?? 0.0,
            'calories': (data['calories'] as num?)?.toDouble() ?? 0.0,
          };
        }
      }
      return {'carbs': 0.0, 'calories': 0.0};
    } catch (e) {
      debugPrint("Error fetching daily nutrition: $e");
      return {'carbs': 0.0, 'calories': 0.0};
    }
  }

  // 08. Add a new Medication Reminder
  Future<void> addReminder(Map<String, dynamic> reminderData) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .add(reminderData);
      }
    } catch (e) {
      debugPrint("Error adding reminder: $e");
    }
  }

  // 09. Get real-time stream of Reminders
  Stream<QuerySnapshot> getRemindersStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .snapshots();
    }
    return const Stream.empty();
  }

  // 10. Update specific fields in a Reminder document
  Future<void> updateReminderField(String docId, Map<String, dynamic> data) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(docId)
            .update(data);
      }
    } catch (e) {
      debugPrint("Error updating reminder: $e");
    }
  }

  // 11. Delete a Reminder document completely
  Future<void> deleteReminder(String docId) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(docId)
            .delete();
      }
    } catch (e) {
      debugPrint("Error deleting reminder: $e");
    }
  }
}