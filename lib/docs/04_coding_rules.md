# 04 — Quy tắc viết code (Coding Rules)

> Tài liệu quy định cách đặt tên, tổ chức file và các best practice khi viết code Flutter/Dart cho dự án.

---

## 1. Quy tắc đặt tên

### 1.1 Tên file

| Loại | Quy tắc | Ví dụ |
|------|---------|-------|
| File Dart | `snake_case.dart` | `charging_station.dart`, `auth_service.dart` |
| Widget screen | `<tên>_screen.dart` | `login_screen.dart`, `map_screen.dart` |
| Widget dùng chung | `<tên>_widget.dart` hoặc `<tên>.dart` | `station_card.dart`, `rating_stars.dart` |
| Model | `<tên>.dart` | `user.dart`, `review.dart` |
| Service | `<tên>_service.dart` | `station_service.dart` |
| Repository | `<tên>_repository.dart` | `station_repository.dart` |
| Provider | `<tên>_provider.dart` | `auth_provider.dart` |
| Constants | `<nhóm>_constants.dart` | `api_constants.dart`, `app_colors.dart` |

### 1.2 Tên class, biến, hàm

| Loại | Quy tắc | Ví dụ |
|------|---------|-------|
| Class | `PascalCase` | `ChargingStation`, `AuthService` |
| Biến / tham số | `camelCase` | `stationId`, `isActive` |
| Hàm / method | `camelCase` | `fetchStations()`, `calculateDistance()` |
| Hằng số | `camelCase` hoặc `SCREAMING_SNAKE` | `baseUrl`, `MAX_RETRY_COUNT` |
| Enum values | `camelCase` | `ConnectorType.ccs2` |
| Private | Prefix `_` | `_counter`, `_buildStationList()` |

### 1.3 Tên thư mục

- Dùng `snake_case`
- Nhóm theo **feature**, không nhóm theo loại widget
- Ví dụ: `screens/auth/`, `screens/map/`, `screens/detail/`

---

## 2. Tổ chức file

### 2.1 Mỗi file chỉ chứa 1 class public chính

```
✅ user.dart          → class User { ... }
✅ auth_service.dart   → class AuthService { ... }
❌ models.dart         → class User { ... } + class Review { ... }  ← KHÔNG
```

### 2.2 Thứ tự các phần trong 1 file Dart

```dart
// 1. Import thư viện Dart
import 'dart:convert';
import 'dart:math';

// 2. Import package bên ngoài
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// 3. Import file trong dự án
import 'package:client/core/constants/api_constants.dart';
import 'package:client/data/models/user.dart';

// 4. Phần code chính
class AuthService {
  // ...
}
```

### 2.3 Thứ tự các thành phần trong 1 class Widget

```dart
class StationDetailScreen extends StatefulWidget {
  // 1. Static constants
  // 2. Final fields (props)
  // 3. Constructor
  // 4. createState()

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  // 1. State variables
  // 2. Lifecycle methods: initState(), dispose()
  // 3. Business logic methods (private)
  // 4. Build methods (private helpers)
  // 5. build() — luôn đặt cuối cùng

  @override
  Widget build(BuildContext context) {
    return ...;
  }
}
```

---

## 3. Quy tắc viết code

### 3.1 Dart Best Practices

```dart
// ✅ Dùng `const` cho widget không đổi
const Text('Hello World');

// ✅ Dùng `final` cho biến không gán lại
final String name = 'VinFast';

// ✅ Dùng string interpolation
print('Trạm: $stationName (${station.rating} ⭐)');

// ✅ Dùng named parameters cho widget constructor
const StationCard({
  required this.station,
  this.onTap,
  super.key,
});

// ✅ Dùng `?.` và `??` thay vì check null tay
final displayName = user?.fullName ?? 'Khách';

// ❌ KHÔNG dùng `print()` trong production → dùng `debugPrint()` hoặc logger
```

### 3.2 Widget

```dart
// ✅ Tách widget phức tạp thành widget con (method hoặc class riêng)
Widget _buildHeader() { ... }
Widget _buildStationList() { ... }

// ✅ Dùng `const` constructor khi widget không có state
class RatingStars extends StatelessWidget {
  const RatingStars({required this.rating, super.key});
  ...
}

// ❌ KHÔNG viết widget quá dài (> 200 dòng) → tách thành file riêng
```

### 3.3 API & Async

```dart
// ✅ Luôn xử lý lỗi khi gọi API
try {
  final response = await stationService.fetchStations();
  // xử lý thành công
} on DioException catch (e) {
  // xử lý lỗi mạng
} catch (e) {
  // xử lý lỗi khác
}

// ✅ Dùng async/await thay vì .then()
// ✅ Hiển thị loading indicator khi chờ API
```

---

## 4. Comment & tài liệu

```dart
/// Tính khoảng cách giữa 2 tọa độ GPS bằng công thức Haversine.
///
/// Trả về khoảng cách tính bằng **km**.
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  // ...
}

// Comment ngắn cho logic phức tạp
// Nhân hệ số 0.7 cho distance vì user ưu tiên trạm gần
final adjustedScore = score * 0.7;
```

**Quy tắc:**
- Dùng `///` (doc comment) cho **class**, **method public**, **field quan trọng**.
- Dùng `//` cho giải thích logic phức tạp bên trong hàm.
- **KHÔNG** comment cho code hiển nhiên (`// tăng biến đếm lên 1` ← không cần).

---

## 5. Kiểm tra chất lượng

Trước khi commit, đảm bảo:

- [ ] `flutter analyze` — không có warning/error
- [ ] Code đã format bằng `dart format .`
- [ ] Không có `print()` — thay bằng `debugPrint()` hoặc xoá
- [ ] Không có code thừa / import không dùng
- [ ] Widget phức tạp đã tách thành phần nhỏ hơn
- [ ] Tên file, class, biến theo đúng quy tắc ở mục 1
