# FIREBASE ACCOUNT MIGRATION REPORT: EDUBOND

**Status:** Android Reconfigured to `edubond-64cc0` — Tests & Build Verification Pending; Optional Old Data Migration Pending User Decision  
**Date:** November 25, 2026  
**Android Package Name:** `com.example.peermatrix` (unchanged)

---

## 1. Old vs New Project Summary

| Item | Old Firebase Project | New Firebase Project (Active in App) |
| :--- | :--- | :--- |
| **Project ID** | `peermatrix-6a1db` | `edubond-64cc0` |
| **Project Number** | `850714985586` | `314387118764` |
| **Storage Bucket** | `peermatrix-6a1db.firebasestorage.app` | `edubond-64cc0.firebasestorage.app` |
| **Android App ID** | `1:850714985586:android:da335e30902e1436bfaeeb` | `1:314387118764:android:caacafb38f62816ce73d09` |
| **Debug SHA-1** | `8d7f4b6f484c83d28659825451325bd4427bff19` | `23:FB:A5:6B:61:88:49:01:93:88:DF:7B:40:C8:2A:EA:06:2A:71:40` |
| **Google Web Client ID (`client_type: 3`)** | `850714985586-f332vkjs0415ef9r6reoe7suade92jbn.apps.googleusercontent.com` | `314387118764-utq87d2na5soestlttj806iflcjdado0.apps.googleusercontent.com` |
| **Config Source** | Old `google-services.json` | Updated `edubond_flutter/android/app/google-services.json` + `AppConstants.googleWebClientId` |

> **Important:** The old Firebase project (`peermatrix-6a1db`) has NOT been modified or deleted.

---

## 2. Pre-Migration Codebase Audit

