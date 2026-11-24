# EduBond — UI Migration Report (`UI_MIGRATION_REPORT.md`)

> **Migration Scope:** Complete Kotlin Android UI (`18 Activities` + `login.html` WebView + `14` Canvas custom Views) migrated to Flutter (`edubond_flutter/`) using `material_ui` (Material Design 3), `flutter_riverpod`, `CustomPainter`, `fl_chart`, `file_picker`, `url_launcher`, and `google_sign_in`.  
> **Firebase Compatibility:** Preserves existing Firebase project (`peermatrix-6a1db`), package ID (`com.example.peermatrix`), and all 13+ Firestore collections and field names without modification.

---

## 1. Completed Screen-by-Screen UI Mapping

| # | Original Kotlin Screen | Flutter Screen / File | Status | Visual & UX Parity Notes |
| :---: | :--- | :--- | :---: | :--- |
| 1 | `AnimatedLoginActivity` + `login.html` | `SplashGatePage` (`lib/features/splash/splash_gate_page.dart`) | Completed | Recreated natively with `_StudyLampPainter` (`CustomPainter`) + `AnimationController`. Preserves `#0F172A` background, closed curved eyes, pull-string triangle knob, tap/vertical-drag pull animation, light beam cone (`#FFFEF0`), sage shade (`#A3AD8A`), happy arched eyes, open mouth + `#FF7B7B` tongue, glowing `#FACC15` `"WELCOME TO EDUBOND"`, and 1.5s fade transition. |
| 2 | `MainActivity` (Login Page) | `AuthenticationModulePage` (`lib/features/authentication/authentication_module.dart`) | Completed | Gradient `#CFE8FF → #EDE7FF → #F8FBFF`, translucent rounded card (`28px`, `#AAB7C8` stroke), `📖 EduBond` header, Gmail & App Password fields (`#EEF3FA`), `EyeTogglePainter`, `#0057D8` Login, `#006B57` Continue with Google, `#4B008C` Login as Admin, Forgot Password & About Us links. |
| 3 | `MainActivity` (Forgot Password) | `ForgotPasswordScreen` (`lib/features/authentication/forgot_password_screen.dart`) | Completed | Preserves auth card, explanatory copy, Gmail field, `#0061FF` Send Reset Email, and `#F1F5F9` Back to Login button. |
| 4 | `MainActivity` (Admin Login) | `AdminLoginScreen` (`lib/features/authentication/admin_login_screen.dart`) | Completed | `#F8FBFF → #EEF6FF → #F8F7FF` gradient, `AdminShieldPainter` badge, `#6A1B9A` EduBond header, `32px` card, `UserOutlinePainter` + `LockBadgePainter` + `EyeTogglePainter`, `#6A1B9A → #8E24AA` gradient button, `#9CA3AF` Back button. |
| 5 | `MainActivity` (Set App Password) | `SetAppPasswordScreen` (`lib/features/authentication/set_app_password_screen.dart`) | Completed | Green `LockBadgePainter` header, `#F0FFF7` verified Gmail card (`#BDEBD0` border), two labeled password fields with eye toggles, `#238A4B` Save Password & Continue, `#DC2F3A` Cancel and Logout. |
| 6 | `MainActivity` (Enter App Password) | `AppPasswordScreen` (`lib/features/authentication/app_password_screen.dart`) | Completed | Blue `LockBadgePainter` header, `#ECFDF5` verified Gmail card, eye-toggled App Password input, `#2F80ED` Login, `#F1F5F9` Back button. |
| 7 | `MainActivity` (About Us) | `AboutUsScreen` (`lib/features/authentication/about_us_screen.dart`) | Completed | Circular `developer_pic.png` (136px), BAUST CSE bio, clickable `mailto:`, LinkedIn, and GitHub rows (`url_launcher`), `#4B008C` Back to Login. |
| 8 | `UserHomeActivity` | `DashboardModulePage` (`lib/features/dashboard/dashboard_module.dart`) | Completed | `#0061FF` `"EduBond Dashboard"` header + `#93C5FD` circular initials badge, `#1D4ED8 → #7C3AED` hero card (`32px`), responsive `GridView` with `SearchIconPainter`, `UsersIconPainter`, `ChatIconPainter`, `LogoutIconPainter`, and Logout `AlertDialog`. |
| 9 | `UserProfileActivity` | `ProfileModulePage` (`lib/features/profile/profile_module.dart`) | Completed | View/Edit/Change-Password internal modes with back-button state handling, `#2563EB` Edit Profile, `#7C3AED` Change App Password, `#0D9466` Update Name & Bio, Forgot Password shortcut. |
| 10 | `SubjectActivity` | `SubjectsModulePage` (`lib/features/subjects/subjects_module.dart`) | Completed | `"Subject Search"` header, search card with `#0D9466` `"REQUEST NEW SUBJECT ADD"`, collapsible `"Subject List:"` toggle, uppercase subject cards, `#334155` `"BACK"` button. |
| 11 | `SubjectDetailActivity` | `SubjectDetailScreen` (`lib/features/subjects/subject_detail_screen.dart`) | Completed | Role selection (`StudyOptionIconPainter` `#2563EB`, `UserOutlinePainter` `#7C3AED`) + Study Groups view (`Start a Study Group` card + `Available Groups` with `#059669` `Open Group` and `#EFF6FF` `Request to Join`). |
| 12 | `TeacherQuizActivity` | `QuizModulePage` (`lib/features/quiz/quiz_module.dart`) | Completed | Examination Rules card (`#059669` `Start Exam`), sticky header with monospace countdown (`#FEE2E2` pill, `#DC2626`, red `< 60s`), 10 MCQ cards with `RadioGroup`, `#2563EB` `Submit Quiz`, auto-submit on timeout, and a dedicated Score & Result screen (`>= 7/10` pass, 2-attempt block). |
| 13 | `RequestsActivity` | `RequestsModulePage` (`lib/features/requests/requests_module.dart`) | Completed | Three sections (`Join Requests`, `Teaching Requests`, `My Sent Requests`), `#10B981` Approve/Accept and `#EF4444` Reject buttons. |
| 14 | `MyGroupsActivity` | `GroupsModulePage` (`lib/features/groups/groups_module.dart`) | Completed | `"My Groups"` list with pull-to-refresh + auto-refresh on pop, empty state, and `#334155` `"BACK"` button. |
| 15 | `GroupRoomActivity` | `ChatModulePage` (`lib/features/chat/chat_module.dart`) | Completed | `#075E54` header (clickable title/subtitle + `⋮` Group Info menu), `#E5DDD5` background, `#DCF8C6` outgoing & `#FFFFFF` incoming bubbles, `✓` / `#34B7F1` `✓✓` read receipts, clickable URLs/emails, long-press unsend, `📎` file upload, `📹` meeting link dialog, `SendIconPainter` circular button. |
| 16 | `GroupInfoActivity` | `GroupInfoModulePage` (`lib/features/group_info/group_info_module.dart`) | Completed | Subject/Creator card, Teachers list, Members list, Hire Qualified Teachers with `Request` → `Sent`, `#3B82F6` `📁 View Shared Files`, `#EF4444` `Leave Group` confirmation. |
| 17 | `SharedFilesActivity` | `SharedFilesModulePage` (`lib/features/shared_files/shared_files_module.dart`) | Completed | Real-time filtered attachments (`🖼️` / `📄` / `📹`), uploader display name + `hh:mm a` timestamp, tap to open via `url_launcher`, long-press own file to unsend. |
| 18 | `AdminActivity` | `AdminModulePage` (`lib/features/admin/admin_module.dart`) | Completed | `"Admin Panel"` header + `AdminShieldPainter` badge, `#6366F1 → #A855F7` hero card, 2×2 grid (`Manage Users`, `Subjects`, `Reports`, `Logout`) + shortcut to standalone `AdminTeachersScreen`. |
| 19 | `AdminUserActivity` | `AdminUsersScreen` (`lib/features/admin/admin_users_screen.dart`) | Completed | `All Users` / `Teachers` tabs + `Active Teachers` / `Blocked Teachers` sub-tabs, live search, user count, Add Role subject picker, Remove User, Remove Teaching Role, Unblock User. |
| 20 | `AdminTeacherActivity` | `AdminTeachersScreen` (`lib/features/admin/admin_teachers_screen.dart`) | Completed | Standalone `Teachers` / `Blocked` tabs with live search, user name lookup, Remove Teacher Role, Unblock User. |
| 21 | `AdminSubjectActivity` | `AdminSubjectsScreen` (`lib/features/admin/admin_subjects_screen.dart`) | Completed | `Subject List` / `Requests` tabs, search, `+ Add New Subject` dialog, `Questions` / `Delete`, pending request `Accept` / `Edit` / `Reject`. |
| 22 | `AdminQuizActivity` | `AdminQuizEditorScreen` (`lib/features/admin/admin_quiz_screen.dart`) | Completed | `Set 1`–`Set 4` pill selector + 10 MCQ editor cards saving to both local `SharedPreferences` and Firestore `quizzes/{subject}`. |
| 23 | `AdminReportsActivity` | `ReportsModulePage` (`lib/features/reports/reports_module.dart`) | Completed | `"Total Users"` stat card (`#0061FF`) + 3 weekly bar charts (`New Users`, `New Groups`, `New Teachers`) rendered via `fl_chart` (`#3B82F6`, `#10B981`, `#8B5CF6`). |

