# Plan: EVCPoint MVP — Client (Flutter App)

> Kế hoạch triển khai kỹ thuật chi tiết cho ứng dụng Flutter.

---

## 1. Thứ tự triển khai

```
Phase 1: Core Foundation
  ├── 1.1 Constants (API URL, Colors, Sizes)
  ├── 1.2 Dio Client + JWT Interceptor
  ├── 1.3 Validators + Utilities
  └── 1.4 Reusable Widgets (AppButton, AppTextField, AppSocialButton)

Phase 2: Auth Flow
  ├── 2.1 Models: UserModel
  ├── 2.2 Services: AuthService
  ├── 2.3 Repositories: AuthRepository
  ├── 2.4 Providers: AuthProvider
  └── 2.5 Screens: SplashScreen → WalkthroughScreen → LoginOptionsScreen
            → PhoneInputScreen → OTPVerificationScreen
            → LoginScreen → CompleteProfileScreen → AddVehicleScreen

Phase 3: Station Module
  ├── 3.1 Models: StationSummaryModel, StationDetailModel, ConnectorTypeModel
  ├── 3.2 Services: StationService
  ├── 3.3 Repositories: StationRepository
  ├── 3.4 Providers: StationProvider
  └── 3.5 Screens: HomeMapScreen, StationDetailScreen

Phase 4: Social Module
  ├── 4.1 Reviews (UI trong StationDetailScreen)
  ├── 4.2 Models: StationHistoryModel
  ├── 4.3 Services: HistoryService
  ├── 4.4 Providers: HistoryProvider
  └── 4.5 Screens: HistoryScreen

Phase 5: Profile & Navigation
  ├── 5.1 DashboardScreen (BottomNavigationBar)
  ├── 5.2 ProfileScreen
  └── 5.3 EditProfileScreen
```

---

## 2. Chi tiết triển khai theo file

### Phase 1 — Core Foundation

#### `core/constants/app_colors.dart`
- Bảng màu chính: primary (xanh VinFast), secondary, background, surface, text, error
- Dark/Light variants

#### `core/constants/app_sizes.dart`
- Spacing, padding, border radius, font sizes chuẩn hoá

#### `core/constants/map_style.dart`
- Cấu hình tile URL cho OpenStreetMap

#### `core/utils/dio_client.dart`
- Singleton Dio instance
- Base URL cấu hình được
- Interceptor: gắn JWT token từ SharedPreferences vào header `Authorization`
- Interceptor: handle 401 → redirect về login
- Interceptor: log request/response (debug)

#### `core/utils/validators.dart`
- `validatePhoneNumber(String)` → regex VN phone
- `validatePassword(String)` → min 6 ký tự
- `validateEmail(String)` → email format

#### `core/utils/map_marker_util.dart`
- Utility để tạo custom marker widget cho flutter_map

#### `core/widgets/app_button.dart`
- Primary button với loading state
- Variant: outlined, text button

#### `core/widgets/app_text_field.dart`
- Custom TextField với label, hint, error, icon
- Obscure text toggle cho password

#### `core/widgets/app_social_button.dart`
- Button style cho social login (Google, Apple)

### Phase 2 — Auth Flow

#### `data/models/user_model.dart`
- `fromJson(Map)` / `toJson()`
- Fields: `userId`, `fullName`, `phoneNumber`, `email`, `gender`, `dateOfBirth`, `avatarUrl`, `vehicleModel`, `connectorType`, `createdAt`

#### `data/services/auth_service.dart`
- `register(RegisterRequest)` → `POST /api/auth/register`
- `login(phone, password)` → `POST /api/auth/login`
- `getProfile()` → `GET /api/users/me`
- `updateProfile(data)` → `PUT /api/users/me`

#### `data/repositories/auth_repository.dart`
- Wrap AuthService + lưu/xoá token vào SharedPreferences
- `isLoggedIn()` → check token existence
- `logout()` → clear token + user data

