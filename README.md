# Sokar (سُكَّر) - Smart Diabetes Management App 🩸

**Sokar** is a comprehensive, AI-powered Flutter application designed to provide an intelligent health companion experience for diabetes management. Developed as a graduation project, the app seamlessly integrates cutting-edge Generative AI, on-device Machine Learning, Optical Character Recognition (OCR), and robust cloud architecture.

---

## ✨ Key Features & Modules

* **🤖 AI Health Assistant (Sokar Bot):** Powered by the ultra-fast Groq API (Llama 3.3 70B versatile), offering real-time, context-aware health advice based on the user's recent glucose readings, activity, and medical profile.
* **🥗 Smart Nutrition Generation:** Dynamically generated daily meal plans with precise carb and calorie targets, customized using the user's 24-hour glucose trends.
* **🔍 Smart Data Extraction (OCR):** Integrated **Google ML Kit** for Optical Character Recognition. Users can easily scan lab reports or glucose meter screens to automatically extract readings without manual data entry.
* **📊 Predictive ML Models:** On-device **TensorFlow Lite** integration featuring two custom models:
  * `Diabetes_Risk_Classifier.tflite`: Predicts the risk level of diabetes based on user health metrics.
  * `HbA1c_Final_Estimator.tflite`: Estimates HbA1c levels without requiring immediate lab tests.
* **⏰ Advanced Medication Reminders:** A robust local notification system (using `flutter_local_notifications` and `timezone`) for pills, insulin, and liquids. Features customizable schedules, daily/weekly repeats, and swipe-to-log actions.
* **🔐 Secure Authentication & Cloud Sync:** Complete integration with **Firebase Authentication** for secure logins and **Cloud Firestore** for real-time synchronization of user profiles, nutrition tracking, and medication history.
* **📈 Interactive Health Dashboard:** Visualizing glucose trends and health statistics using `fl_chart` for easy monitoring.

---

## 🛠️ Tech Stack & Dependencies

### Core Technologies
* **Framework:** Flutter (Dart) - SDK ^3.11.5
* **Backend:** Firebase (Core, Auth, Firestore)
* **Architecture:** Modular MVC/Service-based Architecture

### Artificial Intelligence & Machine Learning
* **Generative AI:** Groq Cloud API (HTTP integration)
* **Machine Learning:** `tflite_flutter`
* **Computer Vision:** `google_mlkit_text_recognition` & `image_picker`

### Utilities & Tools
* **State Management:** Provider / Custom Controllers (`dartz` for error handling)
* **Notifications:** `flutter_local_notifications`, `timezone`, `flutter_timezone`
* **UI/UX:** `cupertino_icons`, `fl_chart`
* **File Handling:** `file_picker`, `share_plus`

---

## 📁 Project Architecture

The project follows a highly modular structure for scalability and maintainability:

```text
lib/
 ├── constants/       # App colors, styles, and API keys
 ├── screens/         # UI Views (Dashboard, Plan, Reminders, Auth, OCR, etc.)
 ├── services/        # Core logic and API integration
 │   ├── ml_services/ # TFLite integration classes
 │   ├── auth_service.dart
 │   ├── chatbot_service.dart
 │   ├── database_service.dart
 │   ├── nutrition_service.dart
 │   └── ocr_service.dart
 └── widgets/         # Reusable custom UI components
```

---

## 🚀 Getting Started

Follow these instructions to build and run the project locally.

### Prerequisites

* Flutter SDK (latest stable version)
* Android Studio or VS Code
* An active Firebase project (ensure `google-services.json` is added to `android/app`)

### 👩🏻‍💻 Installation

1. Clone the repository:

```bash
git clone https://github.com/RanaAbdelsalamm/Sokar.git
cd Sokar
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure API Keys:

Create a new file at `lib/constants/api_keys.dart` and securely add your Groq API key:

```dart
class ApiKeys {
  static const String groqKey = 'YOUR_GROQ_API_KEY_HERE';
}
```

4. Run the application:

Connect a physical device or emulator and run:

```bash
flutter run
```

> 📌 **Note on Permissions:** The app requires Camera and Storage permissions for the OCR functionality, and Notification permissions for the medication reminders.

---

Developed as a graduation project to empower patients and simplify diabetes management through Artificial Intelligence 🩵.