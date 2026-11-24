import 'package:material_ui/material_ui.dart';
import '../constants/app_colors.dart';

/// Custom Canvas painters ported from Kotlin `AuthViews.kt` and Activity icons.
class EyeTogglePainter extends CustomPainter {
  const EyeTogglePainter({required this.isClosed});

  final bool isClosed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerY = h / 2;
    const pad = 4.0;

    final stroke = Paint()
      ..color = AppColors.textBody
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final eyeRect = Rect.fromLTRB(pad, centerY - 7, w - pad, centerY + 7);
    canvas.drawOval(eyeRect, stroke);

    final pupil = Paint()
      ..color = AppColors.textBody
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, centerY), 3.2, pupil);

    if (isClosed) {
      canvas.drawLine(
        Offset(pad + 2, centerY + 9),
        Offset(w - pad - 2, centerY - 9),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EyeTogglePainter oldDelegate) =>
      oldDelegate.isClosed != isClosed;
}

class LockBadgePainter extends CustomPainter {
  const LockBadgePainter({
    required this.shackleColor,
    required this.bodyColor,
    required this.keyholeColor,
    this.outlineOnly = false,
  });

  final Color shackleColor;
  final Color bodyColor;
  final Color keyholeColor;
  final bool outlineOnly;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final shacklePaint = Paint()
      ..color = shackleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineOnly ? 2.4 : 4.0
      ..strokeCap = StrokeCap.round;

    final shackleRect = Rect.fromLTRB(
      cx - size.width * 0.22,
      cy - size.height * 0.34,
      cx + size.width * 0.22,
      cy + size.height * 0.14,
    );
    canvas.drawArc(shackleRect, 3.49, 2.44, false, shacklePaint);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx - size.width * 0.30,
        cy - size.height * 0.06,
        cx + size.width * 0.30,
        cy + size.height * 0.34,
      ),
      const Radius.circular(5),
    );

    if (outlineOnly) {
      canvas.drawRRect(bodyRect, shacklePaint);
      return;
    }

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRect, bodyPaint);

    final keyPaint = Paint()
      ..color = keyholeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + size.height * 0.11), 3.4, keyPaint);

    final linePaint = Paint()
      ..color = keyholeColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy + size.height * 0.13),
      Offset(cx, cy + size.height * 0.23),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant LockBadgePainter oldDelegate) =>
      oldDelegate.shackleColor != shackleColor ||
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.outlineOnly != outlineOnly;
}

class AdminShieldPainter extends CustomPainter {
  const AdminShieldPainter({this.color = AppColors.adminPurple});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final shieldPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shield = Path()
      ..moveTo(cx, h * 0.18)
      ..lineTo(w * 0.78, h * 0.30)
      ..lineTo(w * 0.78, h * 0.56)
      ..quadraticBezierTo(w * 0.78, h * 0.76, cx, h * 0.88)
      ..quadraticBezierTo(w * 0.22, h * 0.76, w * 0.22, h * 0.56)
      ..lineTo(w * 0.22, h * 0.30)
      ..close();
    canvas.drawPath(shield, shieldPaint);

    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final check = Path()
      ..moveTo(w * 0.38, h * 0.54)
      ..lineTo(w * 0.47, h * 0.64)
      ..lineTo(w * 0.65, h * 0.42);
    canvas.drawPath(check, checkPaint);
  }

  @override
  bool shouldRepaint(covariant AdminShieldPainter oldDelegate) =>
      oldDelegate.color != color;
}

class UserOutlinePainter extends CustomPainter {
  const UserOutlinePainter({required this.color, this.strokeWidth = 2.5});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.19, paint);
    canvas.drawArc(
      Rect.fromLTRB(w * 0.2, h * 0.63, w * 0.8, h * 0.95),
      3.14159,
      3.14159,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant UserOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class SearchIconPainter extends CustomPainter {
  const SearchIconPainter({this.color = AppColors.primaryBlue});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.44, h * 0.44), w * 0.25, paint);
    canvas.drawLine(
      Offset(w * 0.64, h * 0.64),
      Offset(w * 0.85, h * 0.85),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SearchIconPainter oldDelegate) => false;
}

