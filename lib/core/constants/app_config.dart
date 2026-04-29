/// Các hằng số cấu hình ứng dụng.
/// Tập trung tất cả API key và config tại một nơi duy nhất.
class AppConfig {
  AppConfig._();

  /// Google Maps API Key — dùng cho cả Maps SDK lẫn Directions API.
  /// ⚠️ Thay thế bằng key thật của bạn từ Google Cloud Console.
  static const String googleMapsApiKey = 'YOUR_MAPS_API_KEY_HERE';
}
