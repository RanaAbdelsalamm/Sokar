import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Fetch current user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    return null;
  }

  // 2. Update specific user field in Firestore (e.g., Weight, Height, BMI)
  Future<void> updateUserData(Map<String, dynamic> dataToUpdate) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update(dataToUpdate);
      }
    } catch (e) {
      debugPrint("Error updating user data: $e");
    }
  }

  // 3. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. Check if email is verified
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); 
      return user.emailVerified;
    }
    return false;
  }

  // 5. Resend verification link
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // 6. Registration Logic (UPDATED WITH HEIGHT, BMI, AND MEDICAL QUESTIONS)
  Future<String> signUpUser({
    required String name,
    required String email,
    required String password,
    required double weight,
    required double height,
    required DateTime birthDate,
    required int gender, // 0 = Female, 1 = Male
    required int smokingHistory, // 0 = never, 1 = former, 2 = current
    required int hypertension, // 0 = No, 1 = Yes
    required int heartDisease, // 0 = No, 1 = Yes
  }) async {
    String res = "An error occurred";
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

      // BMI Calculation Logic (Height is in cm, convert to meters)
      double heightInMeters = height / 100;
      double calculatedBmi = weight / (heightInMeters * heightInMeters);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'weight': weight,
        'height': height,
        'bmi': double.parse(calculatedBmi.toStringAsFixed(2)), // Clean format
        'birthDate': birthDate,
        'gender': gender, // Saving as 0 or 1 directly for the ML Model
        'smoking_history': smokingHistory,
        'hypertension': hypertension,
        'heart_disease': heartDisease,
        'createdAt': FieldValue.serverTimestamp(),
      });

      res = "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        res = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        res = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        res = 'The email address is badly formatted.';
      } else {
        res = e.message ?? "Authentication Error";
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // 7. Login Logic
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    // ... existing login logic remains the same
    String res = "An error occurred";
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      res = "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        res = 'User not found or incorrect password.';
      } else {
        res = e.message ?? "Authentication Error";
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // 8. Reset Password Logic
  Future<String> resetPassword({required String email}) async {
    // ... existing reset logic remains the same
    String res = "An error occurred";
    try {
      await _auth.sendPasswordResetEmail(email: email);
      res = "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        res = "No account found for this email.";
      } else {
        res = e.message ?? "An error occurred";
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }
}