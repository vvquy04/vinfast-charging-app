# Spec: EVCPoint MVP — VinFast EV Charging App (Flutter Client)

> Đặc tả tổng hợp cho ứng dụng mobile Flutter tìm kiếm và đánh giá trạm sạc xe điện VinFast.

---

## 1. Tổng quan

### Mục tiêu
Xây dựng ứng dụng mobile bằng **Flutter (Dart)** trên nền tảng **Android** (mở rộng iOS sau), giao tiếp với backend Spring Boot qua REST API, cung cấp:
- Xác thực (đăng ký, đăng nhập, lưu phiên)
- Bản đồ tìm trạm sạc + hiển thị marker
- Chi tiết trạm sạc (cổng sạc, đánh giá)
- Đánh giá trạm sạc (viết, xoá)
- Hồ sơ người dùng + lịch sử trạm đã xem

### Tech Stack
| Layer | Công nghệ |
|-------|-----------|
| Framework | Flutter 3.x (Dart SDK ^3.11.4) |
| HTTP Client | `dio` |
| Bản đồ | `flutter_map` + `latlong2` (OpenStreetMap) |
| State Management | Provider (ChangeNotifier) |
| Local Storage | SharedPreferences |
| Backend | Spring Boot 4.0 (Java) + MySQL — REST API |

### Kiến trúc (Clean Architecture — Simplified)
```
Presentation (screens/, providers/)
    ↓
Data (repositories/, services/, models/)
    ↓
Core (constants/, utils/, widgets/)
```
- **Quy tắc:** Lớp trên chỉ phụ thuộc lớp dưới, không ngược lại
- **Services** gọi API qua Dio, **Repositories** tổng hợp logic nghiệp vụ
- **Providers** (ChangeNotifier) cung cấp state cho screens

---

## 2. User Stories

### US-1: Onboarding & Walkthrough
**Là** người dùng lần đầu mở app,
**Tôi muốn** thấy các màn hình giới thiệu tính năng chính,
**Để** hiểu cách sử dụng app trước khi đăng ký.

**Acceptance Criteria:**
- [ ] Hiển thị 3 slide walkthrough (tìm trạm, sạc xe, đánh giá)
- [ ] Nút "Bắt đầu" để chuyển sang màn đăng ký/đăng nhập
- [ ] Chỉ hiển thị walkthrough 1 lần (lưu flag vào SharedPreferences)

### US-2: Đăng ký tài khoản
**Là** người dùng mới,
**Tôi muốn** đăng ký bằng số điện thoại, mật khẩu, họ tên,
**Để** tạo tài khoản và sử dụng app.

**Acceptance Criteria:**
- [ ] Màn hình nhập: `fullName`, `phoneNumber`, `password` (bắt buộc)
- [ ] Màn hình bổ sung: chọn `vehicleModel` (VF5, VF8, VF9...) + `connectorType` (CCS2, AC, Type2...)
- [ ] Gọi `POST /api/auth/register`
- [ ] Lưu JWT token vào SharedPreferences sau khi đăng ký thành công
- [ ] Validate: SĐT đúng format, mật khẩu ≥ 6 ký tự
- [ ] Hiển thị lỗi từ server (SĐT đã tồn tại, v.v.)

### US-3: Đăng nhập
**Là** người dùng đã có tài khoản,
**Tôi muốn** đăng nhập bằng SĐT và mật khẩu,
**Để** truy cập các tính năng cần xác thực.

**Acceptance Criteria:**
- [ ] Màn hình nhập `phoneNumber`, `password`
- [ ] Gọi `POST /api/auth/login`
- [ ] Lưu JWT token vào SharedPreferences
- [ ] Chuyển sang Dashboard sau khi đăng nhập thành công
- [ ] Hiển thị lỗi nếu đăng nhập sai
- [ ] Auto-login khi mở app nếu token còn hợp lệ

### US-4: Bản đồ trạm sạc
**Là** người dùng xe điện,
**Tôi muốn** xem bản đồ với các trạm sạc gần mình,
**Để** biết trạm nào ở gần nhất.

**Acceptance Criteria:**
- [ ] Bản đồ toàn màn hình (OpenStreetMap via `flutter_map`)
- [ ] Lấy vị trí GPS hiện tại, hiển thị marker "Bạn đang ở đây"
- [ ] Hiển thị marker cho mỗi trạm sạc (gọi `GET /api/stations`)
- [ ] Tap marker → popup tóm tắt (tên, rating, khoảng cách)
- [ ] Tap popup → chuyển sang màn chi tiết trạm

### US-5: Tìm kiếm & Lọc trạm sạc
**Là** người dùng,
**Tôi muốn** tìm trạm theo tên/địa chỉ và lọc theo loại cổng sạc,
**Để** tìm đúng trạm phù hợp xe của mình.

**Acceptance Criteria:**
- [ ] Ô tìm kiếm theo keyword (tên, địa chỉ)
- [ ] Bộ lọc: loại cổng sạc (AC, DC, CCS2, CHAdeMO, Type2)
- [ ] Bộ lọc: bán kính (5km, 10km, 20km, 50km)
- [ ] Danh sách kết quả sắp xếp theo khoảng cách
- [ ] Load more (phân trang)

### US-6: Chi tiết trạm sạc
**Là** người dùng,
**Tôi muốn** xem đầy đủ thông tin một trạm sạc,
**Để** quyết định có đi sạc ở đó không.

