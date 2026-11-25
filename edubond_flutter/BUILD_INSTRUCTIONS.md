# BUILD INSTRUCTIONS: EDUBOND FLUTTER

Step-by-step instructions for testing, analyzing, and building the EduBond Flutter application.

---

## 1. Prerequisites

- **Flutter SDK:** Version 3.38+ / Dart 3.10+
- **Java Development Kit (JDK):** Version 17+ (e.g. OpenJDK 17)
- **Android SDK:** Platform 34 & 36 installed with command-line tools
- **CMake:** Version 3.22.1+ (automatically managed by Flutter/Gradle)
- **NDK:** Version 28.2+

---

## 2. Environment Setup

From the project root:

```bash
cd edubond_flutter
```

Ensure all dependencies are retrieved:

```bash
flutter pub get
```

---

## 3. Static Analysis & Code Verification

Run Flutter analyzer to ensure zero issues across all Dart source and test files:

```bash
flutter analyze
```

Expected result:
```
Analyzing edubond_flutter...
No issues found!
```

---

## 4. Running Automated Tests

Run the complete 43-test suite across unit, widget, and integration specifications:

```bash
flutter test
```

To run individual test suites:

- **Authentication & Sessions:**
  ```bash
  flutter test test/auth_test.dart
  ```
- **Academic & Examination Engine:**
  ```bash
  flutter test test/academic_features_test.dart
  ```
- **Group Management & Real-time Chat:**
  ```bash
  flutter test test/group_chat_test.dart
  ```
- **Admin Panel & Security Boundaries:**
  ```bash
  flutter test test/admin_test.dart
  ```

---

## 5. Building the Android Release APK

To compile the release APK:

```bash
flutter build apk --release
```

### Build Artifact Location:
```
edubond_flutter/build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. Running on a Device or Emulator

To run in debug mode on a connected device:

```bash
flutter run
```

To run in release mode for performance profiling:

```bash
flutter run --release
```
