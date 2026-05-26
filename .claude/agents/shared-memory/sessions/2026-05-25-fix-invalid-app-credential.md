# Session: Diagnose `INVALID_APP_CREDENTIAL` from Firebase Phone Auth

**Date:** 2026-05-25
**Type:** Bug investigation (no code change yet)
**Operator:** team-leader (main assistant)
**User request:** Bug từ app AnMates với response `{"error":{"code":400,"message":"INVALID_APP_CREDENTIAL",...}}`. Investigate, plan, dispatch fix.

## Decisions

| # | Question                                                                 | Decision                                                                                                       |
|---|--------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| 1 | Có sửa code Flutter không?                                              | **Không** — flow `verifyPhoneNumber` / `signInWithPhoneNumber` đã đúng. Vấn đề ở config.                       |
| 2 | Có dispatch coder ngay không?                                            | **Chưa** — vì 80% công việc nằm ở Firebase Console (cần user). Coder chỉ làm phần entitlement + URL scheme sau.|
| 3 | Có giữ `phone_input_view` hiện tại không?                                | **Có**, không touch logic.                                                                                     |
| 4 | Có sửa backend Go không?                                                 | **Không** — error đến từ Google Identity Toolkit phía client, không qua backend.                              |

## Findings (evidence trong repo)

- **Android `google-services.json`**: `"oauth_client": []` rỗng, không có `certificate_hash` → SHA fingerprint chưa register với Firebase Console.
- **iOS `GoogleService-Info.plist`**: thiếu `REVERSED_CLIENT_ID` (OK, không cần cho phone auth), nhưng KHÔNG có cấu hình APNs nào (APNs key phải upload Firebase Console server-side).
- **iOS `Info.plist`**: thiếu `CFBundleURLTypes` cho reCAPTCHA fallback URL scheme, thiếu `aps-environment` entitlement.
- **iOS `AppDelegate.swift`**: clean, dùng FirebaseAppDelegateProxy default (OK).
- **Web `index.html`**: load Firebase JS SDK v12.13.0 đúng, không cần thêm reCAPTCHA script (Firebase tự inject).
- **`phone_input_view.dart` / `otp_view.dart`**: dùng đúng cả 2 path (`signInWithPhoneNumber` cho web, `verifyPhoneNumber` cho mobile). Không có lỗi logic.
- **Backend Go (`anmates-api`)**: không động đến phone auth tới Firebase, chỉ verify ID token. Không phải nguồn lỗi.

## Root cause

`INVALID_APP_CREDENTIAL` là phản hồi của Google Identity Toolkit khi nó **không xác thực được app instance** đang gọi `sendVerificationCode`. Cách Firebase verify app theo platform:

- **Android** → cần SHA-1/SHA-256 keystore khớp + Play Integrity / SafetyNet (auto qua Google Play Services).
- **iOS** → cần silent push qua APNs (yêu cầu APNs key/cert đã upload), nếu fail thì fallback reCAPTCHA (cần URL scheme).
- **Web** → cần invisible reCAPTCHA (tự động) + domain phải nằm trong Authorized domains.

Repo hiện thiếu cả 3.

## Deliverables produced

- `/Users/thanhit/Downloads/AnMates/.claude/agents/shared-memory/current-task.md` (updated)
- `/Users/thanhit/Downloads/AnMates/.claude/agents/shared-memory/plan.md` (updated)
- `/Users/thanhit/Downloads/AnMates/.claude/agents/shared-memory/blockers.md` (BLOCKER-001 added)
- `/Users/thanhit/Downloads/AnMates/.claude/agents/shared-memory/sessions/2026-05-25-fix-invalid-app-credential.md` (this file)
- `/Users/thanhit/Downloads/AnMates/.claude/agents/shared-memory/changelog.md` (row appended)

## Open follow-ups

1. **User**: thực hiện các step trong `plan.md` mục A (Firebase Console: SHA Android, APNs iOS, Authorized domains Web, bật Phone provider).
2. **Coder** (sau khi user xong): thêm `Runner.entitlements` (Push Notifications) + `CFBundleURLTypes` vào `Info.plist`.
3. **QA**: smoke test phone auth 3 platforms, capture vào `qa-reports/2026-05-25-phone-auth.md`.

## Key facts to remember

- Firebase project ID: **anmates-studio**
- Android applicationId: `com.anmates.anmates`
- iOS bundle ID: `com.anmates.anmates`
- GOOGLE_APP_ID iOS: `1:492509819332:ios:590f6db8c98f4b985b3491` (dùng đảo ngược cho URL scheme reCAPTCHA fallback)
- Sender ID: `492509819332`
- Test phone (dev bypass backend): `+84999000001`
