# EduBond Study Groups, Chat & File Sharing Migration Report (Prompt 6)

**Scope:** Migration of Study Group creation/browsing, Join Requests, Teacher Invitations, My Groups, Real-Time WhatsApp-Inspired Chat, Read Receipts, Unsend, Catbox & Firebase Storage File Sharing, Meeting Link Sharing, Group Info, and Shared Files from Kotlin (`SubjectDetailActivity.kt`, `MyGroupsActivity.kt`, `RequestsActivity.kt`, `GroupRoomActivity.kt`, `GroupInfoActivity.kt`, `SharedFilesActivity.kt`, `FirebaseHistoryManager.kt`) to Flutter (`edubond_flutter`).

---

## 1. Migrated Features & Business Rules

### 1.1 Group Creation, Browsing & My Groups
- **Group Creation (`GroupRepository.createGroup`):** Creates documents in Firestore `groups` with ID format `G${timestamp}`, `name`, `subject`, `createdBy`, `members: [creatorEmail]`, `teachers: []`, and `timestamp`, and logs activity to `activity_logs`.
- **Group Browsing (`SubjectDetailScreen`):** Loads groups by `subject` and checks authorization via `GroupModel.containsUser(email)` across `members`, `teachers`, and `createdBy` (case-insensitive). Displays `Open Group` for authorized users, `Request Pending` for already-sent pending join requests, and `Request to Join` for external users.
- **My Groups (`GroupsModulePage`):** `GroupRepository.getGroupsForUser(email)` queries all groups where the user appears in `members`, `teachers`, OR `createdBy` and deduplicates by `group.id`. `GroupsModulePage` uses `WidgetsBindingObserver` and route return callbacks to refresh when returning to or resuming the screen.

### 1.2 Group Join Requests & Teacher Invitations
- **Join Requests (`group_join_requests`):**
  - `GroupRepository.requestToJoinGroup` checks for existing `pending` requests matching `(groupId, requester, status == 'pending')` to prevent duplicate requests before creating a new request document.
  - `RequestsModulePage` displays incoming join requests for groups the user belongs to/teaches/created, incoming teaching invitations, and `My Sent Requests` with status (`pending`, `accepted`, `rejected`).
  - Approving updates `status: 'accepted'` and adds `requester` via `FieldValue.arrayUnion` to `groups/{groupId}.members`.
- **Teacher Invitations (`teacher_group_requests`):**
  - `GroupInfoModulePage` loads qualified teachers for the group's subject (`user_roles` where `role == 'teacher'`), excludes teachers already in `group.teachers` (case-insensitive), and pre-populates already-pending invitations from `teacher_group_requests`.
  - `GroupRepository.requestTeacherToJoin` prevents duplicate pending invitations for `(groupId, teacher)`.
  - Accepting updates `status: 'accepted'` and adds `teacher` via `FieldValue.arrayUnion` to `groups/{groupId}.teachers`.

### 1.3 Real-Time Chat, Read Receipts & Unsend
- **Firestore Streams (`ChatRepository.watchGroupMessages`):** Streams `groups/{groupId}/messages` ordered by `timestamp`, preserving `groupId`, `senderEmail`, `message`, `fileUrl`, `fileType`, `fileName`, `timestamp`, and `seenBy`.
- **WhatsApp-Inspired UI (`ChatModulePage`):**
  - Header `#075E54`, wallpaper `#E5DDD5`, outgoing bubble `#DCF8C6`, incoming bubble `#FFFFFF`, seen double-check `#34B7F1`.
  - Resolves sender display names for incoming messages, formats timestamps (`hh:mm a`), linkifies URLs and email addresses (`RichText` + `url_launcher`), and auto-scrolls when new messages arrive (`_lastMessageCount`).
- **Read Receipts (`seenBy`):** Marks unread messages via `FieldValue.arrayUnion([email])` guarded by non-empty email, case-insensitive membership check, and `_markedReadIds` to prevent duplicate Firestore updates. Preserves single check (`✓`) when `seenBy.length <= 1` and blue double check (`✓✓`) when `seenBy.length > 1`.
- **Unsend Message:** Long-press on the current user's own messages displays a confirmation dialog and deletes the Firestore document from `groups/{groupId}/messages/{messageId}`. Long-pressing another user's message is disabled.

### 1.4 File Sharing, Meeting Links, Group Info & Shared Files
- **Catbox Primary Upload (`CatboxUploadDataSource` + `ChatRepository.uploadAndShareFile`):**
  - Picks files via `filePickProvider` (`FilePicker.pickFile()` accepting any file type `*/*`, mirroring Kotlin `ACTION_OPEN_DOCUMENT`), infers MIME type (`FileViewerHelper.guessMimeType`), and uploads multipart `POST` to `https://catbox.moe/user/api.php` with `reqtype=fileupload` and `fileToUpload`.
  - Reports real upload progress (`0.0 -> 1.0`) in `ChatModulePage` (`LinearProgressIndicator` + percentage banner) and throws/displays upload errors without silently switching to another storage provider.
- **Firebase Storage Helper (`FirebaseStorageDataSource` + `ChatRepository.uploadAndShareFileToFirebaseStorage`):**
  - Preserved as an explicit separate helper uploading to `groups/$groupId/shared_files/${timestamp}_$fileName` with progress streaming (`task.snapshotEvents`).