#### `presentation/providers/auth_provider.dart`
- `ChangeNotifier`
- State: `currentUser`, `isLoading`, `errorMessage`, `isAuthenticated`
- Methods: `login()`, `register()`, `logout()`, `loadProfile()`, `checkAuthStatus()`

#### Auth Screens
- `SplashScreen` → check auth → navigate
- `WalkthroughScreen` → 3 slides + "Bắt đầu"
- `LoginOptionsScreen` → chọn phương thức đăng nhập
- `PhoneInputScreen` → nhập SĐT
- `LoginScreen` → nhập SĐT + mật khẩu
- `CompleteProfileScreen` → nhập thông tin bổ sung
- `AddVehicleScreen` → chọn dòng xe + cổng sạc

### Phase 3 — Station Module

#### `data/models/station_summary_model.dart`
- Fields: `stationId`, `name`, `address`, `latitude`, `longitude`, `openingHours`, `imageUrl`, `rating`, `totalReviews`, `distance`, `connectorTypes[]`

#### `data/models/station_detail_model.dart`
- Extends summary + `recentReviews[]`

#### `data/models/connector_type_model.dart`
- Fields: `connectorId`, `type`, `powerKw`, `totalPorts`

#### `data/services/station_service.dart`
- `getStations(lat, lng, radius, connectorType, page, size)` → `GET /api/stations`
- `getStationDetail(stationId)` → `GET /api/stations/{id}`
- `getReviews(stationId, page, size)` → `GET /api/stations/{id}/reviews`
- `createReview(stationId, rating, comment)` → `POST /api/stations/{id}/reviews`
- `deleteReview(stationId, reviewId)` → `DELETE`

#### `data/repositories/station_repository.dart`
- Wrap StationService, manage pagination state

#### `presentation/providers/station_provider.dart`
- State: `stations[]`, `selectedStation`, `isLoading`, `currentPage`
- Methods: `loadStations()`, `loadMore()`, `searchStations()`, `selectStation()`

#### Station Screens
- `HomeMapScreen` → bản đồ flutter_map + markers + search bar
- `StationDetailScreen` → thông tin trạm + connectors + reviews + nút chỉ đường

### Phase 4 — Social Module

#### `data/models/station_history_model.dart`
- Fields: `stationId`, `stationName`, `visitCount`, `lastVisited`

#### `data/services/history_service.dart`
- `getHistory(page, size)` → `GET /api/users/me/history`
- `recordVisit(stationId)` → `POST /api/users/me/history`

#### `data/repositories/history_repository.dart`
- Wrap HistoryService

#### `presentation/providers/history_provider.dart`
- State: `historyItems[]`, `isLoading`
- Methods: `loadHistory()`, `recordVisit(stationId)`

#### `presentation/screens/history/history_screen.dart`
- ListView hiển thị lịch sử, tap → chi tiết trạm

### Phase 5 — Dashboard & Profile

#### `presentation/screens/home/dashboard_screen.dart`
- `BottomNavigationBar` với 3 tabs: Bản đồ, Lịch sử, Hồ sơ
- `IndexedStack` hoặc `PageView` để giữ state giữa các tab

#### Profile Screens
- `ProfileScreen` → hiển thị thông tin + nút sửa + nút đăng xuất
- `EditProfileScreen` → form chỉnh sửa thông tin

---

## 3. Dependencies (pubspec.yaml)

```yaml
dependencies:
  dio: ^5.x
  provider: ^6.x
  flutter_map: ^6.x
  latlong2: ^0.9.x
  shared_preferences: ^2.x
  geolocator: ^12.x
  url_launcher: ^6.x
```

---

## 4. Verification Plan

### Build
```bash
flutter analyze
flutter build apk --debug
```

### Manual Test
1. Mở app → SplashScreen → Walkthrough
2. Đăng ký → Đăng nhập → Dashboard
3. Xem bản đồ → Tap marker → Chi tiết trạm
4. Viết đánh giá → Xoá đánh giá
5. Xem lịch sử
6. Xem/sửa profile → Đăng xuất