class UsersIconPainter extends CustomPainter {
  const UsersIconPainter({this.color = AppColors.primaryPurple});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.18, paint);
    canvas.drawArc(
      Rect.fromLTRB(w * 0.2, h * 0.6, w * 0.8, h * 0.95),
      3.14159,
      3.14159,
      false,
      paint,
    );
    canvas.drawCircle(Offset(w * 0.25, h * 0.45), w * 0.12, paint);
  }

  @override
  bool shouldRepaint(covariant UsersIconPainter oldDelegate) => false;
}

class ChatIconPainter extends CustomPainter {
  const ChatIconPainter({this.color = AppColors.emerald});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.15, h * 0.2, w * 0.85, h * 0.75),
        const Radius.circular(4),
      ),
      paint,
    );
    final tail = Path()
      ..moveTo(w * 0.3, h * 0.75)
      ..lineTo(w * 0.3, h * 0.9)
      ..lineTo(w * 0.5, h * 0.75);
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant ChatIconPainter oldDelegate) => false;
}

class LogoutIconPainter extends CustomPainter {
  const LogoutIconPainter({this.color = AppColors.textSlate});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final frame = Path()
      ..moveTo(w * 0.5, h * 0.2)
      ..lineTo(w * 0.2, h * 0.2)
      ..lineTo(w * 0.2, h * 0.8)
      ..lineTo(w * 0.5, h * 0.8);
    canvas.drawPath(frame, paint);
    canvas.drawLine(Offset(w * 0.4, h * 0.5), Offset(w * 0.85, h * 0.5), paint);

    final arrow = Path()
      ..moveTo(w * 0.7, h * 0.35)
      ..lineTo(w * 0.85, h * 0.5)
      ..lineTo(w * 0.7, h * 0.65);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant LogoutIconPainter oldDelegate) => false;
}

class StudyOptionIconPainter extends CustomPainter {
  const StudyOptionIconPainter({this.color = AppColors.primaryBlue});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.2, h * 0.22, w * 0.8, h * 0.82),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawLine(Offset(w * 0.35, h * 0.43), Offset(w * 0.65, h * 0.43), paint);
    canvas.drawLine(Offset(w * 0.35, h * 0.60), Offset(w * 0.65, h * 0.60), paint);
  }

  @override
  bool shouldRepaint(covariant StudyOptionIconPainter oldDelegate) => false;
}

class ReportIconPainter extends CustomPainter {
  const ReportIconPainter({this.color = AppColors.emeraldBright});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final page = Path()
      ..moveTo(w * 0.2, h * 0.12)
      ..lineTo(w * 0.6, h * 0.12)
      ..lineTo(w * 0.8, h * 0.32)
      ..lineTo(w * 0.8, h * 0.88)
      ..lineTo(w * 0.2, h * 0.88)
      ..close();
    canvas.drawPath(page, paint);
    canvas.drawLine(Offset(w * 0.35, h * 0.46), Offset(w * 0.65, h * 0.46), paint);
    canvas.drawLine(Offset(w * 0.35, h * 0.60), Offset(w * 0.65, h * 0.60), paint);
    canvas.drawLine(Offset(w * 0.35, h * 0.74), Offset(w * 0.55, h * 0.74), paint);
  }

  @override
  bool shouldRepaint(covariant ReportIconPainter oldDelegate) => false;
}

class SendIconPainter extends CustomPainter {
  const SendIconPainter({this.color = Colors.white});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.1)
      ..lineTo(size.width * 0.9, size.height * 0.5)
      ..lineTo(size.width * 0.1, size.height * 0.9)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SendIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
