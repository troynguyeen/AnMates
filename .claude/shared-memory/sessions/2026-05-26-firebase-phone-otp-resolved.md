# Session: Firebase Phone OTP — `INVALID_APP_CREDENTIAL` RESOLVED + Best-Practice Refactor

**Date:** 2026-05-26
**Type:** Bug fix + refactor (closes BLOCKER-001)
**Operator:** main assistant (chat session)
**User confirmation:** "Đã test done" — phone OTP gửi/verify thành công trên web localhost.

---

## TL;DR

`INVALID_APP_CREDENTIAL` trên web localhost được fix bằng **2 thay đổi config phía Firebase Console + browser URL** (không phải code):

1. Thêm `127.0.0.1` vào **Firebase Console → Authentication → Settings → Authorized domains** (`localhost` đã có sẵn nhưng không đủ).
2. Truy cập app qua `http://127.0.0.1:<PORT>` thay vì `http://localhost:<PORT>` — reCAPTCHA token issued cho domain nào thì Firebase chỉ accept cho domain đó.

Sau khi fix xong, code Flutter được refactor lại theo Firebase Phone Auth docs để bền vững hơn.

---

## Root Cause (đầy đủ)

### Endpoint thực sự fail
`POST https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode` — gọi từ Flutter Web client **trước khi** chạm tới Go backend `/api/auth/phone-verify`.

### Cơ chế Firebase verify "app credential" theo platform

| Platform | Cơ chế | Cần config |
|----------|--------|-----------|
| **Web** | reCAPTCHA (visible v2 hoặc invisible) — token gắn với domain origin | Authorized domains chứa domain hiện tại |
| **Android** | Play Integrity API hoặc SafetyNet — auto qua Google Play Services | SHA-1/SHA-256 fingerprint đăng ký Firebase |
| **iOS** | Silent push qua APNs; fallback reCAPTCHA URL scheme | APNs Auth Key (.p8) upload Firebase + `aps-environment` entitlement |

### Tại sao `localhost` không work nhưng `127.0.0.1` work
- Browser issue reCAPTCHA token gắn với **origin** chính xác (scheme + host + port).
- `localhost` và `127.0.0.1` là 2 origin khác nhau ở góc nhìn của reCAPTCHA/Firebase.
- Firebase Console mặc định pre-authorize `localhost`, nhưng KHÔNG pre-authorize `127.0.0.1`.
- Khi browser mở `127.0.0.1:PORT`, reCAPTCHA gửi token với `referer=127.0.0.1` → Firebase Identity Toolkit không thấy domain này trong allow-list → trả `INVALID_APP_CREDENTIAL`.

### Tại sao user phải dùng `127.0.0.1` thay vì `localhost`
- Trên macOS/Linux một số trường hợp Flutter web dev server bind vào `127.0.0.1` interface chứ không phải `localhost` alias.
- Chrome dev tooling đôi khi resolve `localhost` → IPv6 `::1`, gây mismatch với reCAPTCHA expectation.
- Cách an toàn nhất là align toàn bộ — đăng ký `127.0.0.1` ở Firebase Console + truy cập qua `127.0.0.1`.

---

## Solution (3 bước)

### Bước 1 — Firebase Console (ONE-TIME)

```
https://console.firebase.google.com/project/anmates-studio
→ Authentication → Settings → Authorized domains → Add domain
  - localhost     (mặc định có)
  - 127.0.0.1     ← THÊM MỚI
  - anmates-studio.firebaseapp.com  (mặc định có)
  - <production domain khi deploy>
```

Đồng thời confirm:
- Authentication → Sign-in method → **Phone** = Enabled
- Settings ⚙️ → Usage & billing = **Blaze plan** (bắt buộc từ Sept 2023)

### Bước 2 — Truy cập app

```bash
cd AnMatesApp/anmates_flutter
flutter run -d chrome --web-port=54180
# rồi mở browser tại:
http://127.0.0.1:54180
```

**KHÔNG dùng** `http://localhost:54180` — sẽ lại bị `INVALID_APP_CREDENTIAL`.

### Bước 3 — Code refactor theo Firebase best practices (DONE trong session này)

Xem mục Files Changed bên dưới.

---

## Files Changed

| File | Mục đích |
|------|---------|
| [lib/main.dart](../../../anmates_flutter/lib/main.dart) | `Firebase.initializeApp()` trước `runApp()` — bỏ lazy init |
| [lib/views/auth/phone_input_view.dart](../../../anmates_flutter/lib/views/auth/phone_input_view.dart) | `RecaptchaVerifier` stored as state field; lifecycle (`_clearVerifier`/`_buildVerifier`); `onError`/`onExpired` callbacks; tách `_sendOtpWeb`/`_sendOtpMobile` |
| [lib/views/auth/otp_view.dart](../../../anmates_flutter/lib/views/auth/otp_view.dart) | Web resend dùng explicit `RecaptchaVerifier`; tách `_resendWeb`/`_resendMobile`; extract `_resetOnError`/`_clearDigits`/`_replaceWith` |
| [lib/views/auth/auth_error_messages.dart](../../../anmates_flutter/lib/views/auth/auth_error_messages.dart) | **NEW** — central mapping Firebase error code → user message, dùng chung 2 views |
| [lib/services/api_client.dart](../../../anmates_flutter/lib/services/api_client.dart) | `wsUrl()` derive từ `API_BASE_URL` (bỏ hardcode `ws://192.168.1.216:8080`) |
| [pubspec.yaml](../../../anmates_flutter/pubspec.yaml) | Thêm `firebase_auth_platform_interface: ^8.0.0` explicit dep (cần cho `FirebaseAuthPlatform.instance` trong `RecaptchaVerifier.auth`) |

