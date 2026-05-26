# Blockers

Open blockers that need team-leader to resolve or escalate to the user.

## Template

```
## BLOCKER-NNN: <title>
**Raised by:** <agent>
**Date:** YYYY-MM-DD HH:MM
**Status:** open | resolved

### Problem
<what is blocking>

### Suggested fix
<what to try next>
```

---

## BLOCKER-001: `INVALID_APP_CREDENTIAL` cần Firebase Console access
**Raised by:** team-leader
**Date:** 2026-05-25 22:50
**Status:** **resolved (web)** — 2026-05-26
**Resolved by:** main assistant

### Problem
App AnMates (Flutter) gọi Firebase Phone Auth (`verifyPhoneNumber` / `signInWithPhoneNumber`) bị Google Identity Toolkit từ chối với HTTP 400 `INVALID_APP_CREDENTIAL`. Code Flutter đúng, root cause là config phía Firebase Console:
- Android: chưa có SHA-1/SHA-256 fingerprint nào được đăng ký (`google-services.json` có `oauth_client: []` rỗng).
- iOS: chưa upload APNs Auth Key (.p8) lên Firebase, app không nhận được silent push để verify.
- Web: domain phục vụ Flutter web có thể chưa nằm trong Authorized domains.

### Resolution (web)
User thêm `127.0.0.1` vào Firebase Console → Authentication → Settings → Authorized domains, sau đó truy cập app qua `http://127.0.0.1:PORT` (KHÔNG dùng `localhost:PORT` — `localhost` và `127.0.0.1` là 2 origin khác nhau ở góc nhìn của reCAPTCHA token).

Code Flutter sau đó được refactor theo Firebase docs: init Firebase ở `main()`, `RecaptchaVerifier` lifecycle với `clear()`, central error mapping `auth_error_messages.dart`, `wsUrl` derive từ `API_BASE_URL`.

Detail: [sessions/2026-05-26-firebase-phone-otp-resolved.md](sessions/2026-05-26-firebase-phone-otp-resolved.md).

### Remaining (Android + iOS, future)
- Android real-phone test: cần đăng ký SHA-1/SHA-256 release keystore (debug đã có).
- iOS real-phone test: cần upload APNs Auth Key (.p8) + thêm `aps-environment` entitlement + `CFBundleURLTypes` cho reCAPTCHA fallback.
