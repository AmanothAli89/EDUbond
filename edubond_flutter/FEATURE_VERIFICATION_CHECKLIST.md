# FEATURE VERIFICATION CHECKLIST: EDUBOND

This checklist details every individual feature migrated from the native Kotlin implementation to Flutter, along with its verification method and pass status.

---

## 1. Authentication & Session Management

| Feature | Original Kotlin Parity | Flutter Implementation | Test / Verification Method | Status |
| :--- | :--- | :--- | :--- | :--- |
| Email & Password Login | `LoginActivity.kt` | `LoginScreen` / `AuthRepository.loginWithEmailAndPassword` | `auth_test.dart` | Passed |
| Invalid Password Handling | `LoginActivity.kt` | `Validators.password` + Firebase exception catch | `auth_test.dart` | Passed |
| Google Sign-In | `LoginActivity.kt` | `GoogleSignIn` + `signInWithGoogle` provider | `auth_test.dart` (mock provider) | Passed |
| First-Time Google Login | `LoginActivity.kt` | `GoogleSignInOutcome.setAppPassword` check | `auth_test.dart` | Passed |
| App Password Creation | `SetAppPasswordActivity.kt` | `SetAppPasswordScreen` / `setAppPasswordForGoogleUser` | `auth_test.dart` | Passed |
| Returning Google Login | `LoginActivity.kt` | `GoogleSignInOutcome.verifyAppPassword` check | `auth_test.dart` | Passed |
| Forgot Password | `ForgotPasswordActivity.kt` | `ForgotPasswordScreen` / `sendPasswordResetEmail` | `auth_test.dart` | Passed |
| Admin Login | `AdminLoginActivity.kt` | `AdminLoginScreen` / Firestore `admin_config/credentials` | `admin_test.dart`, `auth_test.dart` | Passed |
| Secure Logout | `MainActivity.kt` | `AuthRepository.logout` (Firebase + Local Storage) | `auth_test.dart` | Passed |
| Dual Session Restoration | `MainActivity.kt` | `AuthRepository.hasValidSession` | `auth_test.dart` | Passed |

---

## 2. Academic Features & Examination Engine

| Feature | Original Kotlin Parity | Flutter Implementation | Test / Verification Method | Status |
| :--- | :--- | :--- | :--- | :--- |
| Core Subjects Seeding | `FirebaseHistoryManager.kt` | 16 seeded subjects in `SubjectRepository` | `academic_features_test.dart` | Passed |
| Real-time Subject Search | `SubjectActivity.kt` | `SubjectsScreen` with search filtering | `academic_features_test.dart` | Passed |
| Collapsible Subject List | `SubjectActivity.kt` | `ExpansionTile` / `ListView` categories | `academic_features_test.dart` | Passed |
| Subject Request Workflow | `SubjectActivity.kt` | `RequestSubjectModal` -> `subject_requests` | `academic_features_test.dart` | Passed |
| Learner Role Registration | `SubjectActivity.kt` | `SubjectRepository.registerLearnerRole` | `academic_features_test.dart` | Passed |
| Teacher Qualification Check | `SubjectActivity.kt` | `SubjectRepository.checkTeacherEligibility` | `academic_features_test.dart` | Passed |
| Blocked Teacher Rejection | `SubjectActivity.kt` | Blocked status check in `quiz_attempts` | `academic_features_test.dart` | Passed |
| 5-Minute Quiz Timer | `QuizActivity.kt` | `_startCountdownTimer` with auto-submit | `academic_features_test.dart` | Passed |
| Quiz Scoring (7/10 Pass) | `QuizActivity.kt` | `QuizRepository.calculateScore` (exact match) | `academic_features_test.dart` | Passed |
| Set Rotation Formula | `QuizActivity.kt` | `totalAttempts % sets.length` | `academic_features_test.dart` | Passed |
| Max 2 Quiz Attempts | `QuizActivity.kt` | Second failed attempt sets `blocked: true` | `academic_features_test.dart` | Passed |
| Attempt Reset on Pass | `QuizActivity.kt` | Passing resets attempts counter to 0 | `academic_features_test.dart` | Passed |

---

## 3. Group Collaboration & Teacher Hiring

