# EduBond — Kotlin-to-Flutter Migration Plan (`MIGRATION_PLAN.md`)

> **Project Name:** EduBond (*Digital Platform for Academic Peers*)  
> **Original Android Namespace / Package:** `com.example.peermatrix` (Root project: `peerMatrix`)  
> **Target Platform:** Flutter (Dart) connecting to the **exact same existing Firebase project** (`peermatrix-6a1db`) and preserving **100% of Firestore collections, document ID conventions, field names, and business rules**.  
> **Migration Rule:** Analysis & planning phase only. No existing Kotlin/XML/Gradle files or Firebase resources have been modified.

---

## 1. Complete Feature Inventory

Below is the exhaustive inventory of every Activity, helper, asset, and workflow found in the Kotlin project.

### 1.1 Intro & Authentication Module

#### 1.1.1 Animated Lamp Intro Splash
- **Existing Kotlin Class / Asset:** `AnimatedLoginActivity.kt`, `app/src/main/assets/login.html`
- **What it does:** Displays an interactive dark-themed splash screen featuring an animated SVG study lamp with closed eyes and a pull-string knob. Pulling/tapping the string lights up the lamp, reveals a smiling face and warm light beam, displays `"Welcome to EduBond"`, and navigates to `MainActivity`.
- **UI Components:** Fullscreen `WebView` (`javaScriptEnabled = true`, `domStorageEnabled = true`) rendering `login.html` (HTML5, CSS3 transitions, inline SVG gradients & paths, Vanilla JS `mousedown`/`touchstart` handlers).
- **Business Logic:** Exposes `@JavascriptInterface fun onIntroDone()` under bridge name `"Android"`. After the 250ms pull animation and 1500ms welcome glow, JS invokes `window.Android.onIntroDone()`, launching `MainActivity` with `introDone = true` and fade transition (`fade_in` / `fade_out`).
- **Firebase Collections & Fields:** None directly.
- **Navigation Destinations:** `MainActivity` (`introDone = true`).
- **Dependencies:** Triggered by `MainActivity` when `!introDone && !fromLogout` and no valid local+Firebase session exists.

#### 1.1.2 User Login, Session Routing, Google + App Password Linking, Forgot Password, Admin Login & About Us
- **Existing Kotlin Classes:** `MainActivity.kt`, `AuthUIHelper.kt`, `AuthViews.kt`
- **What it does:** Serves as the `MAIN` / `LAUNCHER` activity handling session auto-routing and 6 internal page states (`Page.LOGIN`, `Page.FORGOT_PASSWORD`, `Page.ADMIN_LOGIN`, `Page.SET_PASSWORD`, `Page.APP_PASSWORD`, `Page.ABOUT_US`).
- **UI Components:**
  - `loginPageRoot()`: Blue-lavender vertical gradient (`#CFE8FF` → `#EDE7FF` → `#F8FBFF`) with translucent white card (`#F2FFFFFF`, 28dp corners, 1dp `#AAB7C8` stroke).
  - `brandHeader()`: Book emoji (`📖`) + `"EduBond"` + `"Digital Platform for Academic Peers"`.
  - `iconInput()` (`R.drawable.ic_mail`) & `passwordInputWithEye()` (`EyeToggleView` custom Canvas toggle).
  - Buttons: `Login` (`#0057D8`), `Forgot Password?`, `Continue with Google` (`#006B57`), `Login as Admin` (`#4B008C`), `About Us`.
  - `adminLoginPageRoot()`: `AdminShieldLogoView` (Canvas shield + checkmark), `AdminUserIconView`, `AdminLockIconView`, `EyeToggleView`, purple gradient `Login as Admin` button (`#6A1B9A` → `#8E24AA`), `Back` button (`#9CA3AF`).
  - `setPasswordPageRoot()` & `appPasswordPageRoot()`: `GreenLockBadgeView`, `LockBadgeView`, `SmallLockView`, `setPasswordInfoCard()` / `infoCard()`, password inputs with eye toggles.
  - `showAboutUsPage()`: Circular `developer_pic.png` (fallback `ic_logo_edu.xml`), developer bio (`Md. Lemon Islam Bappy`, B.Sc. in CSE, BAUST), clickable email (`mailto:`), LinkedIn, and GitHub links.
- **Business Logic:**
  1. **Startup:** Calls `FirebaseHistoryManager.seedDefaultQuizzesToCloud()`. Checks `intent.getStringExtra("action") == "forgot_password"` to jump straight to Forgot Password. Otherwise validates BOTH `auth.currentUser != null` (with non-empty email) AND `AppStorage.getCurrentUser(this).isNotEmpty()`. If Firebase user exists without local user, signs out both. Routes authenticated users to `UserHomeActivity`; otherwise routes to `AnimatedLoginActivity` (unless `introDone` or `fromLogout`).
  2. **Email/Password Login:** `auth.signInWithEmailAndPassword(email, password)` → saves `AppStorage.setCurrentUser(email)` → merges user document to `users/{uid}` (`loginProvider = "google+password"`, `googleVerified = true`, `passwordSet = true`) → navigates to `UserHomeActivity`.
  3. **Google Sign-In + App Password Layer:** Uses `CredentialManager` + `GetSignInWithGoogleOption` (`R.string.default_web_client_id`) → `GoogleAuthProvider.getCredential(idToken, null)` → `auth.signInWithCredential`. Reloads `FirebaseUser`, queries `users/{uid}`:
     - If `passwordSet == true` (or `FirebaseAuthUserCollisionException`): navigates to `Page.APP_PASSWORD` requiring the user's App Password via `auth.signInWithEmailAndPassword(email, pass)` before entering `UserHomeActivity`.
     - If `passwordSet != true`: navigates to `Page.SET_PASSWORD` requiring min 6-char password + confirmation → calls `currentUser.linkWithCredential(EmailAuthProvider.getCredential(email, password))` → saves user to `users/{uid}` → navigates to `UserHomeActivity`.
  4. **Forgot Password:** Validates non-empty email containing `@` → `auth.sendPasswordResetEmail(email)` → returns to `Page.LOGIN`.
  5. **Admin Login:** Calls `FirebaseHistoryManager.checkAdminLogin(adminId, password)`. On success, signs out any Firebase student user (`auth.signOut()` + `AppStorage.logout()`) and opens `AdminActivity`.
  6. **Back Navigation:** `FORGOT_PASSWORD`, `ADMIN_LOGIN`, `ABOUT_US` return to `LOGIN`; `SET_PASSWORD` and `APP_PASSWORD` sign out and return to `LOGIN`.
- **Firebase Collections & Fields:**
  - `users/{uid}` (`uid`, `username`, `email`, `photoUrl`, `role`, `loginProvider`, `googleVerified`, `passwordSet`, `updatedAt`)
  - `admin_config/credentials` (`id`, `password`)
  - Triggers `quizzes/{subject}` & `subjects/{subId}` seeding on startup.
- **Navigation Destinations:** `AnimatedLoginActivity`, `UserHomeActivity`, `AdminActivity`, external Mail/Browser intents (About Us).
- **Dependencies:** `AppStorage`, `FirebaseHistoryManager`, `CredentialManager`, Google Play Services Auth.

---

### 1.2 Student / User Core Module

#### 1.2.1 Student Dashboard (`UserHomeActivity`)
- **Existing Kotlin Class:** `UserHomeActivity.kt`
- **What it does:** Main student home hub showing user greeting, profile avatar shortcut, and 4 core navigation tiles.
- **UI Components:**
  - Top bar: `"EduBond Dashboard"` (`#0061FF`) + circular initials `profileBadge` (`#93C5FD` circle, first 2 uppercase chars of username/email).
  - Gradient Hero Card (`#1D4ED8` → `#7C3AED`, 32dp radius): `"Welcome, <username>"` & `"Ready to learn together?"`.
  - 2×2 `GridLayout` of rounded white cards (28dp radius, 6dp elevation) with tinted circular icon wrappers (`adjustAlpha(color, 0.08f)`) and custom Canvas icons (`SearchIcon`, `UsersIcon`, `ChatIcon`, `LogoutIcon`):
    1. `Search & Learn` (`#2563EB`)
    2. `Group Requests` (`#7C3AED`)
    3. `My Groups` (`#059669`)
    4. `Logout` (`#475569`)
