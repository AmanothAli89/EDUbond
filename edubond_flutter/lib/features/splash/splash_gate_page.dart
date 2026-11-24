import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/providers.dart';

/// Recreates `AnimatedLoginActivity.kt` + `assets/html/login.html` natively
/// with CustomPainter and AnimationController, plus session auto-routing.
class SplashGatePage extends ConsumerStatefulWidget {
  const SplashGatePage({super.key, this.skipSessionCheck = false});

  final bool skipSessionCheck;

  @override
  ConsumerState<SplashGatePage> createState() => _SplashGatePageState();
}

class _SplashGatePageState extends ConsumerState<SplashGatePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pullController;
  late final Animation<double> _pullAnimation;
  bool _checkingSession = true;
  bool _lightOn = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pullAnimation = CurvedAnimation(
      parent: _pullController,
      curve: Curves.easeOut,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Seed default quizzes in background without blocking intro
    unawaited(
      ref
          .read(quizRepositoryProvider)
          .seedDefaultQuizzesToCloud()
          .catchError((_) {}),
    );

    if (!widget.skipSessionCheck) {
      final loggedIn = await ref.read(authRepositoryProvider).hasValidSession();
      if (loggedIn && mounted) {
        _navigated = true;
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        return;
      }
    }

    if (mounted) {
      setState(() => _checkingSession = false);
    }
  }

  Future<void> _triggerLampPull() async {
    if (_lightOn || _navigated) return;
    await _pullController.forward();
    if (!mounted) return;
    setState(() => _lightOn = true);
    await _pullController.reverse();

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
  }

  @override
  void dispose() {
    _pullController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: AppColors.introDarkBg,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFACC15)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.introDarkBg,
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _triggerLampPull,
            onVerticalDragEnd: (_) => _triggerLampPull(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pullAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(260, 340),
                      painter: _StudyLampPainter(
                        lightOn: _lightOn,
                        pullOffset: _pullAnimation.value * 30,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                AnimatedScale(
                  scale: _lightOn ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    style: TextStyle(
                      color: _lightOn
                          ? const Color(0xFFFACC15)
                          : AppColors.textMuted,
                      fontSize: 19,
                      fontWeight:
                          _lightOn ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 1.2,
                      shadows: _lightOn
                          ? const [
                              Shadow(
                                color: Color(0x80FACC15),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _lightOn
                          ? 'WELCOME TO EDUBOND'
                          : 'PULL DOWN TO LIGHT UP',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyLampPainter extends CustomPainter {
  const _StudyLampPainter({
    required this.lightOn,
    required this.pullOffset,
  });

  final bool lightOn;
  final double pullOffset;

  @override
  void paint(Canvas canvas, Size size) {
    // Map SVG 200x320 coordinate space cleanly to widget size.
    final sx = size.width / 200.0;
    final sy = size.height / 320.0;
    canvas.save();
    canvas.scale(sx, sy);

    // 1. Light Beam when ON
    if (lightOn) {
      final beamPath = Path()
        ..moveTo(55, 150)
        ..lineTo(145, 150)
        ..lineTo(200, 320)
        ..lineTo(0, 320)
        ..close();
      final beamPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x99FFFEF0),
            Color(0x00FFFEF0),
          ],
        ).createShader(const Rect.fromLTRB(0, 150, 200, 320));
      canvas.drawPath(beamPath, beamPaint);
    }

    // 2. Base shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 295), width: 100, height: 20),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x4D000000), Color(0x00000000)],
        ).createShader(
          Rect.fromCenter(center: const Offset(100, 295), width: 100, height: 20),
        ),
    );

    // 3. Lamp base & stem
    final basePaint = Paint()
      ..color = lightOn ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final baseTopPaint = Paint()
      ..color = lightOn ? const Color(0xFFF8FAFC) : const Color(0xFF475569);
    final stemPaint = Paint()
      ..color = lightOn ? const Color(0xFFF8FAFC) : const Color(0xFF334155);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 290), width: 90, height: 24),
      basePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 285), width: 90, height: 24),
      baseTopPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(94, 150, 12, 135),
        const Radius.circular(2),
      ),
      stemPaint,
    );

    // 4. Pull string & triangular knob
    final stringColor =
        lightOn ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8);
    final knobColor =
        lightOn ? const Color(0xFFF8FAFC) : const Color(0xFFCBD5E1);

    final stringPath = Path()
      ..moveTo(82, 150)
      ..quadraticBezierTo(85, 180 + pullOffset * 0.5, 82, 210 + pullOffset);
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = stringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final knobY = 210 + pullOffset;
    final knobPath = Path()
      ..moveTo(78, knobY)
      ..lineTo(86, knobY)
      ..lineTo(82, knobY + 12)
      ..close();
    canvas.drawPath(knobPath, Paint()..color = knobColor);

    // 5. Lamp shade
    final shadePath = Path()
      ..moveTo(70, 40)
      ..lineTo(130, 40)
      ..lineTo(145, 150)
      ..lineTo(55, 150)
      ..close();
    canvas.drawPath(
      shadePath,
      Paint()
        ..color = lightOn ? const Color(0xFFA3AD8A) : const Color(0xFF1E293B),
    );

    final shadeBottom = Path()
      ..moveTo(55, 150)
      ..quadraticBezierTo(100, 165, 145, 150)
      ..quadraticBezierTo(100, 142, 55, 150);
    canvas.drawPath(
      shadeBottom,
      Paint()
        ..color = lightOn ? const Color(0xFFFFFEF0) : const Color(0xFF0F172A),
    );

    // 6. Face on shade
    if (!lightOn) {
      final closedEye = Paint()
        ..color = const Color(0x99000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(80, 90)
          ..quadraticBezierTo(85, 96, 90, 90),
        closedEye,
      );
      canvas.drawPath(
        Path()
          ..moveTo(110, 90)
          ..quadraticBezierTo(115, 96, 120, 90),
        closedEye,
      );
    } else {
      final happyEye = Paint()
        ..color = const Color(0xE6000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(80, 92)
          ..quadraticBezierTo(85, 86, 90, 92),
        happyEye,
      );
      canvas.drawPath(
        Path()
          ..moveTo(110, 92)
          ..quadraticBezierTo(115, 86, 120, 92),
        happyEye,
      );

      final mouthPath = Path()
        ..moveTo(92, 105)
        ..quadraticBezierTo(100, 125, 108, 105)
        ..close();
      canvas.drawPath(mouthPath, Paint()..color = const Color(0xE6000000));

      final tonguePath = Path()
        ..moveTo(100, 115)
        ..quadraticBezierTo(104, 122, 108, 115)
        ..quadraticBezierTo(104, 112, 100, 115);
      canvas.drawPath(tonguePath, Paint()..color = const Color(0xFFFF7B7B));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StudyLampPainter oldDelegate) =>
      oldDelegate.lightOn != lightOn || oldDelegate.pullOffset != pullOffset;
}
