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

  /// Tạo hình ảnh marker hình tròn cho người dùng (Chấm xanh kiểu Google Maps)
  static Future<Uint8List> createUserMarkerImage() async {
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Vòng tròn xanh mờ lan tỏa phía ngoài cùng (pulsing halo)
    final pulsePaint = Paint()
      ..color = const Color(0x332196F3) // Màu xanh dương nhạt với opacity thấp
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 48, pulsePaint);

    // 2. Vẽ bóng mờ dưới vòng tròn trắng để tạo độ nổi khối (depth)
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 1.5),
      18,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // 3. Vòng tròn màu trắng làm viền cho chấm xanh
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 18, whitePaint);

    // 4. Chấm tròn màu xanh dương đậm ở tâm
    final bluePaint = Paint()
      ..color = const Color(0xFF1A73E8) // Màu xanh Google Maps đặc trưng
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 12, bluePaint);

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