- **Business Logic:** Guards against null `auth.currentUser` or empty email (logs out and returns to `MainActivity` with `fromLogout = true`). Syncs `AppStorage.setCurrentUser(email)`. Reads `users/{uid}` to update `welcomeTitle` and `profileBadge`. Logout shows confirmation `AlertDialog`, signs out Firebase & `AppStorage`, clears task stack to `MainActivity`.
- **Firebase Collections & Fields:** `users/{uid}` (`username`).
- **Navigation Destinations:** `UserProfileActivity`, `SubjectActivity`, `RequestsActivity`, `MyGroupsActivity`, `MainActivity`.
- **Dependencies:** `FirebaseAuth`, `AppStorage`.

#### 1.2.2 User Profile & Password Management (`UserProfileActivity`)
- **Existing Kotlin Class:** `UserProfileActivity.kt`
- **What it does:** Allows users to view and edit their display name and biodata, or update their app password.
- **UI Components:** Single header with `←` back button (toggles back from `edit`/`password` sub-views to `view`, or finishes activity from `view`), white rounded card (`24dp`) with 3 internal views:
  1. `view`: Shows Display Name, Biodata, `"Edit Profile"` (`#2563EB`), `"Change App Password"` (`#7C3AED`).
  2. `edit`: Single-line `New Display Name` input, 4-line `Biodata / About Me` input, `"Update Name & Bio"` (`#0D9466`), `"Cancel"`.
  3. `password`: `Current App Password`, `New App Password`, `"Update Password"` (`#7C3AED`), `"Forgot Password?"`, `"Cancel"`.
- **Business Logic:** Loads `username` and `biodata` (fallback `"User"` / `"No bio added yet."`) from `users/{uid}`. Updates via `SetOptions.merge()`. Password change validates non-empty fields & `newPass.length >= 6`, re-authenticates via `EmailAuthProvider.getCredential(email, oldPass)`, then calls `user.updatePassword(newPass)`. `"Forgot Password?"` launches `MainActivity` with `action = "forgot_password"`.
- **Firebase Collections & Fields:** `users/{uid}` (`username`, `biodata`).
- **Navigation Destinations:** `MainActivity` (`action = "forgot_password"`).
- **Dependencies:** `FirebaseAuth`, `FirebaseFirestore`.

---

### 1.3 Subjects, Roles & Teacher Qualification Quiz Module

#### 1.3.1 Subject Search & New Subject Request (`SubjectActivity`)
- **Existing Kotlin Class:** `SubjectActivity.kt`
- **What it does:** Displays searchable list of all global subjects and allows students to request new subjects from the admin.
- **UI Components:** Search card (`EditText` `"Search subject, e.g. Data S"`, `"REQUEST NEW SUBJECT ADD"` button in `#0D9466`), clickable `"Subject List: (Click to show)"` collapsible toggle header, dynamically populated uppercase subject cards, `"BACK"` button (`#334155`).
- **Business Logic:** Loads subjects via `FirebaseHistoryManager.getGlobalSubjects`. Filters case-insensitively on text change (`TextWatcher`); typing automatically expands the list. Pressing `"REQUEST NEW SUBJECT ADD"` validates non-empty search box text and writes a pending request to `subject_requests`.
- **Firebase Collections & Fields:**
  - `subjects` (read `name` / doc ID, auto-seeds 16 core subjects if empty)
  - `subject_requests` (write `id`, `subject`, `by`, `status = "pending"`, `timestamp`)
- **Navigation Destinations:** `SubjectDetailActivity` (passes `subject` extra).
- **Dependencies:** `AppStorage.getCurrentUser`, `FirebaseHistoryManager`.

#### 1.3.2 Subject Role Selection & Subject Study Groups (`SubjectDetailActivity`)
- **Existing Kotlin Class:** `SubjectDetailActivity.kt`
- **What it does:** Lets a user choose whether to **study** or **teach** a subject; if studying, lets them create a new group or join/open existing subject groups.
- **UI Components:**
  - **Role Selection View:** Header (`←` + subject name), `"I want to study this"` card (`StudyOptionIcon`, `#2563EB`), `"I want to teach this"` card (`TeachOptionIcon`, `#7C3AED`).
  - **Subject Groups View:** Header (`←` returns to Role Selection), `"Start a Study Group"` card (`Enter Group Name` input + `Create Group` button), `"Available Groups"` list showing group name, `"Members: X • Teachers: Y"`, and either `"Open Group"` (`#059669`) or `"Request to Join"` (`#EFF6FF` / `#2563EB`).
- **Business Logic:**
  - **Study flow:** Calls `addSubjectRole(email, subject, "learner")` → switches to Subject Groups UI → loads `getGroupsBySubject(subject)`. Membership check verifies if user email (case-insensitive) is in `members`, `teachers`, or equals `createdBy`.
  - **Teach flow:** Calls `getUserSubjectRoles(email)`. If already `"teacher"` for `subject`, shows toast `"You are already a teacher for $subject"` and stops. Otherwise checks `getQuizStatus(email, subject)`; if `blocked == true`, shows blocked toast; otherwise launches `TeacherQuizActivity`.
- **Firebase Collections & Fields:**
  - `user_roles/{email_subject}` (`email`, `subject`, `role`, `score`, `timestamp`)
  - `quiz_attempts/{email_subject}` (`blocked`)
  - `groups` (`id`, `name`, `subject`, `createdBy`, `members`, `teachers`, `timestamp`)
  - `group_join_requests` (`id`, `groupId`, `groupName`, `subject`, `requester`, `status`, `timestamp`)
  - `activity_logs` (logged on `createGroup`)
- **Navigation Destinations:** `TeacherQuizActivity` (`subject` extra), `GroupRoomActivity` (`groupId`, `groupName` extras).
- **Dependencies:** `AppStorage`, `FirebaseHistoryManager`.

#### 1.3.3 Teacher Qualification Quiz (`TeacherQuizActivity`)
- **Existing Kotlin Class:** `TeacherQuizActivity.kt`
- **What it does:** Administers a timed 10-question MCQ exam to qualify a user as a verified teacher for a specific subject.
- **UI Components:**
  - **Rules Screen (`showRulesUI`):** Card listing 6 rules (Subject, Time Limit: 5 Minutes, Minimum Score: 7/10, Total Questions: 10, Max Attempts: 2, Auto-submit on timeout) + `"Start Exam"` (`#059669`) and `"Cancel"` buttons.
  - **Exam Screen (`setupUI`):** Fixed top header with `"Quiz: <subject>"` and monospace countdown badge (`"05:00"` in `#FEE2E2` pill, turns `Color.RED` below 60 seconds), scrollable list of 10 white question cards (`RadioGroup` with 4 `RadioButton` options each), and `"Submit Quiz"` button (`#2563EB`).
- **Business Logic:**
  1. Checks `getQuizStatus(email, subject)`: finishes immediately if `blocked == true` or `attempts >= 2`.
  2. Loads quiz sets from Firestore `quizzes/{subject}` first, falling back to `AppStorage.getQuizSets(subject)` (which seeds defaults into `SharedPreferences` if missing).
  3. Selects question set index using `totalAttempts % sets.size` and requires the selected set to have `>= 10` questions.
  4. Starts `CountDownTimer(300_000, 1_000)`.
  5. Manual submit requires all 10 `RadioGroup`s to have a selection; timer finish triggers `performSubmit()` automatically even with unanswered questions.
  6. Grades answers against `question.answer` (`score >= 7` passes).
  7. Calls `recordQuizResult(email, subject, passed)`: increments `attempts` and `totalAttempts`; if `passed`, resets `attempts = 0`; if `!passed && attempts >= 2`, sets `blocked = true`.
  8. On pass, calls `addSubjectRole(email, subject, "teacher", score)`. Cancels timer in `onDestroy()`.