### A. Local Signing Certificate (Debug Keystore)
Audited on current build machine:
- **SHA-1:** `23:FB:A5:6B:61:88:49:01:93:88:DF:7B:40:C8:2A:EA:06:2A:71:40`
- **SHA-256:** `4D:AB:4D:EE:A1:E5:91:B2:B6:8D:E2:D8:F7:81:CD:91:4D:0C:64:F0:60:5E:E3:95:DA:1D:2A:69:20:0D:6F:DA`
- *(Previous SHA-1 in old `google-services.json` was `8d7f4b6f484c83d28659825451325bd4427bff19` — add the current machine's SHA-1 above in the new Firebase Console so Google Sign-In works.)*

### B. Firebase Configuration References in Code
1. `edubond_flutter/android/app/google-services.json` — Android Firebase configuration (`project_id`, `mobilesdk_app_id`, `api_key`, `oauth_client`).
2. `edubond_flutter/lib/core/constants/app_constants.dart` — Hardcoded `AppConstants.googleWebClientId` used by `FirebaseAuthDataSource.signInWithGoogle()`. **Must be updated** to the new project's `client_type: 3` Web Client ID.
3. `edubond_flutter/lib/main.dart` — Calls `await Firebase.initializeApp();` using `google-services.json`. (Will also support `DefaultFirebaseOptions.currentPlatform` once `firebase_options.dart` is generated via FlutterFire CLI).
4. `edubond_flutter/lib/firebase_options.dart` — Currently absent (not generated yet).

### C. Audited Firestore Collections & Subcollections
From `lib/core/constants/firestore_collections.dart` and repositories:
1. `users` (doc ID: `{uid}`) — `uid`, `username`, `email`, `photoUrl`, `role`, `loginProvider`, `googleVerified`, `passwordSet`, `biodata`, `updatedAt`
2. `subjects` (doc ID: `DocIdHelper.subjectDocId(name)`) — `name`, `type` (`core` | `admin`)
3. `subject_requests` (doc ID: `reqId`) — `id`, `name`, `by`, `status`, `timestamp`
4. `quizzes` (doc ID: `{subject}`) — `subject`, `quizJson`, `lastUpdated`
5. `quiz_attempts` (doc ID: `DocIdHelper.emailSubjectDocId(email, subject)`) — `email`, `subject`, `attempts`, `totalAttempts`, `blocked`, `lastPassed`
6. `user_roles` (doc ID: `email_subject`) — `email`, `subject`, `role` (`learner` | `teacher`), `score`, `status`, `timestamp`
7. `groups` (doc ID: `G{timestamp}`) — `id`, `name`, `subject`, `createdBy`, `members[]`, `teachers[]`, `timestamp`
   - Subcollection: `groups/{groupId}/messages` — `groupId`, `senderEmail`, `message`, `fileUrl`, `fileType`, `fileName`, `timestamp`, `seenBy[]`
8. `group_join_requests` — `id`, `groupId`, `groupName`, `subject`, `requester`, `status`, `timestamp`
9. `teacher_group_requests` — `id`, `groupId`, `groupName`, `subject`, `requester`, `teacher`, `status`, `timestamp`
10. `admin_config` (doc ID: `credentials`) — `id`, `password`
11. `activity_logs` — `email`, `action`, `timestamp`
12. `notes` — `groupId`, `title`, `url`, `type`, `by`, `timestamp`
13. `app_data` (doc ID: `subjects`) — Legacy subject metadata

### D. Required Firestore Composite Indexes
- Collection `notes`: `groupId` (ASC) + `timestamp` (DESC) — queried in `ChatRepository.getNotes()`.
- Single-field queries (`groups/{groupId}/messages` ordered by `timestamp`, `subject_requests` ordered by `timestamp`) are automatically indexed by Firestore.

### E. Audited Storage Paths
- `groups/{groupId}/shared_files/{timestamp}_{fileName}` (`FirebaseStorageDataSource.uploadGroupFile`)
- `groups/{groupId}/files/{fileName}` (legacy Kotlin `FirebaseHistoryManager.kt`)
- External file host fallback: `https://catbox.moe/user/api.php` (`CatboxUploadDataSource`, unaffected by Firebase migration).

---

## 3. Authentication Migration Analysis

1. **Google Sign-In Accounts:**
   - When users sign into the new Firebase project with Google, Firebase Auth generates **new UIDs** unless existing Auth accounts are exported (`firebase auth:export`) and imported (`firebase auth:import`) with preserved UIDs into the new project.
   - **Impact if UIDs change:** Because `users/{uid}` is keyed by Firebase Auth `uid`, migrating `users` documents without preserving Firebase Auth UIDs would cause `AuthRepository.fetchUserProfile(uid)` and `authenticateWithGoogle()` to treat returning Google users as having `passwordSet: false` (prompting them to set an App Password again).
   - **Recommended Auth Migration Method:**
     1. Export users from old project (`peermatrix-6a1db`) via Firebase CLI / Admin SDK: includes UIDs, emails, providers, and password hashes (scrypt parameters from Firebase Console -> Authentication -> Users -> 3-dots menu -> Password hash parameters).
     2. Import into the new project using `firebase auth:import` with `--hash-algo=SCRYPT`, `--hash-key`, `--salt-separator`, `--rounds`, `--mem-cost` from the old project.
     3. That preserves **both** Firebase UIDs **and** existing email/app passwords without requiring password resets!
   - **Alternative (Fresh Auth / No Export Access):** If old project Auth hash parameters cannot be accessed, existing Email+Password users will use **Forgot Password** (`sendPasswordResetEmail`), and Google users will sign in with Google once and re-create their 6-character App Password.

---

## 4. Security Rules Review (Important Audit Finding)

- **Admin Auth Behavior:** In the current app (`AuthRepository.loginAsAdmin`), Admin login reads `admin_config/credentials` and calls `await logout()` (so `request.auth == null` during Admin Panel usage).
- **Risk:** Requiring `request.auth != null && request.auth.token.admin == true` without updating Admin login to use Firebase Auth custom claims would block `AdminLoginScreen` on the new project.
- **Recommendation:**
  - Keep database writes protected (`request.auth != null` for authenticated student/teacher collections).
  - For production hardening, configure a dedicated Firebase Auth admin user (with custom claim `admin: true`) instead of unauthenticated `admin_config` reads, **or** restrict `admin_config` and admin writes appropriately during transition. Never deploy open `allow read, write: if true;` rules in production.

---

## 5. Migration Execution Status

| Step | Status | Details |
| :--- | :--- | :--- |
| 1. Pre-Migration Codebase Audit | **Completed** | Audited all collections, fields, queries, storage paths, Web Client ID, and local SHA-1. |
| 2. Create New Firebase Project | **Completed** | Project `edubond-64cc0` created; Android app `com.example.peermatrix` registered with local SHA-1 `23fba56b...`. |
| 3. Data Migration (Firestore) | **Completed (Fresh Seed)** | Seeded 16 core `subjects`, 9 default `quizzes` banks, `users/{adminUid}`, and `admin_config/credentials` on `edubond-64cc0`. Old project `peermatrix-6a1db` left untouched. |
| 4. Auth Migration | **Completed (Fresh + Admin)** | Fresh Auth enabled on `edubond-64cc0`; created admin user `admin123@gmail.com` (`UID: MyAJxaE5Y0UxOlZpYccP05lxdhn1`) with `{ admin: true }` custom claim and updated `AuthRepository.loginAsAdmin`. |
| 5. Storage Migration | **Not Required (Spark / Catbox)** | App uses free Catbox (`https://catbox.moe/user/api.php`) as primary file host; Firebase Storage (which requires Blaze plan on new projects) was intentionally skipped. |
| 6. Security Rules & Indexes | **Completed (Firestore)** | Production `firestore.rules` authored and deployed, plus `firestore.indexes.json` (`notes` composite index) deployed to `edubond-64cc0`. |
| 7. App Reconfiguration | **Completed** | Updated `android/app/google-services.json`, generated `lib/firebase_options.dart` via FlutterFire CLI, wired `DefaultFirebaseOptions.currentPlatform` in `main.dart`, and updated `AppConstants.googleWebClientId`. |
| 8. Verification | **Unit/Widget Passed; Live Pending** | `flutter analyze` (0 issues) & `flutter test` (43/43) passed with `firebase_options.dart`; live device auth/DB test pending user run. |

---

## 6. Rollback Procedure

If any issue occurs on the new Firebase project:
1. Keep the old Firebase project (`peermatrix-6a1db`) intact and un-deleted.
2. Revert `edubond_flutter/android/app/google-services.json`, `edubond_flutter/lib/core/constants/app_constants.dart` (`googleWebClientId`), and `lib/firebase_options.dart` (if added) via `git checkout`.
3. Rebuild APK (`flutter build apk --release`).
