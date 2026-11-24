# EduBond (Flutter Migration — Phase 2 Foundation)

**EduBond** (*Digital Platform for Academic Peers*) is being migrated from the original Kotlin Android application (`com.example.peermatrix`) to Flutter & Dart while keeping the **exact same Firebase project (`peermatrix-6a1db`)** and **unchanged Firestore schema**.

---

## Project Architecture

```text
edubond_flutter/
├── android/                        # Android Gradle config (applicationId = com.example.peermatrix, minSdk = 24)
│   └── app/google-services.json    # Preserved Firebase config for peermatrix-6a1db
├── assets/
│   ├── html/login.html             # Interactive SVG lamp splash asset
│   ├── images/developer_pic.png    # Developer profile photo
│   └── icons/ic_logo_edu.xml       # Brand vector icon
├── lib/
│   ├── main.dart                   # Firebase.initializeApp() + SharedPreferences + Riverpod ProviderScope
│   ├── app.dart                    # EduBondApp (Material Design 3 + AppRouter)
│   ├── core/
│   │   ├── constants/              # AppColors, AppConstants, FirestoreCollections, QuizSeedData
│   │   ├── routes/                 # AppRoutes & AppRouter
│   │   ├── services/               # LocalStorageService, Riverpod providers
│   │   ├── theme/                  # Material 3 Light Theme
│   │   ├── utils/                  # DocIdHelper, Validators, DateFormatter
│   │   └── widgets/                # EduCard, EduButton, EduTextField, CustomPainters
│   ├── models/                     # UserModel, GroupModel, MessageModel, QuizQuestionModel, etc.
│   ├── data/
│   │   ├── datasources/            # FirebaseAuth, Firestore, FirebaseStorage, Catbox HTTP, LocalPrefs
│   │   └── repositories/           # Auth, Subject, Quiz, Group, Chat, Admin repositories
│   ├── features/                   # 13 feature modules (splash -> reports)
│   └── shared/widgets/             # EmptyStateView, ErrorBanner, FeatureFoundationPage
└── test/
    └── widget_test.dart            # Unit tests for DocIdHelper, QuizSeedData, models, validators
```

---

## Key Packages Selected

- **State Management & DI:** `flutter_riverpod`
- **Firebase:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- **Google Auth:** `google_sign_in`
- **Local Persistence:** `shared_preferences`
- **Networking & Files:** `http`, `file_picker`, `url_launcher`, `cached_network_image`
- **UI & Charts:** `webview_flutter`, `fl_chart`, `intl`

---

## Firebase Setup (Existing Project `peermatrix-6a1db`)

1. The Android app reuses the existing `android/app/google-services.json` (`project_id: peermatrix-6a1db`, `package_name: com.example.peermatrix`) via `com.google.gms.google-services`.
2. **Do NOT create a new Firebase project** or modify Firestore collection/field names.
3. Ensure Android debug/release builds use the SHA-1 keystore registered in Firebase for Google Sign-In (`serverClientId` configured in `AppConstants.googleWebClientId`).
4. *(Optional for multi-platform / Web / iOS later)*: Run `dart pub global activate flutterfire_cli` and `flutterfire configure --project=peermatrix-6a1db` to generate `lib/firebase_options.dart`, then pass `options: DefaultFirebaseOptions.currentPlatform` to `Firebase.initializeApp()`.

---

## Verification Commands

```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
```