---

## Best-Practice Patterns (cho future feature work)

### Pattern 1 — Init Firebase once at app startup

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(...);
}
```

KHÔNG dùng lazy `_ensureFirebase()` pattern trong widget — tạo race condition khi hot reload.

### Pattern 2 — RecaptchaVerifier lifecycle (web phone auth)

```dart
RecaptchaVerifier? _verifier;

@override
void dispose() {
  _verifier?.clear();   // release DOM widget
  super.dispose();
}

Future<void> _sendOtpWeb(String phone) async {
  _verifier?.clear();           // clear cũ (nếu có)
  _verifier = RecaptchaVerifier(
    auth: FirebaseAuthPlatform.instance,
    container: 'recaptcha-container',     // match #id trong web/index.html
    size: RecaptchaVerifierSize.normal,
    theme: RecaptchaVerifierTheme.light,
    onError: (e) { /* show error */ },
    onExpired: () { /* clear + re-init */ },
  );
  final result = await FirebaseAuth.instance.signInWithPhoneNumber(phone, _verifier!);
  // ...navigate to OTP view with `result`
}
```

Per Firebase docs: verifier **chỉ dùng 1 lần** — retry phải tạo mới sau khi `clear()`.

### Pattern 3 — Split web vs mobile flow

```dart
Future<void> _sendOtp() async {
  if (kIsWeb) {
    await _sendOtpWeb(phone);    // signInWithPhoneNumber → ConfirmationResult
  } else {
    await _sendOtpMobile(phone); // verifyPhoneNumber → verificationId via callbacks
  }
}
```

Web và mobile dùng 2 API hoàn toàn khác nhau — KHÔNG cố gắng abstract chung.

### Pattern 4 — Central error message mapping

```dart
// lib/views/auth/auth_error_messages.dart
String friendlyPhoneAuthError(String code) {
  switch (code) {
    case 'invalid-phone-number': return 'Số điện thoại không hợp lệ.';
    case 'invalid-app-credential': return 'App chưa được uỷ quyền. Liên hệ hỗ trợ.';
    case 'too-many-requests': return 'Quá nhiều yêu cầu. Thử lại sau vài phút.';
    // ...
    default: return 'Không xác thực được ($code).';
  }
}
```

Mọi auth view dùng chung — đổi message 1 nơi áp dụng cho cả app.

---

## Verification

```bash
cd AnMatesApp/anmates_flutter
flutter pub get                    # ✓ resolves
flutter analyze lib/views/auth/    # ✓ No issues found
flutter build web                  # ✓ Built build/web
```

User manual test: **OTP gửi và verify thành công trên web localhost (qua 127.0.0.1).**

---

## Open Follow-ups

1. **Android real-phone test** — cần đăng ký SHA-1/SHA-256 keystore release lên Firebase (debug đã có theo session `2026-05-25-otp-real-phone-checklist.md`).
2. **iOS real-phone test** — cần upload APNs Auth Key (.p8) lên Firebase Console + thêm `aps-environment` entitlement + `CFBundleURLTypes` cho reCAPTCHA fallback.
3. **Production web domain** — khi deploy phải add prod domain vào Authorized domains.
4. **Backend Go improvement** (optional) — `verifyFirebaseToken` đang dùng `accounts:lookup` (chỉ kiểm tra token valid trên server). Nên đổi sang Firebase Admin SDK để verify chữ ký JWT cục bộ — nhanh hơn, an toàn hơn, không cần round-trip với Google mỗi lần verify.

---

## Key Facts to Remember

- **`INVALID_APP_CREDENTIAL` ≠ backend bug** — luôn là client-side app verification fail (reCAPTCHA web / SHA Android / APNs iOS).
- **`127.0.0.1` ≠ `localhost`** ở góc nhìn reCAPTCHA — phải add cả 2 vào Authorized domains nếu support cả 2 cách truy cập.
- **Firebase Phone Auth từ Sept 2023 yêu cầu Blaze plan** — Spark plan sẽ trả error.
- **`RecaptchaVerifier` chỉ dùng 1 lần** — phải `clear()` trước khi tạo mới.
- **`firebase_auth_platform_interface`** phải khai báo explicit trong pubspec để dùng `FirebaseAuthPlatform.instance` (transitive dep từ `firebase_auth` không đủ).
