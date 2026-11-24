import 'package:material_ui/material_ui.dart';
import '../constants/app_colors.dart';

/// Custom Canvas painters ported from Kotlin `AuthViews.kt` and Activity icons.
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
      ..strokeWidth = 3.5
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
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final check = Path()
      ..moveTo(w * 0.38, h * 0.54)
      ..lineTo(w * 0.47, h * 0.64)
      ..lineTo(w * 0.65, h * 0.42);
    canvas.drawPath(check, checkPaint);
  }

  @override
  bool shouldRepaint(covariant AdminShieldPainter oldDelegate) {
    return oldDelegate.color != color;
  }
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
  bool shouldRepaint(covariant SendIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