- **Provider Behavior Differences Documented:**
  - Kotlin `GroupRoomActivity` used `uploadFileFree` (Catbox) directly and kept `uploadFileToFirebase` as an unused/separate helper on `FirebaseHistoryManager`. Flutter preserves Catbox as the sole active destination for `uploadAndShareFile` and explicitly does **not** fall back silently to Firebase Storage on Catbox errors (Firebase Storage requires an explicit call to `uploadAndShareFileToFirebaseStorage`).
  - On Flutter, image attachments open in an in-app zoomable preview dialog (`CachedNetworkImage` + `"Open in Browser"` action) via `FileViewerHelper.openSharedFile`, while PDFs/documents open externally via `url_launcher` (`LaunchMode.externalApplication`) rather than Android `ContentResolver` URIs.
- **Meeting Link Sharing (`_MeetingLinkDialog` + `ChatRepository.shareMeetingLink`):**
  - Validates URLs inline inside a `StatefulWidget` dialog (preventing post-dispose controller assertions), detects `Zoom`, `Google Meet`, `Jitsi` (`jitsi` / `jit.si`), or `Live`, and posts a clickable meeting card showing `"Click to Join"` launched with `url_launcher`.
- **Group Information (`GroupInfoModulePage`):** Displays subject, creator, teachers, members, `Hire Qualified Teachers`, `View Shared Files`, and `Leave Group` (`GroupRepository.leaveGroup` removes user from `members` and `teachers`).
- **Shared Files (`SharedFilesModulePage`):** Streams messages containing `fileUrl`, displaying file name, human-readable file type (`FileViewerHelper.displayFileType`), uploader name, timestamp, open action, and owner-only long-press unsend.

---

## 2. Files Added / Modified in This Phase
- `lib/core/services/providers.dart` (added `PickedAttachment` & `filePickProvider`)
- `lib/core/utils/file_viewer_helper.dart` (added shared MIME detection, display labels, image preview dialog, external URL launcher)
- `lib/data/datasources/firestore_datasource.dart` (added `watchSubcollection`, `addSubcollectionDoc`, `arrayUnionSubcollectionField`, `deleteSubcollectionDoc`)
- `lib/data/datasources/catbox_upload_datasource.dart` (added streaming upload progress reporting)
- `lib/data/datasources/firebase_storage_datasource.dart` (added progress tracking via `snapshotEvents`)
- `lib/data/repositories/group_repository.dart` (added `createdBy` to `getGroupsForUser`, duplicate checks on `requestToJoinGroup` and `requestTeacherToJoin`, `getPendingInvitedTeachersForGroup`, case-insensitive `leaveGroup`)
- `lib/data/repositories/chat_repository.dart` (removed silent Firebase Storage fallback on Catbox failure, added explicit `uploadAndShareFileToFirebaseStorage`, updated `jit.si` detection, migrated queries to `FirestoreDataSource`)
- `lib/features/subjects/subject_detail_screen.dart` (handled duplicate join request feedback)
- `lib/features/groups/groups_module.dart` (added `WidgetsBindingObserver` resume refresh & `activeUserEmail`)
- `lib/features/requests/requests_module.dart` (switched to `activeUserEmail`)
- `lib/features/group_info/group_info_module.dart` (pre-loaded pending teacher invitations, case-insensitive teacher exclusion, `activeUserEmail`)
- `lib/features/chat/chat_module.dart` (real upload progress UI, `_MeetingLinkDialog` lifecycle safety, `FileViewerHelper`, smart auto-scroll, case-insensitive `seenBy` read-receipt guard)
- `lib/features/shared_files/shared_files_module.dart` (displayed `fileType`, used `FileViewerHelper.openSharedFile` & `activeUserEmail`)
- `test/academic_features_test.dart` (updated `FakeFirestoreDataSource` compatibility)
- `test/group_chat_test.dart` (added comprehensive unit & widget integration tests)

---

## 3. Verification Results

Executed in `edubond_flutter` using Flutter 3.50.1 / Dart 3.14.0:
- `flutter analyze`: **No issues found!**
- `flutter test`: **All 29 tests passed** (`test/widget_test.dart`, `test/academic_features_test.dart`, `test/group_chat_test.dart`).

### Verified Group & Chat Workflows (`test/group_chat_test.dart`)
- Group creation with `G{timestamp}` IDs and `getGroupsForUser` lookup across `members`, `teachers`, and `createdBy`.
- Duplicate prevention on `group_join_requests` and `teacher_group_requests`, plus approval/acceptance updating `groups` arrays and `leaveGroup` removal.
- Catbox multipart upload (`reqtype=fileupload`, `https://catbox.moe/user/api.php`) with progress reporting, error propagation without silent Firebase Storage fallback, and explicit `uploadAndShareFileToFirebaseStorage` helper execution.
- Meeting platform detection (`Zoom`, `Google Meet`, `Jitsi`, `Live`) and meeting link dialog sharing with clickable `"Click to Join"` card.
- Multi-account real-time chat stream (`alice@baust.edu.bd` & `bob@baust.edu.bd`): sender name display, read receipts (`seenBy`) transitioning single `✓` to blue double `✓✓` (`#34B7F1`) without repeated updates, and sender-only long-press unsend.
- File picker upload flow rendering in `ChatModulePage` and `SharedFilesModulePage` (`PDF Document`, uploader, timestamp, owner-only unsend).
- `GroupInfoModulePage` excluding existing group teachers, inviting qualified teachers, accepting in `RequestsModulePage`, and appearing in `GroupsModulePage`.

> **Note:** Automated tests exercised real Dart repositories, Catbox multipart HTTP serialization (via `MockClient`), `StreamController`-backed real-time subcollection streams, and Riverpod widget trees. Live Firebase Console/emulator device testing across physical/emulator Android devices is recommended for final QA against the live `peermatrix-6a1db` backend.
