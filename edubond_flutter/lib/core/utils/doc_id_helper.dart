/// Generates Firestore document IDs using the exact formulas from Kotlin.
abstract final class DocIdHelper {
  /// Matches: name.trim().replace(" ", "_").lowercase()
  static String subjectDocId(String subjectName) {
    return subjectName.trim().replaceAll(' ', '_').toLowerCase();
  }

  /// Matches: "${email.replace(".", "_")}_${subject.replace(" ", "_")}"
  /// Intentionally preserves case to match existing Kotlin Firestore documents.
  static String emailSubjectDocId(String email, String subject) {
    final safeEmail = email.replaceAll('.', '_');
    final safeSubject = subject.replaceAll(' ', '_');
    return '${safeEmail}_$safeSubject';
  }

  /// Matches: "G${System.currentTimeMillis()}"
  static String newGroupId([int? timestampMs]) {
    return 'G${timestampMs ?? DateTime.now().millisecondsSinceEpoch}';
  }

  /// Matches: System.currentTimeMillis().toString()
  static String newTimestampId([int? timestampMs]) {
    return '${timestampMs ?? DateTime.now().millisecondsSinceEpoch}';
  }
}