**Acceptance Criteria:**
- [ ] Gọi `GET /api/stations/{stationId}`
- [ ] Hiển thị: tên, địa chỉ, giờ mở cửa, hình ảnh
- [ ] Hiển thị danh sách cổng sạc: loại, công suất (kW), số cổng
- [ ] Hiển thị rating trung bình + tổng review
- [ ] Hiển thị 5 đánh giá mới nhất
- [ ] Nút "Xem tất cả đánh giá" → danh sách đầy đủ
- [ ] Nút "Chỉ đường" → mở Google Maps / Apple Maps
- [ ] Gọi `POST /api/users/me/history` khi mở màn chi tiết (ghi nhận lượt xem)

### US-7: Đánh giá trạm sạc
**Là** người dùng đã đăng nhập,
**Tôi muốn** viết đánh giá (chọn sao + bình luận),
**Để** chia sẻ trải nghiệm sạc xe.

**Acceptance Criteria:**
- [ ] Widget chọn sao (1–5)
- [ ] Ô nhập bình luận (không bắt buộc)
- [ ] Gọi `POST /api/stations/{stationId}/reviews`
- [ ] Sau khi gửi → reload danh sách đánh giá
- [ ] Nút xoá (chỉ hiện cho review của mình): `DELETE /api/stations/{stationId}/reviews/{reviewId}`

### US-8: Hồ sơ người dùng
**Là** người dùng đã đăng nhập,
**Tôi muốn** xem và chỉnh sửa thông tin cá nhân,
**Để** cập nhật dòng xe và cổng sạc phù hợp.

**Acceptance Criteria:**
- [ ] Gọi `GET /api/users/me` hiển thị: avatar, họ tên, SĐT, email, giới tính, ngày sinh, dòng xe, cổng sạc
- [ ] Cho phép sửa và gọi `PUT /api/users/me`
- [ ] Nút đăng xuất: xoá token, quay về màn đăng nhập

### US-9: Lịch sử trạm đã xem
**Là** người dùng đã đăng nhập,
**Tôi muốn** xem danh sách trạm đã truy cập gần đây,
**Để** quay lại trạm quen thuộc nhanh chóng.

**Acceptance Criteria:**
- [ ] Gọi `GET /api/users/me/history`
- [ ] Hiển thị danh sách: tên trạm, số lần truy cập, thời gian lần cuối
- [ ] Tap → chuyển sang chi tiết trạm
- [ ] Hỗ trợ phân trang (load more)

---

## 3. Cây màn hình (Screen Map)

```
SplashScreen
    ├── WalkthroughScreen (lần đầu)
    │       └── LoginOptionsScreen
    │               ├── PhoneInputScreen → OTPVerificationScreen
    │               ├── LoginScreen
    │               └── CompleteProfileScreen → AddVehicleScreen
    └── DashboardScreen (đã đăng nhập)
            ├── HomeMapScreen (bản đồ)
            ├── HistoryScreen (lịch sử)
            ├── StationDetailScreen
            │       └── ReviewListScreen
            └── ProfileScreen
                    └── EditProfileScreen
```

---

## 4. Data Layer

### Models (ánh xạ JSON từ API)
| Model | File | Ánh xạ |
|-------|------|--------|
| `UserModel` | `data/models/user_model.dart` | Response từ `/api/users/me` |
| `StationSummaryModel` | `data/models/station_summary_model.dart` | Item trong `/api/stations` |
| `StationDetailModel` | `data/models/station_detail_model.dart` | Response từ `/api/stations/{id}` |
| `ConnectorTypeModel` | `data/models/connector_type_model.dart` | Nested trong station |
| `StationHistoryModel` | `data/models/station_history_model.dart` | Item trong `/api/users/me/history` |

### Services (gọi API via Dio)
| Service | File | Endpoints |
|---------|------|-----------|
| `AuthService` | `data/services/auth_service.dart` | `/api/auth/*` |
| `StationService` | `data/services/station_service.dart` | `/api/stations/*` |
| `HistoryService` | `data/services/history_service.dart` | `/api/users/me/history` |

### Providers (State Management)
| Provider | File | Quản lý |
|----------|------|---------|
| `AuthProvider` | `presentation/providers/auth_provider.dart` | Login state, JWT, user info |
| `StationProvider` | `presentation/providers/station_provider.dart` | Station list, search, filter |
| `HistoryProvider` | `presentation/providers/history_provider.dart` | Visit history |

---

## 5. Constraints & Non-Functional Requirements

1. **API base URL** cấu hình được (không hard-code)
2. **JWT token** lưu trong SharedPreferences, gắn vào Dio Interceptor
3. **Xử lý lỗi 401** (token hết hạn) → tự động chuyển về màn đăng nhập
4. **Loading state** hiển thị indicator khi đang gọi API
5. **Offline fallback**: hiển thị thông báo "Không có kết nối mạng" khi mất mạng
6. **Responsive**: Hỗ trợ các kích thước màn hình Android phổ biến

---

## Review & Acceptance Checklist

- [ ] Tất cả user stories đều có acceptance criteria rõ ràng
- [ ] Screen map phủ hết user stories
- [ ] Data models khớp với API response format trong `docs/03_api_design.md`
- [ ] Services khớp với endpoint list trong `docs/03_api_design.md`
- [ ] Kiến trúc lớp tuân thủ `docs/01_architecture.md`
- [ ] Đặt tên tuân thủ `docs/04_coding_rules.md`
