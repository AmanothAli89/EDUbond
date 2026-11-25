# EduBond Flutter (`edubond_flutter`)

**EduBond** (*Digital Platform for Academic Peers*) is a cross-platform Flutter & Firebase application (`com.example.peermatrix`) designed for peer-to-peer academic collaboration, teacher qualification testing, study group management, real-time group chat, and administrative moderation.

---

## Core Modules & Features

- **Onboarding & Auth (`splash`, `authentication`):** Interactive animated study lamp splash screen, Google Sign-In with App Password linking (`EmailAuthProvider`), Email/Password login, Forgot Password, Profile editing, dual session check (`FirebaseAuth` + `SharedPreferences`), and custom-claim verified Admin login.
- **Academic & Qualification Engine (`subjects`, `quiz`):** 16 pre-seeded core subjects + admin subjects, real-time subject search, subject requests (`subject_requests`), learner role registration, and a 5-minute 10-MCQ teacher qualification exam (`7/10` pass mark, `2` max attempts before blocking, rotating sets).
- **Study Groups & Hiring (`groups`, `requests`, `group_info`):** Group creation (`G${timestamp}`), browsing by subject, join request approval/rejection (`group_join_requests`), qualified teacher discovery & invitations (`teacher_group_requests`), My Groups view, and leave-group support.
- **Real-Time Chat & Sharing (`chat`, `shared_files`):** Live Firestore messaging (`groups/{groupId}/messages`), `seenBy` blue double-check read receipts, sender-only unsend, interactive meeting cards (Google Meet / Zoom / Jitsi), and free file/image uploads via Catbox (`https://catbox.moe/user/api.php`).
- **Admin Panel & Analytics (`admin`, `reports`):** Route-guarded (`AdminAccessGuard`) dashboard with user search/inspection, manual teacher assignment (`score: 10`), blocked teacher unblocking (`attempts = 0`), subject & request management, 4-set x 10-MCQ quiz editor, and 7-day `fl_chart` analytics.

---

## Architecture

```text
edubond_flutter/
├── android/                        # Android Gradle config (applicationId = com.example.peermatrix, minSdk = 24, targetSdk = 36)
│   └── app/google-services.json    # Firebase Android config for edubond-64cc0
├── assets/
│   ├── html/login.html             # Interactive SVG lamp splash asset
│   ├── images/developer_pic.png    # Developer profile photo
│   └── icons/ic_logo_edu.xml       # Brand vector icon
├── lib/
│   ├── main.dart                   # Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform) + Riverpod
│   ├── app.dart                    # EduBondApp (Material 3 + AppRouter)
│   ├── firebase_options.dart       # FlutterFire configuration (edubond-64cc0)
│   ├── core/                       # AppColors, AppConstants, FirestoreCollections, QuizSeedData, providers, utils, widgets
│   ├── models/                     # UserModel, SubjectModel, GroupModel, MessageModel, QuizQuestionModel, etc.
│   ├── data/
│   │   ├── datasources/            # FirebaseAuth, Firestore, Catbox HTTP, FirebaseStorage, LocalPrefs
│   │   └── repositories/           # Auth, Subject, Quiz, Group, Chat, Admin repositories
│   └── features/                   # Feature UI modules & screens
├── firestore.rules                 # Production Cloud Firestore Security Rules
├── firestore.indexes.json          # Firestore composite index definitions
└── test/                           # 44 automated tests (auth, academic, group/chat, admin, models)
```

---

## Key Packages

- **State Management & DI:** `flutter_riverpod`
- **Firebase & Auth:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`
- **Local Persistence:** `shared_preferences`
- **Networking, Files & Charts:** `http`, `file_picker`, `url_launcher`, `cached_network_image`, `webview_flutter`, `fl_chart`, `intl`

---

## Firebase Configuration (`edubond-64cc0`)

1. Configured via `android/app/google-services.json` and `lib/firebase_options.dart` (`package_name: com.example.peermatrix`).
2. Authentication uses **Email/Password** and **Google Sign-In** (with `AppConstants.googleWebClientId` matched to `client_type: 3` and registered SHA-1).
3. Cloud Firestore uses deployed `firestore.rules` (default-deny, `request.auth != null`, owner/admin scoping, and `{ admin: true }` custom claims) and `firestore.indexes.json`.
4. Group file/image sharing uses free Catbox HTTP uploads without requiring a paid Firebase Storage plan.

---

## Verification & Build Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Latest verification status:
- `flutter analyze`: **0 issues found**
- `flutter test`: **44/44 tests passed**

---

## Documentation

- [FINAL_MIGRATION_REPORT.md](FINAL_MIGRATION_REPORT.md)
- [FEATURE_VERIFICATION_CHECKLIST.md](FEATURE_VERIFICATION_CHECKLIST.md)
- [FIREBASE_CONFIGURATION.md](FIREBASE_CONFIGURATION.md)
- [FIREBASE_ACCOUNT_MIGRATION_REPORT.md](FIREBASE_ACCOUNT_MIGRATION_REPORT.md)
- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md)

---

## Developer

**MD. Amanoth Ali**  
B.Sc. in Computer Science and Engineering (CSE)  
Bangladesh Army University of Science and Technology (BAUST)  
GitHub: [AmanothAli89](https://github.com/AmanothAli89)
