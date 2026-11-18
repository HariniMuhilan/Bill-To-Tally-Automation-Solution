import 'package:flutter/material.dart';

/// Unified clean 24x24 SVG-path vector icon types for footer navigation and modal headers.
enum AppVectorIconType {
  inbox,
  review,
  camera,
  tallySync,
  account,
  lockShield,
  mail,
  close,
}

/// Crisp, dependency-free vector icon rendered via GPU [CustomPaint] paths.
class AppVectorIcon extends StatelessWidget {
  final AppVectorIconType type;
  final double size;
  final Color color;
  final double strokeWidth;

  const AppVectorIcon({
    super.key,
    required this.type,
    this.size = 20,
    required this.color,
    this.strokeWidth = 1.9,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _AppVectorIconPainter(
            type: type,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _AppVectorIconPainter extends CustomPainter {
  final AppVectorIconType type;
  final Color color;
  final double strokeWidth;

  const _AppVectorIconPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;
    canvas.save();
    canvas.scale(sx, sy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case AppVectorIconType.inbox:
        _paintInbox(canvas, paint);
        break;
      case AppVectorIconType.review:
        _paintReview(canvas, paint);
        break;
      case AppVectorIconType.camera:
        _paintCamera(canvas, paint);
        break;
      case AppVectorIconType.tallySync:
        _paintTallySync(canvas, paint);
        break;
      case AppVectorIconType.account:
        _paintAccount(canvas, paint);
        break;
      case AppVectorIconType.lockShield:
        _paintLockShield(canvas, paint);
        break;
      case AppVectorIconType.mail:
        _paintMail(canvas, paint);
        break;
      case AppVectorIconType.close:
        _paintClose(canvas, paint);
        break;
    }

    canvas.restore();
  }

  void _paintInbox(Canvas canvas, Paint paint) {
    // Outer rounded tray
    final tray = Path()
      ..moveTo(4, 13)
      ..lineTo(8.5, 13)
      ..lineTo(10, 15.5)
      ..lineTo(14, 15.5)
      ..lineTo(15.5, 13)
      ..lineTo(20, 13);
    canvas.drawPath(tray, paint);

    final box = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 4.5, 17, 15),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(box, paint);
  }

  void _paintReview(Canvas canvas, Paint paint) {
    final box = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 3.5, 17, 17),
      const Radius.circular(4),
    );
    canvas.drawRRect(box, paint);

    final check = Path()
      ..moveTo(8.5, 12.3)
      ..lineTo(11, 14.8)
      ..lineTo(16, 9.5);
    canvas.drawPath(check, paint);
  }

  void _paintCamera(Canvas canvas, Paint paint) {
    final body = Path()
      ..moveTo(4, 8.5)
      ..quadraticBezierTo(4, 7, 5.5, 7)
      ..lineTo(8, 7)
      ..lineTo(9.4, 4.8)
      ..lineTo(14.6, 4.8)
      ..lineTo(16, 7)
      ..lineTo(18.5, 7)
      ..quadraticBezierTo(20, 7, 20, 8.5)
      ..lineTo(20, 17.5)
      ..quadraticBezierTo(20, 19, 18.5, 19)
      ..lineTo(5.5, 19)
      ..quadraticBezierTo(4, 19, 4, 17.5)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawCircle(const Offset(12, 13), 3.3, paint);
  }

  void _paintTallySync(Canvas canvas, Paint paint) {
    // Upper clockwise arc
    final topArc = Path()
      ..moveTo(20, 10.5)
      ..arcToPoint(
        const Offset(5.2, 8.8),
        radius: const Radius.circular(7.8),
        clockwise: false,
      );
    canvas.drawPath(topArc, paint);

    // Upper arrowhead
    final topHead = Path()
      ..moveTo(16.8, 10.7)
      ..lineTo(20.2, 10.7)
      ..lineTo(20.2, 7.3);
    canvas.drawPath(topHead, paint);

    // Lower arc
    final botArc = Path()
      ..moveTo(4, 13.5)
      ..arcToPoint(
        const Offset(18.8, 15.2),
        radius: const Radius.circular(7.8),
        clockwise: false,
      );
    canvas.drawPath(botArc, paint);

    // Lower arrowhead
    final botHead = Path()
      ..moveTo(7.2, 13.3)
      ..lineTo(3.8, 13.3)
      ..lineTo(3.8, 16.7);
    canvas.drawPath(botHead, paint);
  }

  void _paintAccount(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 8.2), 3.6, paint);
    final shoulders = Path()
      ..moveTo(5.2, 19.5)
      ..quadraticBezierTo(5.8, 14.8, 12, 14.8)
      ..quadraticBezierTo(18.2, 14.8, 18.8, 19.5);
    canvas.drawPath(shoulders, paint);
  }

  void _paintLockShield(Canvas canvas, Paint paint) {
    final lockBody = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5, 11, 14, 9.5),
      const Radius.circular(3),
    );
    canvas.drawRRect(lockBody, paint);

    final shackle = Path()
      ..moveTo(8, 11)
      ..lineTo(8, 8)
      ..arcToPoint(
        const Offset(16, 8),
        radius: const Radius.circular(4),
      )
      ..lineTo(16, 11);
    canvas.drawPath(shackle, paint);
    canvas.drawCircle(const Offset(12, 15.6), 1.1, paint);
  }

  void _paintMail(Canvas canvas, Paint paint) {
    final env = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 5.5, 17, 13),
      const Radius.circular(2.8),
    );
    canvas.drawRRect(env, paint);

    final flap = Path()
      ..moveTo(4.2, 7.2)
      ..lineTo(12, 13)
      ..lineTo(19.8, 7.2);
    canvas.drawPath(flap, paint);
  }

  void _paintClose(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(6.5, 6.5), const Offset(17.5, 17.5), paint);
    canvas.drawLine(const Offset(17.5, 6.5), const Offset(6.5, 17.5), paint);
  }

  @override
  bool shouldRepaint(covariant _AppVectorIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
