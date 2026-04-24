# 06 — Hướng dẫn cho AI (AI Instructions)

> File này cung cấp ngữ cảnh cho các công cụ AI khi hỗ trợ viết code cho dự án.

---

## Thông tin dự án

- **Tên:** VinFast Charging Station Finder
- **Loại:** Ứng dụng di động (Flutter) — Đồ án tốt nghiệp
- **Mục đích:** Giúp người dùng xe điện VinFast tìm kiếm và đánh giá trạm sạc
- **Ngôn ngữ:** Dart (Flutter) cho client, Java (Spring Boot) cho backend
- **Database:** MySQL

---

## Kiến trúc (3 lớp)

```
lib/
├── core/           → Constants, utils, shared widgets
├── data/           → Models, API services, repositories
├── presentation/   → Screens, providers
└── main.dart
```

**Phụ thuộc:** `Presentation → Data → Core` (không ngược).

---

## Quy tắc AI cần tuân thủ

1. **Đặt file đúng thư mục** theo kiến trúc.
2. **Mỗi file 1 class public.** Tên file = `snake_case.dart`.
3. **Class = PascalCase**, biến/hàm = `camelCase`.
4. Dùng `const` constructor, `final`, `async/await`.
5. **Xử lý lỗi** `try-catch` khi gọi API.
6. **KHÔNG** `print()` → dùng `debugPrint()`.
7. Tách widget > 150 dòng thành widget nhỏ hơn.
8. HTTP client: `Dio` + interceptor JWT.
9. JSON fields: **camelCase**.

---

## Database (5 bảng)

`users` · `charging_stations` · `connector_types` · `reviews` · `user_station_history`

→ Chi tiết: [02_database.md](./02_database.md)

---

## API Endpoints

| Nhóm | Path | Chức năng |
|------|------|-----------|
| Auth | `/api/auth/` | Đăng ký, đăng nhập |
| Users | `/api/users/` | Profile |
| Stations | `/api/stations/` | CRUD trạm, tìm kiếm |
| Reviews | `/api/stations/{id}/reviews` | Đánh giá |
| History | `/api/history/` | Lịch sử xem trạm |

→ Chi tiết: [03_api_design.md](./03_api_design.md)

---

## Lưu ý quan trọng

- **Code:** tiếng Anh. **UI text:** tiếng Việt.
- Không hardcode URL, màu, chuỗi → `core/constants/`.
- Mọi màn hình cần trạng thái: Loading, Success, Error, Empty.
- Commit format: `<type>: <mô tả>` → [05_git_workflow.md](./05_git_workflow.md)
