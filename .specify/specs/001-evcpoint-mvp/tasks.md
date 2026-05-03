# Tasks: EVCPoint MVP — Client (Flutter App)

> Danh sách task triển khai, sắp xếp theo thứ tự dependency. `[P]` = có thể chạy song song.

---

## Phase 1 — Core Foundation

- [ ] **1.1** [P] Tạo `core/constants/app_colors.dart`
  - Bảng màu: primary (xanh VinFast #00552E), secondary, background, surface, text, error
  - File: `lib/core/constants/app_colors.dart`

- [ ] **1.2** [P] Tạo `core/constants/app_sizes.dart`
  - Spacing, padding, borderRadius, fontSize
  - File: `lib/core/constants/app_sizes.dart`

- [ ] **1.3** [P] Tạo `core/constants/map_style.dart`
  - OpenStreetMap tile URL
  - File: `lib/core/constants/map_style.dart`

- [ ] **1.4** Tạo `core/utils/dio_client.dart`
  - Singleton Dio, base URL, JWT interceptor, 401 handler
  - File: `lib/core/utils/dio_client.dart`
  - Checkpoint: Dio instance gọi được API

- [ ] **1.5** [P] Tạo `core/utils/validators.dart`
  - validatePhoneNumber, validatePassword, validateEmail
  - File: `lib/core/utils/validators.dart`

- [ ] **1.6** [P] Tạo `core/utils/map_marker_util.dart`
  - Custom marker builder cho flutter_map
  - File: `lib/core/utils/map_marker_util.dart`

- [ ] **1.7** [P] Tạo reusable widgets
  - `core/widgets/app_button.dart` — Primary + outlined + loading
  - `core/widgets/app_text_field.dart` — Label, hint, error, icon, obscure toggle
  - `core/widgets/app_social_button.dart` — Social login button

---

## Phase 2 — Auth Flow

- [ ] **2.1** Tạo `data/models/user_model.dart`
  - fromJson / toJson
  - File: `lib/data/models/user_model.dart`

- [ ] **2.2** Tạo `data/services/auth_service.dart`
  - register, login, getProfile, updateProfile
  - File: `lib/data/services/auth_service.dart`

- [ ] **2.3** Tạo `data/repositories/auth_repository.dart`
  - Wrap AuthService + SharedPreferences (token management)
  - File: `lib/data/repositories/auth_repository.dart`

- [ ] **2.4** Tạo `presentation/providers/auth_provider.dart`
  - ChangeNotifier: login, register, logout, loadProfile, checkAuthStatus
  - File: `lib/presentation/providers/auth_provider.dart`

- [ ] **2.5** Tạo Auth Screens
  - `presentation/screens/auth/splash_screen.dart` — Check auth → navigate
  - `presentation/screens/auth/walkthrough_screen.dart` — 3 slides
  - `presentation/screens/auth/login_options_screen.dart` — Chọn phương thức
  - `presentation/screens/auth/phone_input_screen.dart` — Nhập SĐT
  - `presentation/screens/auth/otp_verification_screen.dart` — Xác thực OTP
  - `presentation/screens/auth/login_screen.dart` — SĐT + password
  - `presentation/screens/auth/complete_profile_screen.dart` — Thông tin bổ sung
  - `presentation/screens/auth/add_vehicle_screen.dart` — Chọn xe + cổng sạc
  - Checkpoint: Full auth flow hoạt động end-to-end

---

## Phase 3 — Station Module

- [ ] **3.1** [P] Tạo Station Models
  - `data/models/station_summary_model.dart` — fromJson
  - `data/models/station_detail_model.dart` — fromJson
  - `data/models/connector_type_model.dart` — fromJson

- [ ] **3.2** Tạo `data/services/station_service.dart`
  - getStations, getStationDetail, getReviews, createReview, deleteReview
  - File: `lib/data/services/station_service.dart`

- [ ] **3.3** Tạo `data/repositories/station_repository.dart`
  - Wrap StationService
  - File: `lib/data/repositories/station_repository.dart`

- [ ] **3.4** Tạo `presentation/providers/station_provider.dart`
  - ChangeNotifier: loadStations, loadMore, searchStations, selectStation
  - File: `lib/presentation/providers/station_provider.dart`

- [ ] **3.5** Tạo `presentation/screens/home/home_map_screen.dart`
  - flutter_map + markers + GPS + search bar
  - File: `lib/presentation/screens/home/home_map_screen.dart`
  - Checkpoint: Bản đồ hiển thị markers từ API

- [ ] **3.6** Tạo `presentation/screens/station/station_detail_screen.dart`
  - Thông tin trạm + connectors + reviews + nút chỉ đường
  - Auto ghi nhận lịch sử khi mở
  - File: `lib/presentation/screens/station/station_detail_screen.dart`
  - Checkpoint: Chi tiết trạm hiển thị đúng

---

## Phase 4 — Social Module (Reviews + History)

- [ ] **4.1** Review UI trong StationDetailScreen
  - Widget chọn sao + nhập comment + gửi
  - Danh sách review + nút xoá (chỉ review của mình)
  - Checkpoint: Tạo + xoá review thành công

- [ ] **4.2** Tạo `data/models/station_history_model.dart`
  - File: `lib/data/models/station_history_model.dart`

- [ ] **4.3** Tạo `data/services/history_service.dart`
  - getHistory, recordVisit
  - File: `lib/data/services/history_service.dart`

- [ ] **4.4** Tạo `presentation/providers/history_provider.dart`
  - File: `lib/presentation/providers/history_provider.dart`

- [ ] **4.5** Tạo `presentation/screens/history/history_screen.dart`
  - ListView + tap → chi tiết trạm
  - File: `lib/presentation/screens/history/history_screen.dart`
  - Checkpoint: Lịch sử hiển thị + navigate đúng

---

## Phase 5 — Dashboard & Profile

- [ ] **5.1** Tạo/cập nhật `presentation/screens/home/dashboard_screen.dart`
  - BottomNavigationBar: Bản đồ | Lịch sử | Hồ sơ
  - IndexedStack giữ state
  - File: `lib/presentation/screens/home/dashboard_screen.dart`

- [ ] **5.2** Tạo ProfileScreen
  - Hiển thị avatar, thông tin cá nhân, nút sửa, nút đăng xuất
  - File: `lib/presentation/screens/profile/profile_screen.dart`

- [ ] **5.3** Tạo EditProfileScreen
  - Form chỉnh sửa + gọi PUT /api/users/me
  - File: `lib/presentation/screens/profile/edit_profile_screen.dart`

---

## Phase 6 — Integration & Polish

- [ ] **6.1** Cấu hình `main.dart`
  - MultiProvider setup (AuthProvider, StationProvider, HistoryProvider)
  - Route definitions
  - File: `lib/main.dart`
  - Checkpoint: App khởi chạy, navigate giữa các screens

- [ ] **6.2** Test end-to-end flow
  - Splash → Login → Dashboard → Bản đồ → Chi tiết trạm → Review → Lịch sử → Profile → Đăng xuất

---

## Final Verification

- [ ] `flutter analyze` → No errors
- [ ] `flutter build apk --debug` → SUCCESS
- [ ] App chạy trên thiết bị/emulator: full flow hoạt động
