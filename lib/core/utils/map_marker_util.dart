import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_colors.dart';

class MapMarkerUtil {
  /// Vẽ cờ Trạm sạc hình Giọt nước Đen với tia sét
  static Future<BitmapDescriptor> createStationMarker(bool isAvailable) async {
    const int size = 120; // kích thước marker phân giải cao
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Vẽ bóng đổ (Drop Shadow)
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 10), size / 4, shadowPaint);

    // Vẽ hình giọt nước đen
    final Paint paint = Paint()..color = AppColors.charcoal;
    final Path path = Path();
    path.moveTo(size / 2, size * 0.9);
    path.quadraticBezierTo(size * 0.1, size * 0.5, size * 0.1, size * 0.3);
    path.arcToPoint(Offset(size * 0.9, size * 0.3),
        radius: const Radius.circular(size * 0.4), clockwise: true);
    path.quadraticBezierTo(size * 0.9, size * 0.5, size / 2, size * 0.9);
    canvas.drawPath(path, paint);

    // Vẽ vòng tròn trạng thái
    final Paint statusPaint = Paint()..color = isAvailable ? AppColors.primary : AppColors.lightGray;
    canvas.drawCircle(Offset(size / 2, size * 0.35), size * 0.18, statusPaint);

    // Vẽ tia sét trắng
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = const TextSpan(
      text: '⚡',
      style: TextStyle(fontSize: 28, color: Colors.white),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size / 2 - textPainter.width / 2, size * 0.35 - textPainter.height / 2),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  /// Vẽ vị trí người dùng bằng User Avatar
  static Future<BitmapDescriptor> createAvatarMarker() async {
    const int size = 150;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Vẽ quầng sóng xanh lá mạ
    final Paint pulsePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, pulsePaint);

    // Bo viền đen bao bọc Avatar
    final Paint borderPaint = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size * 0.3, borderPaint);

    // Vẽ Avatar (Chữ U tạm nếu chưa có hình)
    final Paint avatarBg = Paint()..color = AppColors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size * 0.26, avatarBg);

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = const TextSpan(
      text: 'U', // Ý nghĩa User
      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.black),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
