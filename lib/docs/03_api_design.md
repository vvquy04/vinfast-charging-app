# 03 — Thiết kế API (API Design)

> Tài liệu mô tả các REST API endpoint mà Flutter client gọi tới Spring Boot backend.
> Base URL: `http://<server-ip>:8080/api`

---

## 1. Quy ước chung

| Mục | Quy tắc |
|-----|---------|
| **Giao thức** | HTTP (REST) — JSON body |
| **Đường dẫn** | Dùng **kebab-case** hoặc **camelCase** tuỳ convention của Spring |
| **HTTP Methods** | `GET` = đọc, `POST` = tạo mới, `PUT` = cập nhật, `DELETE` = xóa |
| **Authentication** | JWT Bearer Token (gửi trong header `Authorization: Bearer <token>`) |
| **Content-Type** | `application/json` |
| **Mã trạng thái** | `200` OK · `201` Created · `400` Bad Request · `401` Unauthorized · `404` Not Found · `500` Server Error |

### Format response thành công

```json
{
  "success": true,
  "data": { ... },
  "message": "Thành công"
}
```

### Format response lỗi

```json
{
  "success": false,
  "data": null,
  "message": "Mô tả lỗi"
}
```

---

## 2. Nhóm API

### 2.1 Authentication (`/api/auth`)

| Method | Endpoint | Mô tả | Auth |
|--------|----------|--------|------|
| `POST` | `/api/auth/register` | Đăng ký tài khoản mới | ❌ |
| `POST` | `/api/auth/login` | Đăng nhập, nhận JWT token | ❌ |

#### `POST /api/auth/register`

```json
// Request body
{
  "fullName": "Nguyễn Văn A",
  "phoneNumber": "0901234567",
  "password": "matkhau123",
  "email": "user@example.com",       // optional
  "vehicleModel": "VF8",             // optional
  "connectorType": "CCS2"            // optional
}

// Response 201
{
  "success": true,
  "data": {
    "userId": 1,
    "fullName": "Nguyễn Văn A",
    "phoneNumber": "0901234567",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  },
  "message": "Đăng ký thành công"
}
```

#### `POST /api/auth/login`

```json
// Request body
{
  "phoneNumber": "0901234567",
  "password": "matkhau123"
}

// Response 200
{
  "success": true,
  "data": {
    "userId": 1,
    "fullName": "Nguyễn Văn A",
    "phoneNumber": "0901234567",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  },
  "message": "Đăng nhập thành công"
}
```

---

### 2.2 User Profile (`/api/users`)

| Method | Endpoint | Mô tả | Auth |
|--------|----------|--------|------|
| `GET` | `/api/users/me` | Lấy thông tin user hiện tại | ✅ |
| `PUT` | `/api/users/me` | Cập nhật thông tin cá nhân | ✅ |

#### `GET /api/users/me`

```json
// Response 200
{
  "success": true,
  "data": {
    "userId": 1,
    "fullName": "Nguyễn Văn A",
    "phoneNumber": "0901234567",
    "email": "user@example.com",
    "gender": "MALE",
    "dateOfBirth": "1995-10-20",
    "avatarUrl": "https://example.com/avatar.jpg",
    "vehicleModel": "VF8",
    "connectorType": "CCS2",
    "createdAt": "2026-01-15T08:30:00"
  }
}
```

---

### 2.3 Charging Stations (`/api/stations`)

| Method | Endpoint | Mô tả | Auth |
|--------|----------|--------|------|
| `GET` | `/api/stations` | Lấy danh sách trạm sạc (có filter) | ❌ |
| `GET` | `/api/stations/{id}` | Lấy chi tiết 1 trạm (kèm connector_types) | ❌ |
| `GET` | `/api/stations/nearby` | Tìm trạm gần vị trí hiện tại | ❌ |

#### `GET /api/stations` — Query Parameters

| Param | Kiểu | Mô tả |
|-------|------|-------|
| `lat` | double | Vĩ độ người dùng (để tính khoảng cách) |
| `lng` | double | Kinh độ người dùng |
| `radius` | int | Bán kính tìm kiếm (km), mặc định `10` |
| `connectorType` | string | Lọc theo loại cổng sạc: `AC`, `DC`, `CCS2`... |
| `keyword` | string | Tìm kiếm theo tên hoặc địa chỉ trạm |
| `page` | int | Trang hiện tại (phân trang), mặc định `0` |
| `size` | int | Số bản ghi mỗi trang, mặc định `20` |

#### `GET /api/stations/{id}`

```json
// Response 200
{
  "success": true,
  "data": {
    "stationId": 1,
    "name": "Trạm sạc VinFast Vincom Bà Triệu",
    "address": "191 Bà Triệu, Hai Bà Trưng, Hà Nội",
    "latitude": 21.0115,
    "longitude": 105.8490,
    "openingHours": "24/7",
    "imageUrl": "https://...",
    "rating": 4.5,
    "totalReviews": 128,
    "connectorTypes": [
      { "connectorId": 1, "type": "CCS2", "powerKw": 150, "totalPorts": 4 },
      { "connectorId": 2, "type": "AC",   "powerKw": 11,  "totalPorts": 2 }
    ]
  }
}
```

---

### 2.4 Reviews (`/api/reviews`)

| Method | Endpoint | Mô tả | Auth |
|--------|----------|--------|------|
| `GET` | `/api/stations/{stationId}/reviews` | Lấy danh sách đánh giá của trạm | ❌ |
| `POST` | `/api/stations/{stationId}/reviews` | Tạo đánh giá mới | ✅ |
| `DELETE` | `/api/reviews/{reviewId}` | Xoá đánh giá (chỉ chủ sở hữu) | ✅ |

#### `POST /api/stations/{stationId}/reviews`

```json
// Request body
{
  "rating": 5,
  "comment": "Trạm sạc nhanh, sạch sẽ, nhân viên thân thiện."
}

// Response 201
{
  "success": true,
  "data": {
    "reviewId": 42,
    "userId": 1,
    "stationId": 1,
    "rating": 5,
    "comment": "Trạm sạc nhanh, sạch sẽ, nhân viên thân thiện.",
    "createdAt": "2026-04-08T10:30:00"
  },
  "message": "Đánh giá thành công"
}
```

---

### 2.5 User Station History (`/api/history`)

| Method | Endpoint | Mô tả | Auth |
|--------|----------|--------|------|
| `GET` | `/api/history` | Lấy lịch sử trạm đã xem (của user hiện tại) | ✅ |
| `POST` | `/api/history/{stationId}` | Ghi nhận/cập nhật lượt xem trạm | ✅ |

---

## 3. Xử lý lỗi phía Client

| Mã | Xử lý |
|----|--------|
| `401` | Token hết hạn → chuyển về màn hình đăng nhập |
| `400` | Hiển thị thông báo lỗi từ `message` |
| `404` | Hiển thị "Không tìm thấy dữ liệu" |
| `500` | Hiển thị "Lỗi hệ thống, vui lòng thử lại" |
| Network Error | Hiển thị "Không có kết nối mạng" |

---

## 4. Lưu ý khi triển khai

1. **JWT Token** được lưu trong `SharedPreferences` (hoặc `flutter_secure_storage`) và gắn vào mỗi request qua `Dio Interceptor`.
2. **Pagination** sử dụng `page` + `size` — client tự quản lý load more.
3. **Tên trường JSON** sử dụng **camelCase** — Dart model dùng `json_serializable` hoặc parse thủ công.
4. Khi backend chưa sẵn sàng, có thể mock data tại tầng `services/` để phát triển UI song song.
