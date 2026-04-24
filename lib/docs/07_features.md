# 07 — Danh sách tính năng (Features)

> Tài liệu liệt kê các tính năng của ứng dụng, chia theo nhóm và mức độ ưu tiên.

---

## 1. Tổng quan

Ứng dụng **VinFast Charging Station Finder** giúp người dùng xe điện VinFast:
- Tìm trạm sạc gần nhất trên bản đồ
- Xem chi tiết trạm (loại cổng sạc, công suất, giờ mở cửa)
- Đánh giá và đọc review từ người dùng khác
- Lọc trạm theo loại cổng sạc phù hợp xe của mình

---

## 2. Tính năng theo Module

### 2.1 🔐 Xác thực (Auth) — `screens/auth/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| A1 | Đăng ký | Tạo tài khoản: avatar, email, mật khẩu, họ tên, SĐT, model xe, cổng sạc | 🔴 Cao |
| A2 | Đăng nhập | Đăng nhập bằng email + mật khẩu, nhận JWT token | 🔴 Cao |
| A3 | Đăng xuất | Xoá token, quay về màn login | 🔴 Cao |
| A4 | Lưu phiên đăng nhập | Tự đăng nhập lại khi mở app (token trong SharedPreferences) | 🟡 Trung bình |

### 2.2 🗺️ Bản đồ (Map) — `screens/map/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| M1 | Hiển thị bản đồ | Bản đồ OpenStreetMap toàn màn hình | 🔴 Cao |
| M2 | Hiển thị trạm sạc | Marker cho các trạm sạc trên bản đồ | 🔴 Cao |
| M3 | Vị trí hiện tại | Lấy & hiển thị vị trí GPS của người dùng | 🔴 Cao |
| M4 | Tap marker | Nhấn marker → popup tóm tắt trạm → nhấn tiếp → chi tiết | 🔴 Cao |
| M5 | Chỉ đường | Mở Google Maps/Apple Maps để chỉ đường đến trạm | 🟡 Trung bình |

### 2.3 🔍 Tìm kiếm & Lọc (Search) — `screens/search/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| S1 | Tìm kiếm tên/địa chỉ | Nhập keyword, hiển thị kết quả phù hợp | 🔴 Cao |
| S2 | Lọc theo cổng sạc | Chọn AC, DC, CCS2, CHAdeMO, Type2 | 🔴 Cao |
| S3 | Lọc theo khoảng cách | Chọn bán kính: 5km, 10km, 20km, 50km | 🟡 Trung bình |
| S4 | Sắp xếp kết quả | Theo khoảng cách, rating, số lượng review | 🟡 Trung bình |

### 2.4 📋 Chi tiết trạm (Detail) — `screens/detail/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| D1 | Thông tin trạm | Tên, địa chỉ, giờ mở cửa, hình ảnh | 🔴 Cao |
| D2 | Danh sách cổng sạc | Loại cổng, công suất (kW), số cổng khả dụng | 🔴 Cao |
| D3 | Điểm đánh giá | Hiển thị rating trung bình + tổng review | 🔴 Cao |
| D4 | Danh sách review | Xem đánh giá từ người dùng khác | 🔴 Cao |
| D5 | Nút chỉ đường | Mở bản đồ bên ngoài → dẫn đến trạm | 🟡 Trung bình |

### 2.5 ⭐ Đánh giá (Review) — `screens/review/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| R1 | Viết đánh giá | Chọn số sao (1–5) + viết comment | 🔴 Cao |
| R2 | Xoá đánh giá | Xoá đánh giá do mình viết | 🟡 Trung bình |

### 2.6 👤 Hồ sơ người dùng (Profile)

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| P1 | Xem thông tin | Ảnh đại diện, Họ tên, email, SĐT, model xe, cổng sạc | 🟡 Trung bình |
| P2 | Sửa thông tin | Cập nhật ảnh đại diện, Họ tên, SĐT, model xe, cổng sạc | 🟡 Trung bình |
| P3 | Lịch sử xem trạm | Danh sách trạm đã xem gần đây | 🟢 Thấp |

---

## 3. Roadmap phát triển

### Phase 1 — MVP (Minimum Viable Product)

Hoàn thành các tính năng **🔴 Ưu tiên Cao**:
- ✅ Auth (đăng ký, đăng nhập, đăng xuất)
- ✅ Bản đồ + hiển thị trạm sạc
- ✅ Tìm kiếm cơ bản + lọc cổng sạc
- ✅ Chi tiết trạm + danh sách review
- ✅ Viết đánh giá

### Phase 2 — Nâng cao

Hoàn thành các tính năng **🟡 Trung bình**:
- Lưu phiên đăng nhập
- Chỉ đường đến trạm
- Lọc nâng cao (khoảng cách, sắp xếp)
- Profile + sửa thông tin

### Phase 3 — Bổ sung

- Lịch sử xem trạm
- UI/UX polish (animation, dark mode)
- Offline caching (lưu dữ liệu trạm đã xem)
