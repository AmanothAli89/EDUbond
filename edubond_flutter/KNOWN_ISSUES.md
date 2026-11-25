# KNOWN LIMITATIONS & CONFIGURATION NOTES: EDUBOND

This document details platform-specific behaviors, known limitations, and remaining deployment configuration steps.

---

## 1. Remaining Manual Configuration

### A. Google OAuth 2.0 SHA-1 Registration
- **Requirement:** For Google Sign-In to function on live Android devices in release mode, the release keystore's SHA-1 fingerprint must be added to the Firebase Project Console under **Project Settings > Your Apps > Android (`com.example.peermatrix`)**.
- **Debug Fingerprint:** By default, debug signing is configured so `flutter run` works immediately during local testing.

### B. Firestore `admin_config/credentials` Document
- **Requirement:** Ensure the Firestore database has the document:
  - Collection: `admin_config`
  - Document ID: `credentials`
  - Fields:
    - `id`: `"your_admin_id"`
    - `password`: `"your_admin_password"`
- The client application does not contain hardcoded credentials, ensuring secure admin access.

---

## 2. Platform & Toolchain Behaviors

### A. Windows Gradle Incremental Kotlin Cache Lock
- **Detail:** On Windows OS, Gradle's Kotlin incremental compiler can hold file locks on `.tab` cache files during parallel multi-module release compilation.
- **Resolution:** Configured `kotlin.incremental=false` and `kotlin.incremental.useClasspathSnapshot=false` in `android/gradle.properties`.

### B. Android Gradle Plugin 8.x/9.x Release Lint Bug
- **Detail:** When compiling release builds on JDK 17, AGP's bundled lint analysis can encounter a `NoSuchMethodError: List.removeLast()` when inspecting third-party plugin source comments.
- **Resolution:** Configured `gradle.projectsEvaluated` in `android/build.gradle.kts` and `lint { checkReleaseBuilds = false }` in `android/app/build.gradle.kts` to disable vital lint failures while keeping full Dart static analysis via `flutter analyze`.

### C. File Attachments & External Handlers
- **Detail:** Documents shared in group chat (.pdf, .docx, images) are opened using the system-default Android Intent application through `url_launcher`.
- **Note:** Devices without an installed PDF viewer or document editor will prompt the user to choose or install a compatible viewer from the Play Store.
