# Current Task

**Status:** done (web)
**Owner:** main assistant
**Started at:** 2026-05-25 22:50 UTC
**Closed at:** 2026-05-26 (user confirmed "đã test done")
**Goal:** Fix `INVALID_APP_CREDENTIAL` (HTTP 400) when AnMates app gửi OTP qua Firebase Phone Auth.

## Resolution

Root cause = `127.0.0.1` không nằm trong **Firebase Console → Authorized domains**, dù `localhost` đã có. Browser issue reCAPTCHA token gắn với origin chính xác; `localhost` và `127.0.0.1` là 2 origin khác nhau ở góc nhìn của reCAPTCHA.

**Fix (web):** add `127.0.0.1` vào Authorized domains + truy cập app qua `http://127.0.0.1:PORT` thay vì `http://localhost:PORT`.

Sau khi fix, Flutter code được refactor lại theo Firebase Phone Auth docs (init Firebase ở `main()`, `RecaptchaVerifier` lifecycle, central error mapping, `wsUrl` derive từ env).

Full detail: [sessions/2026-05-26-firebase-phone-otp-resolved.md](sessions/2026-05-26-firebase-phone-otp-resolved.md).

## Acceptance criteria
- [x] (User) Add `127.0.0.1` vào Firebase Authorized domains
- [x] (User) Test OTP gửi/verify trên web localhost → success
- [x] (Main assistant) Refactor code Flutter theo Firebase best practices
- [x] (Main assistant) `flutter analyze` clean + `flutter build web` success
- [ ] (Future) Android real-phone test — cần SHA-1/SHA-256 keystore release đăng ký Firebase
- [ ] (Future) iOS real-phone test — cần APNs Auth Key (.p8) upload + `aps-environment` entitlement + `CFBundleURLTypes` cho reCAPTCHA fallback

## Notes
- `INVALID_APP_CREDENTIAL` là response của Google Identity Toolkit (`identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode`) — không phải từ backend Go.
- Cơ chế Firebase verify app theo platform: Web = reCAPTCHA + authorized domain; Android = SHA fingerprint + Play Integrity; iOS = APNs silent push + fallback reCAPTCHA URL scheme.
- Firebase Phone Auth từ Sept 2023 yêu cầu **Blaze plan** — Spark plan sẽ trả error.
- `RecaptchaVerifier` chỉ dùng 1 lần — phải `clear()` trước khi tạo mới.
