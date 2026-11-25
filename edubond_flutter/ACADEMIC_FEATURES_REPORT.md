# EduBond Academic Features Migration Report (Prompt 5)

**Scope:** Migration of Subject Management, Learner Role & Study Groups, Teacher Qualification, Examination Rules, Quiz Scoring/Attempt Tracking, Timer & Lifecycle Handling, and Local Quiz Caching (`AppStorage`) from Kotlin (`SubjectActivity.kt`, `SubjectDetailActivity.kt`, `TeacherQuizActivity.kt`, `AppStorage.kt`, `FirebaseHistoryManager.kt`) to Flutter (`edubond_flutter`).

---

## 1. Migrated Features & Parity Summary

### 1.1 Subject Management
- **Firestore Loading & Core/Admin Types:** `SubjectRepository.getGlobalSubjectItems()` (`lib/data/repositories/subject_repository.dart`) fetches documents from Firestore `subjects`, maps them to `SubjectModel` (`lib/models/subject_model.dart`) preserving `name` and `type` (`'core'` or `'admin'`), and seeds the 16 `AppConstants.coreSubjects` with `type: 'core'` when the collection is empty.
- **Real-Time Search & Collapsible List:** `SubjectsModulePage` (`lib/features/subjects/subjects_module.dart`) filters subjects in real time as the user types in `EduTextField`, displays `Core`/`Admin` badges, and supports collapsing/expanding both the Subject List and My Subject Requests sections.
- **Subject Requests & Status Display:** Submitting a new subject writes `{id, subject, by, status: 'pending', timestamp}` to `subject_requests`. `SubjectRepository.getUserSubjectRequests()` loads the user's submitted requests (client-side sorted descending by `timestamp` to avoid composite index dependencies), and `SubjectsModulePage` renders each request with a status badge (`PENDING`, `ACCEPTED`, `REJECTED`).

### 1.2 Learner Role & Subject Groups
- **Role Registration:** Selecting `"I want to study this"` in `SubjectDetailScreen` (`lib/features/subjects/subject_detail_screen.dart`) calls `SubjectRepository.addSubjectRole(..., role: 'learner')`, persisting `{email, subject, role: 'learner', score: 0, timestamp}` under `user_roles/{email}_{subject}`.
- **Group Browsing, Creation & Join Requests:** Transitions directly to the subject's Available Groups view backed by `GroupRepository` (`lib/data/repositories/group_repository.dart`):
  - Creates groups via `GroupRepository.createGroup(...)` (`groups/G{timestamp}`).
  - Browses groups filtered by `subject`.
  - Preserves exact membership permissions via `GroupModel.containsUser(email)` (case-insensitive check across `createdBy`, `members`, and `teachers`), showing `Open Group` for existing members/creators/teachers, `Request Pending` for already-sent pending join requests, and `Request to Join` otherwise (`group_join_requests`).

### 1.3 Teacher Qualification & Examination Flow
- **Eligibility Guards:** Selecting `"I want to teach this"` in `SubjectDetailScreen` checks:
  1. `user_roles` to verify the user is not already a verified `teacher` for the subject.
  2. `quiz_attempts/{email}_{subject}` (`blocked == true` or `attempts >= 2`) to block ineligible users before launching `QuizModulePage` (`lib/features/quiz/quiz_module.dart`).
  3. `QuizModulePage._prepareQuiz()` re-verifies `blocked` and `attempts` on launch as a second safety guard.

### 1.4 Examination Rules, Scoring & Attempt Logic
Preserved in `AppConstants` (`lib/core/constants/app_constants.dart`) and `QuizRepository` (`lib/data/repositories/quiz_repository.dart`):
- **Time limit:** `300` seconds (`5` minutes).
- **Questions per set:** `10` MCQs.
- **Minimum passing score:** `7 / 10`.
- **Maximum attempts before block:** `2`.
- **Quiz set rotation:** `QuizRepository.selectSetIndex` computes `totalAttempts % sets.length`.
- **Scoring & Outcome:**
  - `QuizRepository.calculateScore` performs exact option string matching (`selected == question.answer`).
  - **Pass (`score >= 7`):** Grants `teacher` role in `user_roles/{email}_{subject}` with `score`, resets `attempts` to `0`, sets `lastPassed: true`, and increments `totalAttempts`.
  - **Fail (`score < 7`):** Increments `attempts` and `totalAttempts`, sets `lastPassed: false`, and sets `blocked: true` when `attempts >= 2`.
  - All fields (`email`, `subject`, `attempts`, `totalAttempts`, `blocked`, `lastPassed`, `timestamp`) are persisted in `quiz_attempts/{email}_{subject}` with `merge: true`.

### 1.5 Quiz Timer & Lifecycle Safety
- **Countdown & Warning State:** `QuizModulePage` uses `Timer.periodic` formatting `MM:SS` via `DateFormatter.formatCountdown`. When `_remainingSeconds < 60`, the timer container turns red (`AppColors.timerBg` / `AppColors.timerRed`).
- **Auto-Submit & Duplicate Prevention:** Reaching `00:00` cancels the timer and triggers `_submitQuiz(autoSubmit: true)` once. Dual `_submitting` and `_submitted` flags guarantee duplicate submissions cannot occur from concurrent taps or timer ticks.
- **Lifecycle & Navigation Safety:**
  - `WidgetsBindingObserver` records pause timestamps on `AppLifecycleState.paused`/`inactive` and subtracts elapsed wall-clock time on `AppLifecycleState.resumed`, auto-submitting if time expired while backgrounded.
  - `PopScope` intercepts back navigation during an active exam with an exit confirmation dialog; `dispose()` cancels any active `Timer`.
  - MCQ `RadioGroup` options are wrapped in `Material(type: MaterialType.transparency)` inside `EduCard` to preserve ink splashes without Material 3 `ListTile` assertions.

