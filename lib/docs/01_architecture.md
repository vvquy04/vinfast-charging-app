# 01 — Kiến trúc ứng dụng (Architecture)

> Tài liệu mô tả kiến trúc tổng quan của ứng dụng **VinFast Charging Station Finder** — phía client (Flutter).

---

## 1. Tổng quan

Ứng dụng được xây dựng bằng **Flutter (Dart)**, hướng tới nền tảng **Android** (mở rộng iOS về sau). Kiến trúc tuân theo mô hình **Clean Architecture phiên bản đơn giản**, chia thành 3 lớp chính:

| Lớp | Thư mục | Trách nhiệm |
|-----|---------|-------------|
| **Core** | `lib/core/` | Hằng số, tiện ích dùng chung, widget tái sử dụng |
| **Data** | `lib/data/` | Model, gọi API, xử lý dữ liệu |
| **Presentation** | `lib/presentation/` | Giao diện (screens) và quản lý trạng thái (providers) |

### Luồng phụ thuộc (Dependency Flow)

```
Presentation  →  Data  →  Core
 (screens)     (repos)   (constants, utils)
 (providers)   (services)
               (models)
```

> **Quy tắc:** Lớp trên chỉ được phụ thuộc vào lớp dưới, không được phụ thuộc ngược lại.

---

## 2. Cây thư mục chi tiết

```
lib/
├── core/
│   ├── constants/          # Hằng số: API URL, màu sắc, chuỗi text
│   ├── utils/              # Hàm tiện ích dùng chung (format, validate, haversine...)
│   └── widgets/            # Widget dùng lại nhiều nơi (custom button, loading, card...)
│
├── data/
│   ├── models/             # Data class: User, ChargingStation, Review, ConnectorType...
│   ├── services/           # Tầng gọi API backend (dùng Dio / http)
│   └── repositories/       # Logic xử lý & tổng hợp dữ liệu từ services
│
├── presentation/
│   ├── screens/            # Các màn hình chính
│   │   ├── auth/           #   → Đăng nhập, đăng ký
│   │   ├── map/            #   → Bản đồ chính (hiển thị trạm sạc)
│   │   ├── search/         #   → Tìm kiếm & lọc trạm sạc
│   │   ├── detail/         #   → Chi tiết trạm sạc
│   │   └── review/         #   → Đánh giá & bình luận
│   └── providers/          # State management (Provider / Riverpod / setState)
│
├── docs/                   # Tài liệu dự án (file bạn đang đọc)
└── main.dart               # Entry point
```

---

## 3. Mô tả từng lớp

### 3.1 Core

| Thư mục | Nội dung |
|---------|---------|
| `constants/` | `api_constants.dart` — base URL, endpoint paths; `app_colors.dart` — bảng màu; `app_strings.dart` — text tĩnh |
| `utils/` | Các hàm helper: tính khoảng cách Haversine, format ngày giờ, validate email/phone... |
| `widgets/` | Widget tái sử dụng: `CustomAppBar`, `LoadingIndicator`, `StationCard`, `RatingStars`... |

### 3.2 Data

| Thư mục | Nội dung |
|---------|---------|
| `models/` | Các data class ánh xạ từ JSON API: `User`, `ChargingStation`, `ConnectorType`, `Review`, `UserStationHistory` |
| `services/` | Các class gọi API REST: `AuthService`, `StationService`, `ReviewService`... — mỗi service tương ứng 1 nhóm endpoint |
| `repositories/` | Tổng hợp logic nghiệp vụ: kết hợp nhiều service, xử lý cache cục bộ, mapping dữ liệu |

### 3.3 Presentation

| Thư mục | Nội dung |
|---------|---------|
| `screens/` | Mỗi thư mục con = 1 nhóm màn hình liên quan. Mỗi màn hình là 1 `StatefulWidget` hoặc `StatelessWidget` |
| `providers/` | Quản lý trạng thái cho từng feature — cung cấp dữ liệu cho screens |

---

## 4. Công nghệ sử dụng

| Thành phần | Công nghệ | Ghi chú |
|-----------|-----------|---------|
| Framework | Flutter 3.x (Dart) | SDK ^3.11.4 |
| HTTP Client | `dio` hoặc `http` | Gọi REST API tới backend |
| Bản đồ | `flutter_map` + `latlong2` | Hiển thị bản đồ OpenStreetMap |
| State management | Provider / Riverpod | *(cần xác nhận lựa chọn cuối)* |
| Navigation | Navigator 2.0 hoặc `go_router` | *(cần xác nhận lựa chọn cuối)* |
| Backend | Spring Boot (Java) + MySQL | Server riêng biệt, giao tiếp qua REST API |

---

## 5. Sơ đồ kiến trúc tổng quan

```
┌─────────────────────────────────────────────┐
│                 Flutter App                  │
│  ┌────────────────────────────────────────┐  │
│  │          Presentation Layer            │  │
│  │  screens/ ←→ providers/                │  │
│  └────────────────┬───────────────────────┘  │
│                   │ gọi repository            │
│  ┌────────────────▼───────────────────────┐  │
│  │             Data Layer                 │  │
│  │  repositories/ → services/ → models/   │  │
│  └────────────────┬───────────────────────┘  │
│                   │ sử dụng constants/utils   │
│  ┌────────────────▼───────────────────────┐  │
│  │             Core Layer                 │  │
│  │  constants/  utils/  widgets/          │  │
│  └────────────────────────────────────────┘  │
└──────────────────┬──────────────────────────┘
                   │ REST API (HTTP/JSON)
┌──────────────────▼──────────────────────────┐
│         Spring Boot Backend + MySQL          │
└──────────────────────────────────────────────┘
```

---

## 6. Nguyên tắc thiết kế

1. **Separation of Concerns** — Mỗi lớp chỉ lo 1 việc duy nhất.
2. **Single Responsibility** — Mỗi file/class chỉ đảm nhận 1 trách nhiệm.
3. **DRY (Don't Repeat Yourself)** — Widget & logic dùng lại phải đặt vào `core/`.
4. **Lớp dưới không biết lớp trên** — `data/` không import `presentation/`.
5. **Đặt tên nhất quán** — Xem chi tiết tại [04_coding_rules.md](./04_coding_rules.md).
