# EduBond — Digital Platform for Academic Peers

**EduBond** is a peer-to-peer academic collaboration and learning platform built with **Flutter**, **Dart**, and **Firebase**. It connects learners and qualified peer teachers through subject-based study groups, real-time group chat, resource sharing, teacher qualification examinations, and an administrative management dashboard.

---

## Key Features

### Interactive Onboarding & Visual Identity
- **Animated Study Lamp Splash Screen:** Custom-painted study lamp with interactive pull-string animation, eye state transitions, warm illumination effect, and automatic session check.
- **Clean Material UI:** Preserved academic palette (`#F8FBFF` background, `#1E1B4B` primary navy, `#2563EB` blue, `#7C3AED` purple, and WhatsApp-inspired `#075E54` / `#E5DDD5` / `#DCF8C6` chat surfaces).

### Authentication & Dual-Layer Security
- **Google Sign-In & App Password Linking:** First-time Google users create a 6+ character App Password linked via `EmailAuthProvider`, enabling sign-in via either Google or Email/Password.
- **Email & Password Login:** Validated login flow with show/hide password toggle and Firebase password reset (`Forgot Password`).
- **Dual Session Restoration:** Verifies both `FirebaseAuth.currentUser` and local `SharedPreferences` session state on startup.
- **Role-Protected Admin Authentication:** Firebase Auth email + custom claim (`{ admin: true }`) verification paired with `AdminAccessGuard` route protection.

### Subjects & Teacher Qualification Examination
- **Subject Catalog:** 16 pre-seeded core subjects (CSE & SSC subjects in English and Bengali) plus admin-curated subjects, real-time search filtering, and collapsible views.
- **Subject Requests:** Students can request new subjects (`subject_requests`) and track approval status (`pending`, `approved`, `rejected`).
- **Learner & Teacher Roles (`user_roles`):**
  - **I want to study this:** Registers the learner role and opens available study groups for the subject.
  - **I want to teach this:** Checks qualification and blocked status before launching the qualification exam.
- **Teacher Qualification Exam Rules:**
  - **10 MCQs** per examination set with rotating sets (`totalAttempts % sets.length`)
  - **5-minute (300s) countdown timer** with automatic submission on timeout
  - **Passing threshold:** `7/10`
  - **Attempt limit:** Maximum `2` failed attempts before automatic blocking (`quiz_attempts.blocked = true`), which only an admin can unblock

### Study Groups, Requests & Teacher Hiring
- **Group Creation & Discovery:** Create subject-specific study groups (`G${timestamp}`), browse existing groups, and see role-aware actions (**Open Group** vs. **Request to Join**).
- **Join Request Moderation (`group_join_requests`):** Send join requests with duplicate prevention, and approve or reject incoming requests.
- **Hire Qualified Teachers (`teacher_group_requests`):** Search qualified teachers for a group's subject (excluding teachers already in the group), send invitations, and accept/reject teaching invites.
- **My Groups & Group Info:** Unified view of all groups where the user is creator, member, or teacher, plus member management and leave-group support.

### Real-Time Chat & Resource Sharing
- **Live Group Messaging:** Firestore real-time stream (`groups/{groupId}/messages`) with sender attribution, timestamps, and chronological ordering.
- **Read Receipts & Unsend:** Blue double-check read receipts (`#34B7F1`) backed by `seenBy` tracking, plus sender-only message unsending.
- **File & Image Sharing:** Free file/image uploads via Catbox (`CatboxUploadDataSource`) and shared attachment gallery (`SharedFiles`) with preview/launcher support.
- **Live Meeting Cards:** Interactive meeting link cards supporting Google Meet, Zoom, and Jitsi links.

### Complete Admin Panel & Analytics
- **Admin Dashboard:** Purple gradient hero card with navigation to Users, Teachers, Subjects, and Weekly Reports.
- **User & Teacher Management:** Search users, inspect profile/role details, manually grant teacher roles (`score: 10`), revoke teaching roles, remove users, and unblock blocked quiz takers (`attempts = 0`, `blocked = false`).
- **Subject & Quiz Set Editor:** Approve/edit/reject subject requests, add/delete subjects, and manage 4 quiz sets x 10 MCQs per subject with local `SharedPreferences` + Firestore (`quizzes/{subject}`) sync.
- **Weekly Reports:** Total users plus 7-day trend bar charts (`fl_chart`) for new users, new groups, and new qualified teachers.

---

## Tech Stack

- **Framework:** Flutter (`sdk: ^3.14.0` Dart)
- **State Management & DI:** `flutter_riverpod`
- **Backend & Auth:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`
- **Local Storage & Caching:** `shared_preferences`
- **Charts & Media:** `fl_chart`, `cached_network_image`, `file_picker`, `url_launcher`, `http`, `intl`
- **Android Application ID:** `com.example.peermatrix` (`minSdk = 24`, `targetSdk = 36`)

---

## Project Structure

```text
EduBond-master/
└── edubond_flutter/
    ├── android/                         # Android configuration (com.example.peermatrix, google-services.json)
    ├── assets/                          # Splash HTML, icons, images
    ├── lib/
    │   ├── core/                        # Constants, routes, Riverpod providers, theme, utils, shared widgets
    │   ├── data/                        # DataSources (FirebaseAuth, Firestore, Catbox, LocalPrefs) & Repositories
    │   ├── features/                    # Splash, Authentication, Dashboard, Subjects, Quiz, Groups, Chat, Requests, SharedFiles, GroupInfo, Profile, Admin, Reports
    │   ├── models/                      # Immutable Dart models & Firestore mappers
    │   ├── firebase_options.dart        # FlutterFire configuration (edubond-64cc0)
    │   └── main.dart                    # Application entry point
    ├── firestore.rules                  # Production Cloud Firestore Security Rules
    ├── firestore.indexes.json           # Composite index definitions
    └── test/                            # 44 automated unit & widget tests across 5 test suites
```

---

## Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AmanothAli89/EDUbond.git
   cd EDUbond/edubond_flutter
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase (if using your own Firebase project):**
   - Place `google-services.json` in `edubond_flutter/android/app/`.
   - Run `flutterfire configure` to regenerate `lib/firebase_options.dart` and update `AppConstants.googleWebClientId` in `lib/core/constants/app_constants.dart`.
   - Enable **Email/Password** and **Google** providers in Firebase Authentication, deploy `firestore.rules` & `firestore.indexes.json`, and seed `subjects`, `quizzes`, and an admin user (`{ admin: true }` custom claim).
4. **Verify & Run:**
   ```bash
   flutter analyze
   flutter test
   flutter run
   ```
5. **Build Release APK:**
   ```bash
   flutter build apk --release
   ```

---

## Testing & Verification

- `flutter analyze`: **0 issues found**
- `flutter test`: **44/44 tests passing** across:
  - `test/auth_test.dart`
  - `test/academic_features_test.dart`
  - `test/group_chat_test.dart`
  - `test/admin_test.dart`
  - `test/widget_test.dart`

---

## Developer

**MD. Amanoth Ali**
- B.Sc. in Computer Science and Engineering (CSE)
- Bangladesh Army University of Science and Technology (BAUST)
- GitHub: [AmanothAli89](https://github.com/AmanothAli89)

---

## License

This project is licensed under the MIT License.