- **Firebase Collections & Fields:**
  - `quiz_attempts/{email_subject}` (`email`, `subject`, `attempts`, `totalAttempts`, `blocked`, `lastPassed`, `timestamp`)
  - `quizzes/{subject}` (`quizJson`)
  - `user_roles/{email_subject}` (`email`, `subject`, `role = "teacher"`, `score`, `timestamp`)
- **Navigation Destinations:** Returns (`finish()`) to `SubjectDetailActivity`.
- **Dependencies:** `AppStorage`, `FirebaseHistoryManager`, `CountDownTimer`.

---

### 1.4 Group Management, Requests & Real-Time Collaboration Module

#### 1.4.1 Requests Center (`RequestsActivity`)
- **Existing Kotlin Class:** `RequestsActivity.kt`
- **What it does:** Central screen for approving/rejecting incoming group join requests, accepting/rejecting teaching invitations, and tracking sent join requests.
- **UI Components:** 3 stacked sections (`Join Requests`, `Teaching Requests`, `My Sent Requests`) with white 24dp rounded cards and green (`#10B981`) / red (`#EF4444`) action buttons.
- **Business Logic:**
  - **Incoming Join Requests:** Calls `getIncomingJoinRequests(email)` (fetches user's groups via `getGroupsForUser`, queries `group_join_requests` where `groupId in groupIds` and `status == "pending"`, filters out requests sent by `email`). Approve updates request `status = "accepted"` and appends `requester` to `groups/{groupId}.members` via `FieldValue.arrayUnion`. Reject updates `status = "rejected"`.
  - **Incoming Teaching Requests:** Queries `teacher_group_requests` where `teacher == email` and `status == "pending"`. Accept updates `status = "accepted"` and appends `email` to `groups/{groupId}.teachers` via `FieldValue.arrayUnion`. Reject updates `status = "rejected"`.
  - **My Sent Requests:** Queries `group_join_requests` where `requester == email` and shows `groupName` + `status`.
- **Firebase Collections & Fields:** `groups`, `group_join_requests`, `teacher_group_requests`.
- **Navigation Destinations:** Finishes back to `UserHomeActivity` (refreshes self via `showUI()` after action).
- **Dependencies:** `AppStorage`, `FirebaseHistoryManager`.

#### 1.4.2 My Groups List (`MyGroupsActivity`)
- **Existing Kotlin Class:** `MyGroupsActivity.kt`
- **What it does:** Displays all study groups where the current user is either a member or a teacher.
- **UI Components:** Header `"My Groups"`, scrollable list of cards (`name`, `subject`), empty state message, `"BACK"` button (`#334155`).
- **Business Logic:** Queries `groups` where `members array-contains email` AND `teachers array-contains email`, merges and deduplicates by `id`. Refreshes in `onResume()` (so leaving a group updates the list immediately).
- **Firebase Collections & Fields:** `groups` (`id`, `name`, `subject`, `members`, `teachers`).
- **Navigation Destinations:** `GroupRoomActivity` (`groupId`, `groupName` extras).
- **Dependencies:** `AppStorage`, `FirebaseHistoryManager`.

#### 1.4.3 Group Chat Room (`GroupRoomActivity`)
- **Existing Kotlin Class:** `GroupRoomActivity.kt`
- **What it does:** Real-time WhatsApp-style group messaging room supporting text messages, URL/email auto-linking, read receipts, message unsending, cloud file sharing, and video meeting link sharing.
- **UI Components:**
  - `RelativeLayout` with `fitsSystemWindows = true` and `windowSoftInputMode="adjustResize"` in Manifest.
  - Top Header (`#075E54`): `←` back button, clickable title + subtitle (`Teachers: ...` or `tap for group info`), overflow menu (`⋮` → `Group Info`).
  - Chat Area (`#E5DDD5` background): `ScrollView` with aligned message bubbles (`#DCF8C6` right-aligned for `isMe`, `#FFFFFF` left-aligned with sender username in `#075E54` for others). Attachment card inside bubble (`📹` for `meeting`, `🖼️` for image, `📄` for docs), `Linkify` web/email links, `hh:mm a` timestamp, and `✓` / blue `✓✓` (`#34B7F1`) seen indicator.
  - Bottom Input Bar: Rounded white pill (`📎` attachment picker, `📹` meeting link dialog trigger, `Message` `EditText`) + circular `#075E54` send button (`SendIconView` Canvas triangle).
- **Business Logic:**
  - Attaches real-time Firestore `addSnapshotListener` on `groups/{groupId}/messages` ordered by `timestamp`, auto-scrolling to bottom.
  - Resolves sender display names asynchronously via `getUserNameGlobally(senderEmail)`.
  - Automatically marks unseen messages as read via `markMessageAsRead` (`FieldValue.arrayUnion(email)`). Displays `✓✓` when `seenBy.size > 1`.
  - Long-press on own bubble opens `"Unsend"` `AlertDialog` calling `deleteMessage(groupId, msgId)`.
  - **Meeting Link Dialog:** Validates non-empty URL starting with `http`, detects platform (`zoom` → `"Zoom"`, `meet.google` → `"Google Meet"`, `jitsi` → `"Jitsi"`, else `"Live"`), posts via `saveMeetingLink` (`fileType = "meeting"`, `fileName = platform`).
  - **File Sharing:** Opens `Intent.ACTION_OPEN_DOCUMENT` (`*/*`), takes persistable permission if supported, extracts display name via `OpenableColumns.DISPLAY_NAME` & MIME via `contentResolver.getType`, uploads bytes via OkHttp multipart POST to `https://catbox.moe/user/api.php` (`uploadFileFree`), and saves message with returned URL. (Note: `uploadFile` and `uploadFileToFirebase` using Firebase Storage also exist in `FirebaseHistoryManager` as unused/alternative methods.)
  - **Opening Files/Meetings:** Opens `http` URLs and meeting links via `Intent.ACTION_VIEW`; includes fallback Google Docs Viewer / MIME intent logic for non-HTTP URIs.
- **Firebase Collections & Fields:**
  - `groups/{groupId}` (`name`, `teachers`)
  - `groups/{groupId}/messages/{messageId}` (`groupId`, `senderEmail`, `message`, `fileUrl`, `fileType`, `fileName`, `timestamp`, `seenBy`)
  - `users` (sender name lookup)
  - `activity_logs` (logged on every `saveMessage`)
- **Navigation Destinations:** `GroupInfoActivity` (`groupId` extra), external Browser/Viewer/Meeting apps.
- **Dependencies:** `OkHttpClient`, `catbox.moe` HTTP endpoint, `AppStorage`, `FirebaseHistoryManager`.

#### 1.4.4 Group Information & Teacher Hiring (`GroupInfoActivity`)
- **Existing Kotlin Class:** `GroupInfoActivity.kt`
- **What it does:** Displays group metadata, teachers, members, allows hiring qualified teachers for the subject, opens shared files, and lets the user leave the group.
- **UI Components:** Header (`←` + group name), Group Details card (`Subject:`, `Creator:`), `Teachers` section, `Members` section, `Hire Qualified Teachers` section (each with `Request` button), `"📁 View Shared Files"` (`#3B82F6`), `"Leave Group"` (`#EF4444`).
- **Business Logic:** Fetches group doc via `getGroupInfo(groupId)`. Queries `getQualifiedTeachers(subject)` (`user_roles` where `role == "teacher"`), filters out teachers already in `groups/{groupId}.teachers`, and sends invites via `requestTeacherToJoin` (disables button & changes text to `"Sent"`). Leave Group shows confirmation dialog, removes user email from both `members` and `teachers` arrays, and navigates to `MyGroupsActivity` (`FLAG_ACTIVITY_CLEAR_TOP`).
- **Firebase Collections & Fields:** `groups/{groupId}`, `user_roles`, `users`, `teacher_group_requests`.
- **Navigation Destinations:** `SharedFilesActivity` (`groupId` extra), `MyGroupsActivity`.
- **Dependencies:** `AppStorage`, `FirebaseHistoryManager`.

#### 1.4.5 Shared Files Gallery (`SharedFilesActivity`)
- **Existing Kotlin Class:** `SharedFilesActivity.kt`
- **What it does:** Lists all files shared inside a group room with click-to-open and long-press-to-unsend (for uploader).
- **UI Components:** Header (`←` + `"Shared Files"`), scrollable list of file cards (`🖼️` / `📄` icon, `fileName`, `"Shared by <name> • <hh:mm a>"`), empty state `"No files shared yet"`.
- **Business Logic:** Subscribes to `getGroupMessages(groupId)`, filters `messages.filter { it.containsKey("fileUrl") }`, resolves uploader names via `getUserNameGlobally`, opens URLs via `Intent.ACTION_VIEW`, and allows uploader (`senderEmail == currentUser`) to long-press and unsend (`deleteMessage`).
- **Firebase Collections & Fields:** `groups/{groupId}/messages`, `users`.
- **Navigation Destinations:** External Browser/File Viewer apps.
- **Dependencies:** `AppStorage`, `FirebaseHistoryManager`.

---

### 1.5 Admin Panel Module

#### 1.5.1 Admin Dashboard (`AdminActivity`)
- **Existing Kotlin Class:** `AdminActivity.kt`
- **What it does:** Main administration dashboard with quick navigation to user management, subjects/quizzes, weekly reports, and logout.
- **UI Components:** Header (`"Admin Panel"` + `AdminShieldIcon` badge), purple gradient hero card (`#6366F1` → `#A855F7`, `"Welcome, Admin"`, `"System overview and management"`), 2×2 `GridLayout` (`Manage Users` → `AdminUserActivity`, `Subjects` → `AdminSubjectActivity`, `Reports` → `AdminReportsActivity`, `Logout` → confirmation dialog returning to `MainActivity` with `fromLogout = true`). *(Note: `TeacherMenuIcon` inner class is defined in `AdminActivity.kt` but not placed in the 4-tile grid because teacher management is embedded inside `AdminUserActivity`.)*
- **Firebase Collections & Fields:** None directly.
- **Navigation Destinations:** `AdminUserActivity`, `AdminSubjectActivity`, `AdminReportsActivity`, `MainActivity`.

#### 1.5.2 User & Teacher Management (`AdminUserActivity` & `AdminTeacherActivity`)
- **Existing Kotlin Classes:** `AdminUserActivity.kt`, `AdminTeacherActivity.kt`
- **What they do:**
  - **`AdminUserActivity`** (opened from `AdminActivity`): Provides 2 primary tabs (`All Users`, `Teachers`) and 2 sub-tabs under `Teachers` (`Active Teachers`, `Blocked Teachers`), plus live search and count summary (`infoTv`).
    - *All Users:* Search by username/email; `"Add Role"` opens single-choice subject dialog and assigns `"teacher"` role with `score = 10`; `"Remove"` deletes `users/{uid}` document after confirmation.
    - *Active Teachers:* Search by email/subject; displays `"Verified Score: X/10"`; `"Remove Teaching Role"` deletes `user_roles/{docId}` after confirmation.
    - *Blocked Teachers:* Search by email/subject; `"Unblock User"` sets `blocked = false, attempts = 0` on `quiz_attempts/{attemptId}`.
  - **`AdminTeacherActivity`** (registered in `AndroidManifest.xml`, standalone alternative screen): Provides `Teachers` & `Blocked` tabs with live search, resolves teacher display names via `getUserNameGlobally`, removes teacher roles (`removeTeacherRoleGlobally`), and unblocks teachers (`unblockTeacherGlobally`).
- **Firebase Collections & Fields:** `users`, `user_roles`, `quiz_attempts`, `subjects`.
- **Navigation Destinations:** Returns via `←`.

#### 1.5.3 Subject & Subject Request Management (`AdminSubjectActivity`)
- **Existing Kotlin Class:** `AdminSubjectActivity.kt`
- **What it does:** Manages global subjects and approves/edits/rejects user-submitted subject requests.
- **UI Components:** 2 tabs (`Subject List`, `Requests`), search bar, `"+ Add New Subject"` button (`#10B981`), subject cards with `"Questions"` (`#3B82F6`) & `"Delete"` (`#EF4444`) buttons, request cards with `"Accept"`, `"Edit"`, and `"Reject"` buttons.
- **Business Logic:**
  - *Subject List:* Fetches `getGlobalSubjects`, filters by `searchQuery`. Add dialog calls `addSubjectGlobally(name)` (`type = "admin"`). Delete confirmation calls `deleteSubjectGlobally(name)`. `"Questions"` launches `AdminQuizActivity`.
  - *Requests:* Fetches `getSubjectRequests`, filters `status == "pending"` and `searchQuery` (case-sensitive `indexOf` in Kotlin). `"Accept"` marks `status = "accepted"` and adds subject globally; `"Edit"` opens `EditText` dialog to rename before accepting & adding globally; `"Reject"` marks `status = "rejected"`.
- **Firebase Collections & Fields:** `subjects`, `subject_requests`.
- **Navigation Destinations:** `AdminQuizActivity` (`subject` extra).

#### 1.5.4 Quiz Set Editor (`AdminQuizActivity`)
- **Existing Kotlin Class:** `AdminQuizActivity.kt`
- **What it does:** Allows admin to create or edit 4 MCQ sets (`Set 1`–`Set 4`) of 10 questions each per subject.
- **UI Components:** Header (`←` + `"Quiz Sets: <subject>"`), horizontal pill selector (`Set 1`..`Set 4`), 10 `QuizInputGroup` cards (Question Text, Option 1–4, Correct Answer), `"Save Set X"` button (`#10B981`).
- **Business Logic:** Loads local sets from `AppStorage.getQuizSets(subject)` first for speed, then syncs from Firestore `quizzes/{subject}` (ensuring 4 sets exist in memory). Validates all 6 fields on all 10 questions are non-empty, serializes to `JSONArray`, saves locally (`AppStorage.saveQuizSets`) AND uploads to Firestore (`FirebaseHistoryManager.saveQuizSets`).
- **Firebase Collections & Fields:** `quizzes/{subject}` (`subject`, `quizJson`, `lastUpdated`).
- **Navigation Destinations:** Returns via `←`.

#### 1.5.5 System Reports & Weekly Analytics (`AdminReportsActivity`)
- **Existing Kotlin Class:** `AdminReportsActivity.kt`
- **What it does:** Displays total registered users and 3 weekly bar charts covering the last 7 days.
- **UI Components:** `"Total Users"` stat card + 3 custom Canvas `WeeklyBarChartView` cards (`New Users (Weekly)` in `#3B82F6`, `New Groups (Weekly)` in `#10B981`, `New Teachers (Weekly)` in `#8B5CF6`) showing 7 weekday bars (`EEE`), rounded tops, base line, and counts above bars.
- **Business Logic:** Counts all docs in `users`. Computes `weekAgo` (`Calendar.DAY_OF_YEAR - 7`), queries `users` (`updatedAt >= weekAgo`), `groups` (`timestamp >= weekAgo`), and `user_roles` (`role == "teacher"` and `timestamp >= weekAgo`). Aggregates counts by 3-letter weekday (`SimpleDateFormat("EEE")`) supporting both `Long` millis and `com.google.firebase.Timestamp`.
- **Firebase Collections & Fields:** `users` (`updatedAt`), `groups` (`timestamp`), `user_roles` (`role`, `timestamp`).

---

### 1.6 Unused / Legacy / Helper Components Found
- `Ui.kt`: Legacy programmatic UI helper (`root`, `title`, `subtitle`, `input`, `button`, `card`, `dp`) not called by current activities.
- `QuizSeeder.kt`: Deprecated stub (`// This file is deprecated. Manual entry via AdminQuizActivity is preferred.`).
- `res/layout/activity_main.xml`: Unused template XML layout containing a single `"Bappy"` `TextView`.
- `FirebaseHistoryManager.addNote`, `getNotes`, `updateSubjects`, `uploadFile`, `uploadFileToFirebase`: Helper methods present in `FirebaseHistoryManager.kt` (`notes` collection, `app_data/subjects`, Firebase Storage uploads) not currently invoked by active UI screens, but documented below for completeness.

---

## 2. Existing Project Architecture

```
+-------------------------------------------------------------------+
|                        Presentation Layer                         |
|  18 Android Activities (Programmatic Views + Canvas Custom Views) |
|  + 1 WebView Intro Activity (assets/login.html + JS Bridge)       |
+-------------------------------------------------------------------+
         |                                           |
         v                                           v
+---------------------------+        +------------------------------+
|  Local Persistence Layer  |        |   Cloud & Network Layer      |
|  AppStorage (object)      |        |   FirebaseHistoryManager     |
|  - SharedPreferences      |        |   - FirebaseAuth             |
|    ("PeerMatrixLocalDB")  |        |   - FirebaseFirestore        |
|  - Pre-seeded JSON Quiz   |        |   - FirebaseStorage          |
|    Banks (9 subjects)     |        |   - OkHttp -> catbox.moe API |
+---------------------------+        +------------------------------+
```

### Key Architectural Characteristics
1. **Activity-Centric Architecture:** Navigation uses explicit `Intent`s with string/boolean extras (`subject`, `groupId`, `groupName`, `introDone`, `fromLogout`, `action`). There are no Fragments, ViewModels, or Navigation Graph XML files.
2. **Programmatic View Construction:** Every screen builds its view hierarchy in Kotlin (`ScrollView`, `LinearLayout`, `GridLayout`, `RelativeLayout`) using `GradientDrawable` styling and custom `View.onDraw(Canvas)` vector icons/charts.
3. **Callback-Based Asynchronous Data Flow:** `FirebaseHistoryManager` exposes callback lambdas (`onResult`, `onComplete`, `onUpdate`) over Firebase Tasks and OkHttp `enqueue`, marshaling UI updates via `runOnUiThread { ... }`. Only Google Sign-In (`CredentialManager`) uses `CoroutineScope(Dispatchers.Main).launch`.
4. **Dual-Layer Auth Session:** Auth state relies on BOTH `FirebaseAuth.getInstance().currentUser` AND `SharedPreferences` (`PeerMatrixLocalDB -> current_user`), except Admin login which bypasses `FirebaseAuth` and validates against Firestore `admin_config/credentials` (signing out any active student `FirebaseAuth` session).
5. **Hybrid File Storage:** Although `firebase-storage` is configured (`peermatrix-6a1db.firebasestorage.app`) and helper methods (`uploadFile`, `uploadFileToFirebase`) exist, active chat file uploads in `GroupRoomActivity` call `uploadFileFree()` which posts multipart form-data to `https://catbox.moe/user/api.php`.

---

## 3. Existing Firestore Database Schema & Local Storage

**Existing Firebase Project:** `peermatrix-6a1db`  
**Existing Storage Bucket:** `peermatrix-6a1db.firebasestorage.app`

### 3.1 Firestore Collections

| Collection / Path | Document ID Pattern | Fields & Types | Operations (Read / Write / Delete) |
| :--- | :--- | :--- | :--- |
| `users/{uid}` | Firebase Auth `uid` | `uid` (`String`), `username` (`String`), `email` (`String`), `photoUrl` (`String`), `role` (`"user"`), `loginProvider` (`"google+password"`), `googleVerified` (`Boolean`), `passwordSet` (`Boolean`), `biodata` (`String`, optional), `updatedAt` (`FieldValue.serverTimestamp()`) | `MainActivity` (merge write, read `passwordSet`), `UserHomeActivity` (read `username`), `UserProfileActivity` (read & merge `username`, `biodata`), `FirebaseHistoryManager.getUserNameGlobally` (query `whereEqualTo("email", email)`), `AdminUserActivity` (list all, delete `uid`), `AdminReportsActivity` (count all, query `updatedAt >= weekAgo`) |
| `subjects/{subjectId}` | `name.trim().replace(" ", "_").lowercase()` | `name` (`String`), `type` (`"core"` \| `"admin"`) | `FirebaseHistoryManager.getGlobalSubjects` (read all, auto-seed 16 core docs if empty), `seedDefaultQuizzesToCloud` (create if missing), `addSubjectGlobally` (set), `deleteSubjectGlobally` (delete) |
| `subject_requests/{requestId}` | `System.currentTimeMillis().toString()` | `id` (`String`), `subject` (`String`), `by` (`String` email), `status` (`"pending"` \| `"accepted"` \| `"rejected"`), `timestamp` (`Long` ms) | `SubjectActivity` (create), `AdminSubjectActivity` (query ordered by `timestamp` DESC, update `status` & optionally `subject`) |
| `quizzes/{subject}` | Exact subject `name` | `subject` (`String`), `quizJson` (`String` — JSON array of sets; each set is array of `{question, options: [4], answer}`), `lastUpdated` (`Long` ms) | `seedDefaultQuizzesToCloud` (set if missing), `TeacherQuizActivity` (get `quizJson`), `AdminQuizActivity` (get & set `quizJson`) |
| `quiz_attempts/{attemptId}` | `"${email.replace(".", "_")}_${subject.replace(" ", "_")}"` | `email` (`String`), `subject` (`String`), `attempts` (`Int` — consecutive fails, reset to `0` on pass), `totalAttempts` (`Int` — cumulative count), `blocked` (`Boolean` — true when `!passed && attempts >= 2`), `lastPassed` (`Boolean`), `timestamp` (`Long` ms) | `SubjectDetailActivity` (get `blocked`), `TeacherQuizActivity` (get status, merge update on submit), `AdminUserActivity` / `AdminTeacherActivity` (query `blocked == true`, update `blocked = false, attempts = 0`) |
| `user_roles/{roleId}` | `"${email.replace(".", "_")}_${subject.replace(" ", "_")}"` | `email` (`String`), `subject` (`String`), `role` (`"learner"` \| `"teacher"`), `score` (`Int`), `timestamp` (`Long` ms) | `SubjectDetailActivity` (set `"learner"`, query by `email`), `TeacherQuizActivity` (set `"teacher"` with score), `GroupInfoActivity` (query `subject` & `role == "teacher"`), `AdminUserActivity` / `AdminTeacherActivity` (query `role == "teacher"`, set with score 10, delete doc), `AdminReportsActivity` (query `role == "teacher"` & `timestamp >= weekAgo`) |
| `groups/{groupId}` | `"G${System.currentTimeMillis()}"` | `id` (`String`), `name` (`String`), `subject` (`String`), `createdBy` (`String` email), `members` (`List<String>` emails), `teachers` (`List<String>` emails), `timestamp` (`Long` ms) | `SubjectDetailActivity` (create group, query `subject`), `MyGroupsActivity` (query `members` arrayContains + `teachers` arrayContains), `GroupRoomActivity` / `GroupInfoActivity` (get by ID, `arrayUnion` on accept, remove on leave), `AdminReportsActivity` (query `timestamp >= weekAgo`) |
| `groups/{groupId}/messages/{messageId}` | Auto-generated Firestore ID | `groupId` (`String`), `senderEmail` (`String`), `message` (`String`), `fileUrl` (`String?`), `fileType` (`String?`), `fileName` (`String?`), `timestamp` (`Long` ms), `seenBy` (`List<String>` emails) | `GroupRoomActivity` (real-time `addSnapshotListener` ordered by `timestamp` ASC, add message, `arrayUnion` on `seenBy`, delete message), `SharedFilesActivity` (real-time listener, delete message) |
| `group_join_requests/{requestId}` | `System.currentTimeMillis().toString()` | `id` (`String`), `groupId` (`String`), `groupName` (`String`), `subject` (`String`), `requester` (`String` email), `status` (`"pending"` \| `"accepted"` \| `"rejected"`), `timestamp` (`Long` ms) | `SubjectDetailActivity` (create), `RequestsActivity` (query `whereIn("groupId", groupIds)` & `status == "pending"`, query `requester == email`, update `status`) |
| `teacher_group_requests/{requestId}` | `System.currentTimeMillis().toString()` | `id` (`String`), `groupId` (`String`), `groupName` (`String`), `subject` (`String`), `requester` (`String` email), `teacher` (`String` email), `status` (`"pending"` \| `"accepted"` \| `"rejected"`), `timestamp` (`Long` ms) | `GroupInfoActivity` (create), `RequestsActivity` (query `teacher == email` & `status == "pending"`, update `status`) |
| `admin_config/credentials` | Fixed doc ID: `"credentials"` | `id` (`String`), `password` (`String`) | `MainActivity` → `checkAdminLogin` (read `id` & `password`; fallback `"Bappy"` / `"Bappy81"` if missing) |
| `activity_logs/{autoId}` | Auto-generated Firestore ID | `email` (`String`), `action` (`String`), `timestamp` (`Long` ms) | Written by `saveMessage` and `createGroup` |
| `notes/{autoId}` *(helper only)* | Auto-generated Firestore ID | `groupId` (`String`), `title` (`String`), `url` (`String`), `type` (`String`), `by` (`String`), `timestamp` (`Long` ms) | `addNote`, `getNotes` (`whereEqualTo("groupId", groupId).orderBy("timestamp", DESCENDING)`) |
| `app_data/subjects` *(legacy)* | Fixed doc ID: `"subjects"` | `list` (`String` JSON) | `updateSubjects` (unused legacy helper) |

### 3.2 Local Storage (`SharedPreferences`)
- **Preference File:** `PeerMatrixLocalDB`
- **Keys:**
  - `current_user`: `String` (trimmed user email; cleared on logout / admin login).
  - `quiz_sets_<subject>`: `String` (JSON array of quiz sets per subject; auto-seeded from `AppStorage` for 9 subjects: 5 CSE English subjects + 4 SSC 9–10 Bengali subjects).

---

## 4. Kotlin-to-Flutter Migration Mapping

### 4.1 Screen & Component Mapping

| Existing Kotlin File | Flutter Target (Screen / Widget / Service) | Notes |
| :--- | :--- | :--- |
| `AnimatedLoginActivity.kt` + `login.html` | `IntroLampScreen` (`webview_flutter` loading `assets/html/login.html` OR native `CustomPainter` + `AnimationController`) | Using `webview_flutter` with `JavaScriptChannel("Android")` preserves the exact SVG lamp pixel-for-pixel; native `CustomPainter` is an optional later enhancement. |
| `MainActivity.kt` + `AuthUIHelper.kt` + `AuthViews.kt` | `AuthGateScreen`, `LoginScreen`, `ForgotPasswordScreen`, `AdminLoginScreen`, `SetAppPasswordScreen`, `AppPasswordScreen`, `AboutUsScreen` + `CustomPainter` icons | Replace `Page` enum swapping with `Navigator` / `GoRouter` routes; preserve exact session check (`FirebaseAuth` + `SharedPreferences`). |
| `UserHomeActivity.kt` | `UserHomeScreen` | `Scaffold` + `GridView.count(crossAxisCount: 2)` + `CustomPaint` icons (`SearchIconPainter`, `UsersIconPainter`, `ChatIconPainter`, `LogoutIconPainter`). |
| `UserProfileActivity.kt` | `UserProfileScreen` | State-driven or sub-routed view/edit/password update UI. |
| `SubjectActivity.kt` | `SubjectSearchScreen` | `TextField` filter + collapsible `AnimatedCrossFade` / `Visibility` subject list + subject request action. |
| `SubjectDetailActivity.kt` | `SubjectDetailScreen` & `SubjectGroupsScreen` | Role choice cards + group creation & subject group list. |
| `TeacherQuizActivity.kt` | `TeacherQuizScreen` | Rules view → 5-minute `Timer.periodic` countdown + 10 MCQ `RadioListTile` cards + auto-submit & pass/block logic. |
| `RequestsActivity.kt` | `RequestsScreen` | 3 sections (`Join Requests`, `Teaching Requests`, `My Sent Requests`). |
| `MyGroupsActivity.kt` | `MyGroupsScreen` | Combined `members` + `teachers` groups list; refresh on route return (`RouteAware` / `Stream`). |
| `GroupRoomActivity.kt` | `GroupRoomScreen` | `Scaffold(resizeToAvoidBottomInset: true)`, `StreamBuilder` on `messages`, `flutter_linkify` / `url_launcher`, `file_picker` + `http`/`dio` upload to `catbox.moe`, meeting dialog, long-press unsend. |
| `GroupInfoActivity.kt` | `GroupInfoScreen` | Metadata, Teachers, Members, Hire Qualified Teachers, Shared Files button, Leave Group. |
| `SharedFilesActivity.kt` | `SharedFilesScreen` | Filtered real-time file list + `url_launcher` + long-press unsend for uploader. |
| `AdminActivity.kt` | `AdminDashboardScreen` | Gradient hero + 2×2 admin grid + `CustomPaint` icons. |
| `AdminUserActivity.kt` | `AdminUsersScreen` | Tabs (`All Users`, `Teachers` with `Active` / `Blocked` sub-tabs) + search + assign role / remove / unblock. |
| `AdminTeacherActivity.kt` | Consolidated into `AdminUsersScreen` (or separate `AdminTeachersScreen`) | Keep parity with both `AdminUserActivity` and `AdminTeacherActivity` behaviors (including name resolution). |
| `AdminSubjectActivity.kt` | `AdminSubjectsScreen` | Tabs (`Subject List`, `Requests`) + search + add/delete subject + accept/edit/reject request. |
| `AdminQuizActivity.kt` | `AdminQuizEditorScreen` | Horizontal `Set 1`–`Set 4` chips + 10 MCQ form controllers saving to `SharedPreferences` & Firestore. |
| `AdminReportsActivity.kt` | `AdminReportsScreen` | Total users card + 3 `WeeklyBarChartPainter` (`CustomPainter`) charts. |
| `FirebaseHistoryManager.kt` | `FirebaseRepository` / modular services (`AuthService`, `SubjectService`, `QuizService`, `GroupService`, `ChatService`, `AdminService`, `FileUploadService`) | Keep every collection name, doc ID pattern, and field name identical. |
| `AppStorage.kt` | `LocalStorageService` + `QuizSeedData` | `shared_preferences` + `dart:convert` (`jsonEncode`/`jsonDecode`) + exact seeded English & Bengali quiz questions. |
| `Ui.kt`, `QuizSeeder.kt`, `activity_main.xml` | *Do not migrate (legacy/unused)* | Confirmed unused/deprecated in Kotlin source. |

### 4.2 Logic & API Mapping

| Kotlin / Android Construct | Flutter / Dart Equivalent |
| :--- | :--- |
| `Activity` + `Intent` extras | `StatefulWidget` / `StatelessWidget` + `Navigator.pushNamed` / `GoRouter` arguments |
| `SharedPreferences("PeerMatrixLocalDB")` | `shared_preferences` (`SharedPreferences.getInstance()`) |
| `org.json.JSONArray` / `JSONObject` | `dart:convert` (`jsonDecode`, `jsonEncode`) + typed Dart models (`QuizQuestion`, `GroupModel`, etc.) |
| `CredentialManager` + `GoogleIdTokenCredential` | `google_sign_in` (`GoogleSignIn.signIn()` → `GoogleAuthProvider.credential(idToken, accessToken)`) |
| `FirebaseAuth` (`linkWithCredential`, `reauthenticate`, `updatePassword`, `sendPasswordResetEmail`) | `firebase_auth` (`User.linkWithCredential`, `User.reauthenticateWithCredential`, `User.updatePassword`, `FirebaseAuth.sendPasswordResetEmail`) |
| `FirebaseFirestore` (`addSnapshotListener`, `FieldValue.arrayUnion`, `serverTimestamp`, `SetOptions.merge()`) | `cloud_firestore` (`snapshots()`, `FieldValue.arrayUnion`, `FieldValue.serverTimestamp()`, `SetOptions(merge: true)`) |
| `OkHttpClient` multipart upload (`catbox.moe`) | `http` `MultipartRequest` (or `dio` `FormData`) |
| `Intent.ACTION_OPEN_DOCUMENT` + `OpenableColumns` | `file_picker` (`FilePicker.platform.pickFiles(withData: true)`) |
| `Intent.ACTION_VIEW` / `mailto:` / `Linkify` | `url_launcher` (`launchUrl` with `LaunchMode.externalApplication`) + `flutter_linkify` (or `linkify` + `RichText`) |
| `CountDownTimer(300000, 1000)` | `Timer.periodic(const Duration(seconds: 1), ...)` |
| `View.onDraw(Canvas)` | `CustomPaint` + `CustomPainter` |
| `WebView` + `@JavascriptInterface` | `webview_flutter` (`WebViewController.loadFlutterAsset` + `addJavaScriptChannel`) |

---

## 5. Recommended Flutter Folder Structure

```text
edubond_flutter/
├── assets/
│   ├── html/
│   │   └── login.html                  # Copied from app/src/main/assets/login.html
│   └── images/
│       └── developer_pic.png           # Copied from app/src/main/res/drawable/developer_pic.png
├── lib/
│   ├── main.dart                       # Firebase.initializeApp + App entry & routing
│   ├── firebase_options.dart           # Generated via flutterfire configure for peermatrix-6a1db
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart         # Exact hex palette (#F8FBFF, #075E54, #DCF8C6, etc.)
│   │   │   ├── firestore_keys.dart     # Exact collection & field name constants
│   │   │   └── quiz_seed_data.dart     # Exact 9-subject MCQ seeds (English & Bengali)
│   │   ├── services/
│   │   │   ├── local_storage_service.dart  # SharedPreferences wrapper (current_user, quiz_sets_*)
│   │   │   └── file_upload_service.dart    # catbox.moe multipart upload + FirebaseStorage fallback
│   │   └── widgets/
│   │       ├── custom_painters.dart    # EyeToggle, LockBadges, AdminShield, MenuIcons, SendIcon, WeeklyBarChart
│   │       └── ui_cards.dart           # Shared rounded cards, gradient buttons, back headers
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── subject_request_model.dart
│   │   │   ├── quiz_question_model.dart
│   │   │   ├── quiz_attempt_model.dart
│   │   │   ├── user_role_model.dart
│   │   │   ├── group_model.dart
│   │   │   ├── message_model.dart
│   │   │   └── group_request_model.dart
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── subject_repository.dart
│   │       ├── quiz_repository.dart
│   │       ├── group_repository.dart
│   │       ├── chat_repository.dart
│   │       └── admin_repository.dart
│   └── features/
│       ├── intro/
│       │   └── intro_lamp_screen.dart
│       ├── auth/
│       │   ├── auth_gate_screen.dart
│       │   ├── login_screen.dart
│       │   ├── forgot_password_screen.dart
│       │   ├── admin_login_screen.dart
│       │   ├── set_app_password_screen.dart
│       │   ├── app_password_screen.dart
│       │   └── about_us_screen.dart
│       ├── home/
│       │   ├── user_home_screen.dart
│       │   └── user_profile_screen.dart
│       ├── subjects/
│       │   ├── subject_search_screen.dart
│       │   ├── subject_detail_screen.dart
│       │   └── teacher_quiz_screen.dart
│       ├── groups/
│       │   ├── my_groups_screen.dart
│       │   ├── requests_screen.dart
│       │   ├── group_room_screen.dart
│       │   ├── group_info_screen.dart
│       │   └── shared_files_screen.dart
│       └── admin/
│           ├── admin_dashboard_screen.dart
│           ├── admin_users_screen.dart
│           ├── admin_subjects_screen.dart
│           ├── admin_quiz_editor_screen.dart
│           └── admin_reports_screen.dart
└── pubspec.yaml
```

---

## 6. Required Flutter Dependencies (`pubspec.yaml` Plan — Do Not Install Yet)

| Package | Purpose | Replaces in Kotlin |
| :--- | :--- | :--- |
| `firebase_core` | Initialize Firebase app (`peermatrix-6a1db`) | `google-services` plugin init |
| `firebase_auth` | Email/password, Google credential, `linkWithCredential`, `reauthenticate`, `updatePassword`, `sendPasswordResetEmail` | `com.google.firebase:firebase-auth` |
| `cloud_firestore` | All 13 Firestore collections, real-time `snapshots()`, `FieldValue.arrayUnion`, `serverTimestamp()` | `com.google.firebase:firebase-firestore` |
| `firebase_storage` | Storage compatibility (`peermatrix-6a1db.firebasestorage.app`) | `com.google.firebase:firebase-storage` |
| `google_sign_in` | Obtain Google ID token for Firebase Auth | `androidx.credentials` + `googleid` |
| `shared_preferences` | `current_user` session flag & `quiz_sets_<subject>` local cache | `android.content.SharedPreferences` |
| `webview_flutter` | Interactive `login.html` lamp splash + JS bridge (`onIntroDone`) | `android.webkit.WebView` |
| `http` *(or `dio`)* | Multipart file upload to `https://catbox.moe/user/api.php` | `com.squareup.okhttp3:okhttp` |
| `file_picker` | Pick `*/*` documents & images from device storage | `Intent.ACTION_OPEN_DOCUMENT` |
| `url_launcher` | Open uploaded files, meeting links (Zoom/Meet/Jitsi), email/LinkedIn/GitHub | `Intent.ACTION_VIEW` / `ACTION_SENDTO` |
| `flutter_linkify` *(or `linkify`)* | Auto-detect clickable web URLs and emails in chat bubbles | `android.text.util.Linkify` |
| `intl` | Format timestamps (`hh:mm a`, 3-letter weekday `EEE` for charts) | `java.text.SimpleDateFormat` |

---

## 7. Phased Migration Strategy

1. **Phase 1 — Flutter Project Bootstrap & Firebase Linking (Separate Directory):**
   - Create a separate Flutter project (`edubond_flutter`) alongside or outside the Kotlin repo, keeping `com.example.peermatrix` package ID and SHA-1 (`8d7f4b6f484c83d28659825451325bd4427bff19`) so the existing `peermatrix-6a1db` OAuth/Firebase configuration works seamlessly without modifying the Firebase project.
   - Add assets (`login.html`, `developer_pic.png`) and exact theme constants.
2. **Phase 2 — Core Data Models, Seeds & Services:**
   - Port `AppStorage` (`LocalStorageService` + exact 9-subject Bengali & English `QuizSeedData`) and `FirebaseHistoryManager` into typed repositories while preserving exact collection names, doc ID formulas, and field names.
3. **Phase 3 — Intro WebView & Hybrid Authentication Flow:**
   - Implement `IntroLampScreen` (`webview_flutter` + JS channel), `AuthGateScreen`, `LoginScreen`, `GoogleSignIn` → `SetAppPasswordScreen` / `AppPasswordScreen`, `ForgotPasswordScreen`, `AdminLoginScreen`, and `AboutUsScreen`.
4. **Phase 4 — Student Dashboard, Profile, Subjects & Teacher Quiz:**
   - Implement `UserHomeScreen`, `UserProfileScreen`, `SubjectSearchScreen`, `SubjectDetailScreen`, and `TeacherQuizScreen` (including 5-minute countdown, auto-submit, `attempts` / `totalAttempts` / `blocked` rules).
5. **Phase 5 — Study Groups, Requests & Real-Time Chat Room:**
   - Implement `MyGroupsScreen`, `RequestsScreen`, `GroupRoomScreen` (live messages, read receipts `seenBy`, long-press unsend, `catbox.moe` file upload, meeting link cards), `GroupInfoScreen`, and `SharedFilesScreen`.
6. **Phase 6 — Admin Panel & Analytics:**
   - Implement `AdminDashboardScreen`, `AdminUsersScreen` (All Users + Active/Blocked Teachers), `AdminSubjectsScreen`, `AdminQuizEditorScreen` (4 sets × 10 MCQs), and `AdminReportsScreen` (`WeeklyBarChartPainter`).
7. **Phase 7 — End-to-End Parity Verification Against Live Firebase (`peermatrix-6a1db`):**
   - Run the Feature Verification Checklist (Section 9) testing Kotlin ↔ Flutter interoperability (e.g., a group/message/quiz created in Kotlin opens identically in Flutter and vice versa).

---

## 8. Potential Migration Risks & Edge Cases Discovered

1. **CRITICAL — `users.updatedAt` Type Mismatch in `AdminReportsActivity`:**
   - `MainActivity.saveUserToFirestore` writes `updatedAt` using `FieldValue.serverTimestamp()` (stored as Firestore `Timestamp`), whereas `AdminReportsActivity.loadData` queries `users` with `.whereGreaterThanOrEqualTo("updatedAt", weekAgo)` where `weekAgo` is a `Long` (epoch milliseconds). In Firestore, comparing a `Timestamp` field against an integer returns 0 results! In Flutter, query using `Timestamp.fromDate(weekAgoDate)` (or handle legacy `Long` values client-side) while still writing `FieldValue.serverTimestamp()`.
2. **CRITICAL — Exact Document ID Formatting:**
   - `user_roles` and `quiz_attempts` use `"${email.replace(".", "_")}_${subject.replace(" ", "_")}"` (without lowercasing `email` or `subject`), whereas `subjects` uses `name.trim().replace(" ", "_").lowercase()`. Replicating the exact capitalization and replacement rules is mandatory so Flutter reads/updates existing Kotlin-created documents.
3. **CRITICAL — Google Sign-In OAuth SHA-1 & Web Client ID (`client_type: 3`):**
   - `MainActivity` passes `R.string.default_web_client_id` (`850714985586-f332vkjs0415ef9r6reoe7suade92jbn.apps.googleusercontent.com`) to Credential Manager. In Flutter (`google_sign_in`), ensure `serverClientId` uses that same Web Client ID and Android debug/release builds use the matching SHA-1 keystore registered in Firebase, or Google Sign-In will throw `ApiException: 10`.
4. **MEDIUM — `SharedFilesActivity` Null `fileUrl` Key Edge Case:**
   - Kotlin `saveMessage` writes `"fileUrl" to null` for plain text messages, and `SharedFilesActivity` filters `messages.filter { it.containsKey("fileUrl") }`. In Firestore, keys with `null` values still satisfy `containsKey("fileUrl")`! In Flutter, filter `fileUrl != null && fileUrl.isNotEmpty` so text-only messages don't appear as `"Unknown File"` cards.
5. **MEDIUM — Firestore `whereIn` Limit (`getIncomingJoinRequests`):**
   - `db.collection("group_join_requests").whereIn("groupId", groupIds)` will throw a Firestore exception if a user belongs to more than 30 groups (or 10 on older limits). In Flutter, chunk `groupIds` into batches of 10–30 and merge results.
6. **MEDIUM — Required Firestore Composite Indexes:**
   - Queries combining equality/range + `orderBy` (`notes`, `group_join_requests`, `teacher_group_requests`, `AdminReportsActivity` `user_roles`) require existing composite indexes in `peermatrix-6a1db`. Do not alter query structures carelessly without checking index availability.
7. **MEDIUM — `catbox.moe` Third-Party Upload Reliability & CORS/Web Support:**
   - Active file sharing uploads to `https://catbox.moe/user/api.php` without auth. If `catbox.moe` is unreachable or rate-limited, keep `FirebaseStorage` fallback ready and handle timeouts cleanly.
8. **MEDIUM — Android `minSdk 24` & WebView Touch Handling (`login.html`):**
   - Ensure `webview_flutter` disables overscroll/zoom and supports touch events properly on `pull-string` in `login.html`, and verify `Android.onIntroDone()` channel registration before `loadFlutterAsset`.
9. **LOW — Bengali UTF-8 Rendering & Quiz Validation:**
   - Seeded SSC 9–10 subjects (`গনিত ৯-১০`, `উচ্চতর গনিত ৯-১০`, `পদার্থবিজ্ঞান ৯-১০`, `অর্থনীতি ৯-১০`) rely on UTF-8 Bengali glyphs and exact string matching for quiz answers (`selectedOption == question.answer`). Preserve exact Unicode strings during porting.
10. **LOW — Admin Login Session Separation:**
    - Admin login does NOT sign into `FirebaseAuth`; it reads `admin_config/credentials` directly and signs out any student `FirebaseAuth` session. Ensure Firestore security rules and Flutter auth guards do not accidentally redirect an Admin screen back to `LoginScreen` when `FirebaseAuth.instance.currentUser == null`.

---

## 9. Feature Verification Checklist

- [ ] **Intro Splash:** `login.html` renders dark lamp, pull-string animation works on touch/drag, turns on light + happy face + `"Welcome to EduBond"`, invokes `onIntroDone()`, routes to login.
- [ ] **Session Routing:** Cold start with logged-in Firebase + local `current_user` skips intro & login and opens `UserHomeScreen`; logout clears both and returns to Login with `fromLogout` behavior.
- [ ] **Email/Password Login:** Valid credentials sign in, save `current_user`, merge `users/{uid}`, and navigate to `UserHomeScreen`.
- [ ] **Google Sign-In (New User):** Credential picker signs into Firebase → detects `passwordSet != true` → prompts Set App Password (min 6 chars, confirm match) → links `EmailAuthProvider` credential → saves `users/{uid}` → opens `UserHomeScreen`.
- [ ] **Google Sign-In (Returning User):** Detects `passwordSet == true` → prompts Enter App Password → verifies via `signInWithEmailAndPassword` → opens `UserHomeScreen`.
- [ ] **Forgot Password:** Sends reset email via `sendPasswordResetEmail` (accessible from Login & Profile Change Password).
- [ ] **Admin Login:** Validates against `admin_config/credentials` (with `"Bappy"`/`"Bappy81"` fallback), signs out any active user session, opens `AdminDashboardScreen`.
- [ ] **About Us:** Displays `developer_pic.png`, BAUST CSE details, and working `mailto:`, LinkedIn, and GitHub links.
- [ ] **User Dashboard & Profile:** Displays username & 2-letter initials badge; Profile view/edit updates `username` & `biodata`; Change Password re-authenticates and updates password.
- [ ] **Subject Search & Request:** Auto-seeds 16 subjects if `subjects` empty; live search filters subjects; collapsible toggle works; submitting a subject name writes `pending` doc to `subject_requests`.
- [ ] **Study Role & Groups:** `"I want to study this"` writes `"learner"` role to `user_roles`; user can create a group (`G<timestamp>`) and see/open joined groups or send join requests to unjoined groups.
- [ ] **Teach Role & Qualification Quiz:** Blocks already-qualified teachers or blocked users (`quiz_attempts.blocked == true`); shows 6 exam rules; runs 5:00 countdown (red < 1:00); enforces all-answered on manual submit; auto-submits on timeout; passes at `>= 7/10` granting `"teacher"` role; blocks after 2 consecutive failures.
- [ ] **Requests Center:** Approving join request marks `accepted` and adds requester to `groups.members`; rejecting marks `rejected`; accepting teaching request marks `accepted` and adds teacher to `groups.teachers`; sent requests show accurate status.
- [ ] **My Groups & Group Room:** Lists groups where user is in `members` or `teachers`; real-time chat updates; sender names resolved; URLs/emails auto-linked; `seenBy` updates and renders `✓` vs blue `✓✓`; long-press own message unsends; `📎` uploads to `catbox.moe` and opens files; `📹` detects Zoom/Meet/Jitsi/Live links and opens them.
- [ ] **Group Info & Shared Files:** Displays subject, creator, teachers, members; lists unjoined qualified teachers with `"Request"` invite; Shared Files lists group attachments and allows uploader unsend; `"Leave Group"` removes user from `members` & `teachers`.
- [ ] **Admin Users & Teachers:** Search users, assign teacher role (`score = 10`), remove user doc, view active teachers & remove role, view blocked teachers & unblock (`blocked = false, attempts = 0`).
- [ ] **Admin Subjects & Quizzes:** Add/delete global subjects; accept/edit/reject pending `subject_requests`; edit & save 4 sets × 10 MCQs to both local storage and `quizzes/{subject}`.
- [ ] **Admin Reports:** Shows total user count and 3 custom-drawn 7-day weekly bar charts (New Users, New Groups, New Teachers).
