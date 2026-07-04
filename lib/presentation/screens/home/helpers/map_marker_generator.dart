import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class MapMarkerGenerator {
  /// Tải hình ảnh logo một lần
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

  /// Tạo hình ảnh marker hình tròn cho người dùng
  static Future<Uint8List> createUserMarkerImage() async {
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Hiệu ứng vòng tròn lan tỏa
    final pulsePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, pulsePaint);

    // Viền tối ngoài cùng
    final borderPaint = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 38, borderPaint);

    // Vòng tròn trắng bên trong
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 32, whitePaint);

    // Vẽ chữ "U" đại diện cho User
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

  /// Tạo hình ảnh marker cho trạm sạc với viền màu theo trạng thái.
  ///
  /// [borderColor] quyết định màu viền ngoài cùng:
  /// - Xanh lá (Trống) → Color(0xFF4CAF50)
  /// - Vàng (Vừa phải) → Color(0xFFFFC107)
  /// - Đỏ (Kẹt/Đầy/Bảo trì) → Color(0xFFF44336)
  /// - Trắng (mặc định) → Colors.white
  static Future<Uint8List> createStationMarkerImage({
    required bool isAvailable,
    required ui.Image? logoImage,
    Color borderColor = Colors.white,
  }) async {
    const double width = 160;
    const double height = 180;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Tạo hình dạng ghim (hình tròn + tam giác phía dưới)
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

    // 2. Vẽ bóng dưới chân ghim
    canvas.drawPath(
      unifiedPath.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3. Vẽ nền (Xanh Navy nếu hoạt động, Xám nếu dừng hoạt động)
    final bgPaint = Paint()
      ..color = isAvailable ? AppColors.navy : AppColors.lightGray
      ..style = PaintingStyle.fill;
    canvas.drawPath(unifiedPath, bgPaint);

    // 4. Vẽ viền màu (thay đổi theo trạng thái check-in)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(unifiedPath, borderPaint);

    // 5. Vẽ logo trạm sạc vào giữa ghim dưới dạng hình tròn
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

      // Vẽ viền trắng mỏng bao quanh logo
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

  /// Lấy màu viền marker tương ứng với trạng thái check-in.
  static Color getStatusBorderColor(String? crowdStatus) {
    switch (crowdStatus) {
      case 'EMPTY':
        return const Color(0xFF4CAF50); // Xanh lá
      case 'MODERATE':
        return const Color(0xFFFFC107); // Vàng
      case 'BUSY':
      case 'MAINTENANCE':
        return const Color(0xFFF44336); // Đỏ
      default:
        return const Color(0xFF4CAF50); // Mặc định: Xanh lá
    }
  }
}
