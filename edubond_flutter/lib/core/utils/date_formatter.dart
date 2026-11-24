import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _weekdayFormat = DateFormat('EEE');

  static String formatMessageTime(int timestampMs) {
    return _timeFormat.format(DateTime.fromMillisecondsSinceEpoch(timestampMs));
  }

  static String formatWeekday(DateTime date) {
    return _weekdayFormat.format(date);
  }

  static String formatCountdown(int remainingSeconds) {
    final clamped = remainingSeconds < 0 ? 0 : remainingSeconds;
    final minutes = (clamped ~/ 60).toString().padLeft(2, '0');
    final seconds = (clamped % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Safely parses Firestore Timestamp or epoch milliseconds (`int` / `num`).
  static DateTime? parseFirestoreDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    return null;
  }

  /// Returns ordered weekday labels for the last 7 days (oldest -> today).
  static List<String> lastSevenDayLabels([DateTime? now]) {
    final anchor = now ?? DateTime.now();
    final labels = <String>[];
    for (var i = 6; i >= 0; i--) {
      labels.add(formatWeekday(anchor.subtract(Duration(days: i))));
    }
    return labels;
  }
}
