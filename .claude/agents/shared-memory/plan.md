# Plan

## Task: Fix `INVALID_APP_CREDENTIAL` Firebase Phone Auth error
**Date:** 2026-05-25

### Root cause analysis (done — team-leader)
- Lỗi `INVALID_APP_CREDENTIAL` đến từ Google Identity Toolkit, được trả ra khi Firebase **không xác thực được app** đang gọi `sendVerificationCode`.
- Trên Android: cần SHA-1/SHA-256 fingerprint của keystore (debug & release) được register trong Firebase Console. File `google-services.json` hiện trong repo có `"oauth_client": []` rỗng → chưa add SHA.
- Trên iOS: cần APNs Auth Key (.p8) hoặc APNs Certificate được upload vào Firebase Console → app nhận silent push để verify. Nếu thiếu, FirebaseAuth fallback reCAPTCHA — yêu cầu `CFBundleURLTypes` chứa `REVERSED_CLIENT_ID` trong `Info.plist`. Hiện cả 2 đều thiếu.
- Trên Web: domain phục vụ Flutter web (`localhost`, `anmates.studio`, …) phải nằm trong **Authorized domains** của Firebase Auth. Bỏ là dính `INVALID_APP_CREDENTIAL`.

### Steps

#### A. User (phải làm — yêu cầu Firebase Console access)
1. [ ] **Android — Add SHA fingerprints**
   - Lấy SHA-1 debug:
     ```
     cd /Users/thanhit/Downloads/AnMates/AnMatesApp/anmates_flutter/android && ./gradlew signingReport
     ```
     Tìm dòng `Variant: debug` → copy SHA1 và SHA-256.
   - Vào https://console.firebase.google.com → project **anmates-studio** → ⚙ Project settings → tab **General** → kéo xuống app Android `com.anmates.anmates` → **Add fingerprint** → paste SHA-1; lặp lại cho SHA-256.
   - (Nếu đã có release keystore) lấy SHA của keystore release (`keytool -list -v -keystore <path>.jks -alias <alias>`) và add tương tự.
   - Bấm **Download google-services.json** → replace file `AnMatesApp/anmates_flutter/android/app/google-services.json`.

2. [ ] **iOS — Upload APNs key**
   - Vào https://developer.apple.com → Certificates, Identifiers & Profiles → Keys → tạo key mới với **Apple Push Notifications service (APNs)** enabled → download `.p8` + ghi nhớ **Key ID** và **Team ID**.
   - Vào Firebase Console → project settings → tab **Cloud Messaging** → mục Apple app configuration → **APNs Authentication Key** → upload `.p8`, điền Key ID + Team ID.
   - Trong Xcode (`AnMatesApp/anmates_flutter/ios/Runner.xcworkspace`) → target Runner → tab Signing & Capabilities → bấm **+ Capability** → add **Push Notifications** (sinh ra entitlement `aps-environment=development`).
   - Bấm **Download GoogleService-Info.plist** mới (nếu có thay đổi) → replace `AnMatesApp/anmates_flutter/ios/Runner/GoogleService-Info.plist`.

3. [ ] **Web — Add authorized domains**
   - Firebase Console → Authentication → tab **Settings** → mục **Authorized domains** → đảm bảo có `localhost`, và domain production (vd `anmates.studio`, `app.anmates.studio`).

4. [ ] **Verify Phone Auth provider bật**
   - Firebase Console → Authentication → tab **Sign-in method** → bật **Phone**.
   - (Optional, recommended) Thêm số test trong `Phone numbers for testing`: vd `+84999000001` với code `123456` → tránh hết quota SMS khi dev.

5. [ ] **(Optional) App Check**
   - Nếu đã enable App Check enforcement cho Authentication, phải register debug token (Android: trong logcat tìm `App Check debug token`; iOS: tìm `FIRDebugProvider`). Hoặc tạm thời disable enforcement trong khi fix.

#### B. Coder (chạy sau khi user xong step A)
6. [ ] (Coder) Thêm Push Notifications entitlement file `ios/Runner/Runner.entitlements` (nếu Xcode chưa generate) với key `aps-environment=development`, link vào `Runner.xcodeproj` build settings (`CODE_SIGN_ENTITLEMENTS`).
7. [ ] (Coder) Thêm `CFBundleURLTypes` vào `ios/Runner/Info.plist` để fallback reCAPTCHA hoạt động kể cả khi APNs lỗi:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key><string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>app-1-492509819332-ios-590f6db8c98f4b985b3491</string>
       </array>
     </dict>
   </array>
   ```
   (Scheme này là REVERSED form của GOOGLE_APP_ID, dùng cho Firebase Auth reCAPTCHA verifier trên iOS.)
8. [ ] (Coder) Add `appVerificationDisabledForTesting=true` chỉ trong debug build + dùng số test → giúp dev nhanh hơn.

#### C. QA
9. [ ] (QA) Smoke test phone auth flow:
   - Web (Chrome localhost:54180): nhập số → reCAPTCHA invisible → nhận OTP/SMS hoặc code test → submit → backend `/auth/phone/verify` 200.
   - Android emulator: nhập số → không còn `INVALID_APP_CREDENTIAL`; auto-retrieval hoặc nhập OTP → submit OK.
   - iOS simulator: nhập số → fallback reCAPTCHA (vì simulator không có APNs token) → submit OK. Trên device thật: silent push → verify pass.
10. [ ] (QA) Capture screenshot + paste log dòng `verifyPhoneNumber` thành công vào `qa-reports/2026-05-25-phone-auth.md`.

### Out of scope
- Sửa logic backend Go (lỗi không xuất phát từ backend).
- Migrate sang OTP provider khác (Twilio, eSMS) — chỉ là Firebase config fix.
- Setup App Check enforcement đầy đủ (gợi ý theo dõi sau).
