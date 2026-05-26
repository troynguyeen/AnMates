# Current Task

**Status:** blocked
**Owner:** team-leader (diagnostics done — needs user action on Firebase Console)
**Started at:** 2026-05-25 22:50 UTC
**Goal:** Fix `INVALID_APP_CREDENTIAL` (HTTP 400) when AnMates app gửi OTP qua Firebase Phone Auth.

## Acceptance criteria
- [ ] (User) SHA-1 + SHA-256 fingerprint của Android debug & release keystore đã đăng ký trong Firebase Console.
- [ ] (User) APNs Authentication Key (.p8) đã upload Firebase Console > Project Settings > Cloud Messaging cho app iOS `com.anmates.anmates`.
- [ ] (User) Tải lại `google-services.json` & `GoogleService-Info.plist` mới (sau khi add SHA / APNs) và replace 2 file trong repo.
- [ ] (User) Domain hosting Flutter web (vd `anmates.studio`, `localhost`) được thêm vào Firebase Console > Authentication > Settings > Authorized domains.
- [ ] (Coder, optional) Thêm `CFBundleURLTypes` với REVERSED_CLIENT_ID vào `ios/Runner/Info.plist` để reCAPTCHA fallback chạy được trên iOS simulator / device chưa có APNs.
- [ ] (QA) Test lại flow phone auth trên web (localhost:54180), Android emulator, iOS simulator → không còn `INVALID_APP_CREDENTIAL`.

## Notes
- Lỗi này là response từ Google Identity Toolkit (`identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode`), không phải từ backend Go.
- Code Flutter (`phone_input_view.dart`, `otp_view.dart`) đã đúng pattern — không cần sửa logic gọi `verifyPhoneNumber` / `signInWithPhoneNumber`.
- Root cause là **config phía Firebase Console** (app credential = SHA fingerprint Android, APNs key iOS, authorized domain Web).
- Bằng chứng trong repo:
  - `android/app/google-services.json` → `"oauth_client": []` rỗng và KHÔNG có mảng `certificate_hash` ⇒ chưa add SHA-1.
  - `ios/Runner/GoogleService-Info.plist` không có `REVERSED_CLIENT_ID` (chưa bật Google Sign-In, nhưng không ảnh hưởng phone auth nếu APNs OK).
  - `ios/Runner/Info.plist` không có Push Notifications entitlement / `aps-environment` → iOS không nhận được silent push để verify app, sẽ fallback reCAPTCHA — nhưng fallback đó cần URL scheme đăng ký, hiện chưa có.
