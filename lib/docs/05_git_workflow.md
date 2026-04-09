# 05 — Git Workflow

> Tài liệu quy định quy trình làm việc với Git cho dự án đồ án tốt nghiệp.

---

## 1. Chiến lược phân nhánh (Branching Strategy)

Dự án sử dụng mô hình **Git Flow đơn giản** với 3 loại branch:

```
main ─────────────────────────────────── (code ổn định, production-ready)
  │
  └── develop ────────────────────────── (branch làm việc hàng ngày)
        │
        ├── feature/map-screen ────────  (tính năng mới)
        ├── feature/auth-login ────────
        └── fix/station-rating-bug ────  (sửa lỗi)
```

| Branch | Mục đích | Tạo từ | Merge vào |
|--------|----------|--------|-----------|
| `main` | Code ổn định, đã test | — | — |
| `develop` | Branch phát triển chính | `main` | `main` |
| `feature/<tên>` | Phát triển tính năng mới | `develop` | `develop` |
| `fix/<tên>` | Sửa lỗi | `develop` | `develop` |

### Quy tắc

- **Không bao giờ commit trực tiếp vào `main`** — chỉ merge từ `develop` khi tính năng hoàn chỉnh.
- **`develop`** là branch làm việc chính — pull mới nhất trước khi tạo feature branch.
- **Feature branch** đặt tên rõ ràng, dùng **kebab-case**: `feature/station-detail`, `feature/search-filter`.
- Xong feature → merge vào `develop` → xoá feature branch.

---

## 2. Quy tắc viết Commit Message

### Format

```
<type>: <mô tả ngắn gọn bằng tiếng Anh>
```

### Các type phổ biến

| Type | Ý nghĩa | Ví dụ |
|------|---------|-------|
| `feat` | Thêm tính năng mới | `feat: add station map screen` |
| `fix` | Sửa lỗi | `fix: correct haversine distance calculation` |
| `refactor` | Tái cấu trúc code (không thay đổi logic) | `refactor: split scoring logic into utils` |
| `style` | Format code, sửa lỗi chính tả (không thay đổi logic) | `style: format dart files` |
| `chore` | Cấu hình, setup, dependency | `chore: add dio and flutter_map dependencies` |
| `docs` | Cập nhật tài liệu | `docs: update API design documentation` |
| `test` | Thêm hoặc sửa test | `test: add unit test for StationRepository` |

### Quy tắc

- **Mô tả bằng tiếng Anh**, viết thường, không dấu chấm cuối câu.
- **Tối đa 72 ký tự** cho dòng đầu tiên.
- Nếu cần giải thích thêm, xuống dòng 2 lần rồi viết body:

```
feat: add station detail screen with connector info

- Display station name, address, rating
- Show list of available connector types
- Add navigation button to open map directions
```

---

## 3. Quy trình làm việc hàng ngày

### 3.1 Bắt đầu tính năng mới

```bash
# 1. Cập nhật develop
git checkout develop
git pull origin develop

# 2. Tạo feature branch
git checkout -b feature/station-detail

# 3. Code & commit thường xuyên
git add .
git commit -m "feat: add station detail screen layout"
git commit -m "feat: integrate station API into detail screen"

# 4. Push lên remote
git push origin feature/station-detail
```

### 3.2 Hoàn thành tính năng

```bash
# 1. Cập nhật develop mới nhất
git checkout develop
git pull origin develop

# 2. Merge feature vào develop
git merge feature/station-detail

# 3. Giải quyết conflict (nếu có), rồi commit

# 4. Push develop
git push origin develop

# 5. Xoá feature branch (tuỳ chọn)
git branch -d feature/station-detail
git push origin --delete feature/station-detail
```

### 3.3 Merge develop vào main (milestone)

Chỉ merge khi một nhóm tính năng **đã hoàn chỉnh và test**:

```bash
git checkout main
git pull origin main
git merge develop
git push origin main
```

---

## 4. Quy tắc .gitignore

Các file/thư mục KHÔNG commit:

```
# IDE
.idea/
.vscode/
*.iml

# Flutter/Dart
.dart_tool/
build/
.flutter-plugins
.flutter-plugins-dependencies

# OS
.DS_Store
Thumbs.db

# Environment
.env
*.env.local
```

---

## 5. Checklist trước khi commit

- [ ] Code biên dịch thành công (`flutter analyze`)
- [ ] Đã format code (`dart format .`)
- [ ] Commit message đúng format `<type>: <mô tả>`
- [ ] Không commit file nhạy cảm (API key, password, .env)
- [ ] Không commit file build/generated