| Feature | Original Kotlin Parity | Flutter Implementation | Test / Verification Method | Status |
| :--- | :--- | :--- | :--- | :--- |
| Group Creation (`G${timestamp}`) | `GroupActivity.kt` | `CreateGroupModal` / `GroupRepository.createGroup` | `group_chat_test.dart` | Passed |
| Group Browsing by Subject | `GroupActivity.kt` | `GroupsScreen` subject tab filter | `group_chat_test.dart` | Passed |
| Role Check (Open vs Join) | `GroupActivity.kt` | `GroupModel.containsUser` / `Open Group` action | `group_chat_test.dart` | Passed |
| Join Request Submission | `GroupActivity.kt` | `GroupRepository.sendJoinRequest` | `group_chat_test.dart` | Passed |
| Join Request Moderation | `RequestsActivity.kt` | `RequestsScreen` (Accept / Reject) | `group_chat_test.dart` | Passed |
| Duplicate Request Prevention | `GroupActivity.kt` | Query check before inserting request | `group_chat_test.dart` | Passed |
| Qualified Teacher Search | `GroupInfoActivity.kt` | `HireTeacherModal` / `findQualifiedTeachers` | `group_chat_test.dart` | Passed |
| Current Teacher Exclusion | `GroupInfoActivity.kt` | Filter out teachers already in `group.teachers` | `group_chat_test.dart` | Passed |
| Teacher Invitation Workflow | `GroupInfoActivity.kt` | `teacher_group_requests` collection | `group_chat_test.dart` | Passed |
| Teacher Invitation Review | `RequestsActivity.kt` | Accept / Reject invitation tabs | `group_chat_test.dart` | Passed |
| My Groups Aggregated View | `MainActivity.kt` | Filter groups by member, teacher, or creator | `group_chat_test.dart` | Passed |
| Leave Group Workflow | `GroupInfoActivity.kt` | Remove user from `members` or `teachers` | `group_chat_test.dart` | Passed |

---

## 4. Real-Time Chat & File Sharing

| Feature | Original Kotlin Parity | Flutter Implementation | Test / Verification Method | Status |
| :--- | :--- | :--- | :--- | :--- |
| Real-time Messaging | `GroupChatActivity.kt` | Firestore `snapshots()` in `ChatRepository` | `group_chat_test.dart` | Passed |
| Message Chronology | `GroupChatActivity.kt` | Sorted by timestamp ascending | `group_chat_test.dart` | Passed |
| WhatsApp Color Palette | `activity_group_chat.xml` | Outgoing `#DCF8C6`, Incoming `#FFFFFF` | Visual audit + Widget tests | Passed |
| Double Check Mark (`#34B7F1`) | `GroupChatActivity.kt` | Read receipt icon when `seenBy` contains users | `group_chat_test.dart` | Passed |
| Real-time Seen By Tracking | `GroupChatActivity.kt` | `ChatRepository.markMessageAsSeen` | `group_chat_test.dart` | Passed |
| Unsend Message | `GroupChatActivity.kt` | Sender-only long press menu -> delete doc | `group_chat_test.dart` | Passed |
| File & Image Sharing | `GroupChatActivity.kt` | `FilePicker` + Catbox / Firebase upload | `group_chat_test.dart` | Passed |
| Google Meet Card | `GroupChatActivity.kt` | Parsed Google Meet link into interactive card | `group_chat_test.dart` | Passed |
| Shared Files Screen | `SharedFilesActivity.kt` | `SharedFilesScreen` gallery with unsend support | `group_chat_test.dart` | Passed |

---

## 5. Administrative Panel

| Feature | Original Kotlin Parity | Flutter Implementation | Test / Verification Method | Status |
| :--- | :--- | :--- | :--- | :--- |
| Admin Dashboard | `AdminActivity.kt` | `AdminDashboardScreen` (Purple gradient hero) | `admin_test.dart` | Passed |
| User Directory & Search | `AdminUserActivity.kt` | `AdminUsersScreen` with real-time text query | `admin_test.dart` | Passed |
| User Inspection Modal | `AdminUserActivity.kt` | Details dialog (UID, provider, roles, biodata) | `admin_test.dart` | Passed |
| Manual Teacher Role (Score 10) | `AdminUserActivity.kt` | Assign role dialog setting `score: 10` | `admin_test.dart` | Passed |
| User Deletion | `AdminUserActivity.kt` | Confirmation dialog removing doc from `users` | `admin_test.dart` | Passed |
| Teacher Moderation (Active) | `AdminTeacherActivity.kt` | Active teachers tab with role revocation | `admin_test.dart` | Passed |
| Teacher Unblocking | `AdminTeacherActivity.kt` | Resets `attempts = 0`, `blocked = false` | `admin_test.dart` | Passed |
| Subject Management | `AdminSubjectActivity.kt` | `AdminSubjectsScreen` (add, edit, reject, delete) | `admin_test.dart` | Passed |
| Quiz Set Editor (Sets 1–4) | `AdminQuizActivity.kt` | Horizontal set selector with 10 MCQ cards | `admin_test.dart` | Passed |
| Quiz Option Chips | `AdminQuizActivity.kt` | Interactive option chips for correct answer | `admin_test.dart` | Passed |
| Dual Quiz Persistence | `AdminQuizActivity.kt` | Cloud `quizzes/{subject}` + Local storage | `admin_test.dart` | Passed |
| Weekly Analytics BarChart | `AdminReportsActivity.kt` | `fl_chart` rounded BarCharts & weekday labels | `admin_test.dart` | Passed |
| Security Route Guard | Client security fix | `AdminAccessGuard` + `isAdminAuthorized` | `admin_test.dart` | Passed |