---

## 2. Intentional Improvements & Remaining Differences

1. **Native Animated Lamp (`CustomPainter` + `AnimationController`) vs `WebView`:**
   - The Kotlin app loaded `assets/html/login.html` inside `WebView`. In Flutter, the identical lamp illustration, colors, closed/happy eyes, pull string, light beam, and timing were recreated natively via `CustomPainter` + `AnimationController` for faster cold-start rendering and zero WebView overhead. (`assets/html/login.html` remains preserved in `assets/html/`.)
2. **Teacher Quiz Result Screen Added:**
   - Kotlin `TeacherQuizActivity` finished immediately with a Toast after submission. Flutter `QuizModulePage` displays a clear Score & Pass/Blocked Result summary screen (`Score: X / 10`) before returning, improving clarity while keeping the exact same `7/10` pass and `2-attempt` block logic.
3. **`AdminPassword` Eye Toggle Fix:**
   - Kotlin `AuthUIHelper.adminPasswordInputWithEye` had a minor bug where `eyeButton.isClosed = false` was hardcoded on click. Flutter `AdminLoginScreen` toggles `EyeTogglePainter(isClosed: !_visible)` accurately.
4. **Shared Files Null `fileUrl` Filter Fix:**
   - Kotlin `SharedFilesActivity` checked `containsKey("fileUrl")`, which could match text messages containing `"fileUrl": null`. Flutter `MessageModel.hasAttachment` checks `fileUrl != null && fileUrl!.isNotEmpty` so only real attachments/links appear.
5. **Admin Weekly `New Users` Query Fix:**
   - Kotlin `AdminReportsActivity` queried `users.updatedAt >= weekAgo` using a `Long` against a Firestore `Timestamp` field. Flutter `AdminRepository.fetchWeeklyReports()` handles both Firestore `Timestamp` and epoch `int` values cleanly.
6. **File Upload Fallback:**
   - Active group uploads continue using `https://catbox.moe/user/api.php` (`CatboxUploadDataSource`), with automatic fallback to `FirebaseStorage` (`FirebaseStorageDataSource`) if Catbox fails.
7. **Charts Library (`fl_chart`):**
   - `AdminReportsActivity`'s custom `Canvas` bar chart is migrated to `fl_chart` `BarChart` with identical bar colors (`#3B82F6`, `#10B981`, `#8B5CF6`), 7-day weekday labels, and count labels above non-zero bars.

---

## 3. Verification Status

- `flutter analyze`: **0 issues found**
- `flutter test`: All unit & widget tests passing
- Original Kotlin source files in `app/` and Firebase database remain completely unmodified.