### 1.6 Cloud Synchronization & Local Quiz Cache (`AppStorage`)
- **SharedPreferences Keys:** `LocalStorageService` (`lib/core/services/local_storage_service.dart`) preserves `current_user` and `quiz_sets_{subject}`.
- **Default Banks:** `QuizSeedData` (`lib/core/constants/quiz_seed_data.dart`) preserves all 9 seeded subjects (5 English CSE subjects + 4 Bengali Class 9–10/SSC subjects: `গনিত ৯-১০`, `উচ্চতর গনিত ৯-১০`, `পদার্থবিজ্ঞান ৯-১০`, `অর্থনীতি ৯-১০`).
- **Sync & Fallback:** `QuizRepository.getQuizSets(subject)` fetches `quizzes/{subject}.quizJson` from Firestore; on valid non-empty cloud data it synchronizes `quiz_sets_{subject}` in `SharedPreferences` and returns cloud sets. When Firestore fails or returns empty/invalid data, it falls back seamlessly to the local cache / seeded banks.

---

## 2. Files Added / Modified in This Phase
- `lib/models/subject_model.dart` (added `SubjectModel` for `core` / `admin` subject metadata)
- `lib/data/datasources/firestore_datasource.dart` (added `getDocData`, `getCollectionRecords`, `queryRecords`)
- `lib/data/repositories/auth_repository.dart` (added `activeUserEmail` fallback getter)
- `lib/data/repositories/subject_repository.dart` (added `getGlobalSubjectItems`, `getUserSubjectRequests`, updated queries to `FirestoreDataSource`)
- `lib/data/repositories/quiz_repository.dart` (added `calculateScore`, `selectSetIndex`, cloud-to-local cache sync in `getQuizSets`, `attempts`/`totalAttempts` on `QuizSubmissionOutcome`)
- `lib/data/repositories/group_repository.dart` (migrated queries to `FirestoreDataSource`)
- `lib/features/subjects/subjects_module.dart` (added `Core`/`Admin` badges and `My Subject Requests` status list)
- `lib/features/subjects/subject_detail_screen.dart` (added `activeUserEmail`, pending join request state, double-tap guard, `attempts >= maxAttempts` guard)
- `lib/features/quiz/quiz_module.dart` (added `WidgetsBindingObserver`, `PopScope` confirmation, `_submitted` duplicate guard, `< 60s` red timer transition, `Material` wrapper for `RadioListTile`)
- `test/academic_features_test.dart` (added 13 unit and widget integration tests)

---

## 3. Verification Results

Executed in `edubond_flutter` using Flutter 3.50.1 / Dart 3.14.0:
- `flutter analyze`: **No issues found!**
- `flutter test`: **All 21 tests passed** (8 baseline foundation tests in `test/widget_test.dart` + 13 academic workflow tests in `test/academic_features_test.dart`).

### Verified Scenarios (`test/academic_features_test.dart`)
| Scenario | Verification Coverage | Status |
|---|---|---|
| Core & Admin Subjects | 16 seeded core subjects + admin-added subjects sorted and typed | Passed |
| Local Cache (`AppStorage`) | `SharedPreferences` `current_user` and `quiz_sets_{subject}` persistence & logout | Passed |
| Cloud Synchronization | `quizzes/{subject}.quizJson` synced into local `SharedPreferences` cache | Passed |
| Offline Fallback | Cloud read failure falls back to synced cache & Bengali/English `QuizSeedData` | Passed |
| Set Rotation | `totalAttempts % sets.length` verified across attempts | Passed |
| Correct / Incorrect Scoring | Exact match scoring (`10/10`, `6/10`) and passing threshold (`>= 7/10`) | Passed |
| Passing & Teacher Role Grant | Score `7/10` grants `teacher` in `user_roles` with score & resets `attempts = 0` | Passed |
| Failed 1st & 2nd Attempt + Block | 1st fail (`attempts: 1`, retry allowed); 2nd fail (`attempts: 2`, `blocked: true`) | Passed |
| Subjects UI Workflow | Real-time filtering, `Admin`/`Core` badge rendering, request submission & `PENDING` status | Passed |
| Learner Registration & Groups UI | Registers `learner` in `user_roles`, browses groups, requests join, creates group | Passed |
| Teacher Selection & Blocked UI | Blocks blocked users with snackbar; launches `Examination Rules` when eligible | Passed |
| Timer Warning & Auto-Submit | `01:01` normal -> `00:59` red (`AppColors.timerRed`) -> `00:00` single auto-submit | Passed |
| Full UI Quiz Submission | `05:00` start -> answers 10 MCQs -> submits once -> `10/10` pass + `teacher` role | Passed |

> **Note:** Automated verification used an in-memory `FakeFirestoreDataSource` and `SharedPreferences.setMockInitialValues` alongside real repositories, `LocalStorageService`, and Riverpod widgets, as live Firebase network calls are not executed inside `flutter test`. End-to-end live Firestore verification should be run on an Android device/emulator signed into the existing Firebase project (`peermatrix-6a1db`).
