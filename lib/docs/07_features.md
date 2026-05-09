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
| A1 | Đăng ký | Tạo tài khoản qua SĐT + OTP (nhập họ tên, email, mật khẩu, xe, cổng sạc) | 🔴 Cao |
| A2 | Đăng nhập | Đăng nhập bằng SĐT + mật khẩu hoặc Google OAuth | 🔴 Cao |
| A3 | Đăng xuất | Xoá token, quay về màn login | 🔴 Cao |
| A4 | Lưu phiên đăng nhập | Tự đăng nhập lại khi mở app (token trong SharedPreferences) | 🟡 Trung bình |

### 2.2 🗺️ Bản đồ (Map) — `screens/map/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| M1 | Hiển thị bản đồ | Bản đồ OpenStreetMap toàn màn hình | 🔴 Cao |
| M2 | Hiển thị trạm sạc | Marker cho các trạm sạc trên bản đồ | 🔴 Cao |
| M3 | Vị trí hiện tại | Lấy & hiển thị vị trí GPS của người dùng | 🔴 Cao |
| M4 | Tap marker | Nhấn marker → popup tóm tắt trạm → nhấn tiếp → chi tiết | 🔴 Cao |

### 2.3 🔍 Tìm kiếm & Lọc (Search) — `screens/search/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| S1 | Tìm kiếm tên/địa chỉ | Nhập keyword, hiển thị kết quả gợi ý | 🔴 Cao |
| S2 | Lọc theo cổng sạc | Chọn loại cổng (AC, DC, CCS2, CHAdeMO, Type2) | 🔴 Cao |
| S3 | Lọc theo công suất sạc | Chọn công suất tối thiểu (7, 22, 50, 100, 150, 250, 350 kW) | 🔴 Cao |
| S4 | Lọc theo đánh giá | Chọn rating tối thiểu (1–5 ⭐) | 🔴 Cao |

### 2.4 📋 Chi tiết trạm (Detail) — `screens/detail/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| D1 | Thông tin trạm | Tên, địa chỉ, giờ mở cửa, hình ảnh | 🔴 Cao |
| D2 | Danh sách cổng sạc | Loại cổng, công suất (kW), số cổng khả dụng | 🔴 Cao |
| D3 | Điểm đánh giá | Hiển thị rating trung bình + tổng review | 🔴 Cao |
| D4 | Danh sách review | Xem đánh giá từ người dùng khác | 🔴 Cao |

### 2.5 ⭐ Đánh giá (Review) — `screens/review/`

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| R1 | Viết đánh giá | Chọn số sao (1–5) + viết comment | 🔴 Cao |

### 2.6 👤 Hồ sơ người dùng (Profile)

| # | Tính năng | Mô tả | Ưu tiên |
|---|-----------|-------|---------|
| P1 | Xem thông tin | Xem Ảnh đại diện, Họ tên, email, Giới tính, dòng xe, cổng sạc | 🟡 Trung bình |
| P2 | Sửa thông tin | Cập nhật ảnh đại diện, Họ tên, email, Giới tính, dòng xe, cổng sạc | 🟡 Trung bình |
| P3 | Xem Lịch sử trạm | Danh sách trạm đã xem gần đây | 🟢 Thấp |
| P4 | Xóa Lịch sử trạm | Xóa từng bản ghi lịch sử xem trạm | 🟢 Thấp |

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
