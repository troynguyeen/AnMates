# Bug History

---

## 2026-05-24 — Auth screen: không login được (SĐT, Facebook, Apple, Google)

### Triệu chứng
- Nhập số điện thoại → bấm "Gửi mã xác minh" → màn hình OTP hiện ra nhưng gửi đi không có gì
- Nhập 6 chữ số bất kỳ trên OTP screen → app cho vào luôn, không verify gì
- Bấm "Tiếp tục với Facebook / Apple / Google" → không có phản ứng gì

---

### Bug 1 — Phone/OTP flow: UI mock, không gọi backend

**File:** `lib/views/auth/auth_view.dart` → `_sendOtp()`

**Root cause:**  
Hàm `_sendOtp()` chỉ navigate sang `OtpView` mà không gọi bất kỳ API nào. Không có SMS được gửi, không có OTP nào được tạo phía backend.

```dart
// Code cũ (broken)
void _sendOtp() {
  final phone = '+84 ${_phoneCtrl.text.trim()}';
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => OtpView(onVerified: widget.onAuthenticated, phone: phone),
  ));
  // ← không có HTTP call nào
}
```

**Nguyên nhân sâu hơn:**  
Backend Go (`handlers/auth.go`) chỉ có endpoint email+password:
- `POST /api/auth/register` — nhận `{email, password, name}`
- `POST /api/auth/login` — nhận `{email, password}`

Không có endpoint OTP hay SMS nào cả. Flutter UI hiển thị phone login nhưng backend không hỗ trợ.

**Fix:** Thay phone input → email + password fields. Gọi `AuthService().login()` / `AuthService().register()` thật sự.

---

### Bug 2 — OtpView: chấp nhận bất kỳ 6 chữ số, không verify

**File:** `lib/views/auth/otp_view.dart` → `_onKeyTap()`

**Root cause:**  
OTP screen là UI mock hoàn toàn. Khi đủ 6 chữ số, nó gọi `onVerified()` ngay lập tức:

```dart
// Code cũ (broken)
if (_digits.every((d) => d.isNotEmpty)) {
  Future.delayed(const Duration(milliseconds: 200), () {
    if (mounted) {
      Navigator.pop(context);
      widget.onVerified();  // ← gọi thẳng, không verify với server
    }
  });
}
```

Thêm vào đó, `_activeIndex` là `final int _activeIndex = 3` (hardcoded, không thay đổi khi gõ phím) và digits khởi tạo sẵn `['1', '4', '2', '', '', '']`.

**Fix:** OTP screen không còn cần thiết khi đã dùng email+password flow. Đã xoá navigation tới OtpView.

---

### Bug 3 — Social login buttons: onTap rỗng

**File:** `lib/views/auth/auth_view.dart` → 3 `_SocialButton` widgets

**Root cause:**  
Cả 3 nút đều có `onTap: () {}` — empty lambda, không làm gì:

```dart
// Code cũ (broken)
_SocialButton(
  label: 'Tiếp tục với Facebook',
  onTap: () {},   // ← không làm gì
),
_SocialButton(
  label: 'Tiếp tục với Apple',
  onTap: () {},   // ← không làm gì
),
_SocialButton(
  label: 'Tiếp tục với Google',
  onTap: () {},   // ← không làm gì
),
```

Không có OAuth SDK nào được tích hợp (`firebase_auth`, `google_sign_in`, v.v. đều vắng mặt trong `pubspec.yaml`).

**Fix:** Hiện SnackBar "Đăng nhập [Provider] sắp ra mắt 🚀" để user biết tính năng đang phát triển, thay vì im lặng hoàn toàn.

---

### Bug 4 — `auth_service._saveTokens()`: đọc sai key cho user_id

**File:** `lib/services/auth_service.dart` → `_saveTokens()`

**Root cause:**  
Hàm tìm `data['user_id']` (flat key) nhưng backend trả về user ID trong nested object:

```json
// Backend response structure
{
  "data": {
    "access_token": "...",
    "refresh_token": "...",
    "user": {
      "id": "abc-123",    ← đây mới là user_id
      "name": "...",
      "email": "..."
    }
  }
}
```

```dart
// Code cũ (broken)
if (data['user_id'] != null) {   // ← luôn null, không bao giờ match
  await prefs.setString('user_id', data['user_id'] as String);
}
```

Hậu quả: `user_id` không bao giờ được lưu vào `SharedPreferences`. Bất kỳ tính năng nào cần `AuthService().currentUserId()` đều trả về `null`.

**Fix:**
```dart
// Code mới (fixed)
final userId = data['user_id'] as String? ??
    (data['user'] as Map<String, dynamic>?)?['id'] as String?;
if (userId != null) {
  await prefs.setString('user_id', userId);
}
```

---

### Thay đổi files

| File | Thay đổi |
|------|----------|
| `lib/views/auth/auth_view.dart` | Rewrite: phone → email+password, gọi AuthService thật, social → snackbar |
| `lib/services/auth_service.dart` | Fix `_saveTokens`: đọc `data['user']['id']` thay vì `data['user_id']` |
| `lib/views/auth/otp_view.dart` | Không sửa (không còn được navigate tới) |

---

## Cách test

### Đăng ký tài khoản mới
1. Mở app → bấm "Đăng ký ngay"
2. Nhập Name, Email, Password (≥10 ký tự)
3. Bấm "Tạo tài khoản" → phải vào được app

### Đăng nhập
1. Nhập email + password đã đăng ký
2. Bấm "Đăng nhập" → phải vào được app

### Social login
1. Bấm Facebook/Apple/Google → phải hiện SnackBar "sắp ra mắt"

### Lỗi thường gặp sau khi fix
- **"invalid credentials"** → sai email hoặc password
- **"email already registered"** → email đã tồn tại, dùng "Đăng nhập" thay vì "Đăng ký"
- **"name required; valid email; password >= 10 chars"** → password quá ngắn hoặc email sai format
- **Network error** → backend chưa chạy, kiểm tra `docker compose up` và health check tại `http://localhost:8080/health`
