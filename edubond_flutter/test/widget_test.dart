import 'package:flutter_test/flutter_test.dart';
import 'package:edubond_flutter/core/constants/app_constants.dart';
import 'package:edubond_flutter/core/constants/quiz_seed_data.dart';
import 'package:edubond_flutter/core/utils/date_formatter.dart';
import 'package:edubond_flutter/core/utils/doc_id_helper.dart';
import 'package:edubond_flutter/core/utils/validators.dart';
import 'package:edubond_flutter/models/group_model.dart';
import 'package:edubond_flutter/models/message_model.dart';
import 'package:edubond_flutter/models/quiz_question_model.dart';
import 'package:edubond_flutter/models/user_model.dart';

void main() {
  group('DocIdHelper', () {
    test('subjectDocId matches Kotlin formula', () {
      expect(
        DocIdHelper.subjectDocId(' Software Engineering '),
        'software_engineering',
      );
      expect(DocIdHelper.subjectDocId('গনিত ৯-১০'), 'গনিত_৯-১০');
    });

    test('emailSubjectDocId matches Kotlin formula without lowercasing', () {
      expect(
        DocIdHelper.emailSubjectDocId('User.Name@gmail.com', 'Data Structure'),
        'User_Name@gmail_com_Data_Structure',
      );
    });
  });

  group('QuizSeedData & QuizQuestionModel', () {
    test('all 9 seeded subjects have valid 10-question sets', () {
      for (final subject in AppConstants.seededQuizSubjects) {
        final sets = QuizSeedData.getDefaultSetsForSubject(subject);
        expect(sets, isNotNull, reason: 'Missing seed for $subject');
        expect(sets!.length, greaterThanOrEqualTo(2));
        for (final set in sets) {
          expect(set.length, 10, reason: 'Set length mismatch for $subject');
          for (final q in set) {
            expect(q.options.length, 4);
            expect(q.question.isNotEmpty, isTrue);
            expect(q.answer.isNotEmpty, isTrue);
          }
        }
      }
    });

    test('QuizQuestionModel encodes and decodes sets accurately', () {
      final sets = QuizSeedData.getDefaultSetsForSubject('Software Engineering')!;
      final encoded = QuizQuestionModel.encodeQuizSets(sets);
      final decoded = QuizQuestionModel.decodeQuizSets(encoded);
      expect(decoded.length, sets.length);
      expect(decoded.first.first.question, sets.first.first.question);
      expect(decoded.first.first.answer, sets.first.first.answer);
    });
  });

  group('Models & Validators', () {
    test('GroupModel containsUser checks members, teachers, and creator case-insensitively', () {
      const group = GroupModel(
        id: 'G123',
        name: 'CSE Study',
        subject: 'Compiler',
        createdBy: 'Creator@gmail.com',
        members: ['Member@gmail.com'],
        teachers: ['Teacher@gmail.com'],
        timestamp: 1000,
      );
      expect(group.containsUser('creator@gmail.com'), isTrue);
      expect(group.containsUser('MEMBER@gmail.com'), isTrue);
      expect(group.containsUser('teacher@gmail.com'), isTrue);
      expect(group.containsUser('stranger@gmail.com'), isFalse);
    });

    test('MessageModel attachment detection handles null and empty fileUrl', () {
      const plain = MessageModel(
        id: 'm1',
        groupId: 'G1',
        senderEmail: 'a@b.com',
        message: 'Hello',
        fileUrl: null,
        timestamp: 100,
        seenBy: ['a@b.com'],
      );
      const attachment = MessageModel(
        id: 'm2',
        groupId: 'G1',
        senderEmail: 'a@b.com',
        message: 'File',
        fileUrl: 'https://files.catbox.moe/abc.pdf',
        fileType: 'application/pdf',
        fileName: 'abc.pdf',
        timestamp: 200,
        seenBy: ['a@b.com'],
      );
      expect(plain.hasAttachment, isFalse);
      expect(attachment.hasAttachment, isTrue);
    });

    test('UserModel roundtrip preserves schema keys', () {
      const user = UserModel(
        uid: 'u1',
        username: 'Bappy',
        email: 'bappy@gmail.com',
        googleVerified: true,
        passwordSet: true,
        biodata: 'CSE Student',
      );
      final parsed = UserModel.fromMap(user.toMap());
      expect(parsed.uid, 'u1');
      expect(parsed.username, 'Bappy');
      expect(parsed.passwordSet, isTrue);
      expect(parsed.biodata, 'CSE Student');
    });

    test('Validators & DateFormatter', () {
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email('user@gmail.com'), isNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
      expect(DateFormatter.formatCountdown(300), '05:00');
      expect(DateFormatter.formatCountdown(59), '00:59');
    });
  });
}
