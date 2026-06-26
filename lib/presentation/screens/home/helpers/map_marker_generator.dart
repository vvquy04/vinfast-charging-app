import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class MapMarkerGenerator {
  /// Load logo image asset once
  static Future<ui.Image?> loadLogoImage(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Error loading logo asset: $e');
      return null;
    }
  }

  /// Create a colored circle icon for user marker
  static Future<Uint8List> createUserMarkerImage() async {
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Pulse ring
    final pulsePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, pulsePaint);

    // Outer dark border
    final borderPaint = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 38, borderPaint);

    // Inner white circle
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 32, whitePaint);

    // Letter "U"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'U',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Create station marker icon
  static Future<Uint8List> createStationMarkerImage({
    required bool isAvailable,
    required ui.Image? logoImage,
  }) async {
    const double width = 160;
    const double height = 180;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Create teardrop pin shape (circle + triangle bottom)
    final pinPath = Path();
    pinPath.addOval(
      Rect.fromCircle(center: const Offset(width / 2, 65), radius: 50),
    );

    final trianglePath = Path();
    trianglePath.moveTo(width / 2 - 38, 97);
    trianglePath.lineTo(width / 2, height - 12);
    trianglePath.lineTo(width / 2 + 38, 97);
    trianglePath.close();

    final unifiedPath = Path.combine(
      PathOperation.union,
      pinPath,
      trianglePath,
    );

    // 2. Draw Shadow under the pin
    canvas.drawPath(
      unifiedPath.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3. Draw Background fill (Navy for Available, LightGray for Unavailable)
    final bgPaint = Paint()
      ..color = isAvailable ? AppColors.navy : AppColors.lightGray
      ..style = PaintingStyle.fill;
    canvas.drawPath(unifiedPath, bgPaint);

    // 4. Draw White border outline
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(unifiedPath, borderPaint);

    // 5. Draw the preloaded Logo image inside a circular clip, centered in the pin
    if (logoImage != null) {
      canvas.save();

      final logoClip = Path();
      logoClip.addOval(
        Rect.fromCircle(center: const Offset(width / 2, 65), radius: 38),
      );
      canvas.clipPath(logoClip);

      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(
          0,
          0,
          logoImage.width.toDouble(),
          logoImage.height.toDouble(),
        ),
        Rect.fromCircle(center: const Offset(width / 2, 65), radius: 38),
        Paint(),
      );

      canvas.restore();

      // Draw thin white border around the logo circular mask
      canvas.drawCircle(
        const Offset(width / 2, 65),
        38,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
