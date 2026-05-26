# Session — Real Phone OTP Readiness Audit (anmates-studio)

**Date:** 2026-05-25
**Project:** Firebase `anmates-studio` (project number `492509819332`)
**Goal:** Bật phone OTP với số điện thoại thật (không phải test number)
**Status:** Backend/CLI work DONE. iOS Xcode + Firebase Console manual steps remaining.

---

## Tools installed
- `firebase` CLI v15.18.0 (already present, logged in as `anmates.studio@gmail.com`)
- `gcloud` CLI v569.0.0 (newly installed via `brew install --cask gcloud-cli`)
  - **Not yet logged in** — run `! gcloud auth login` if needed later for advanced ops.

## What was verified via Firebase REST API

### ✅ Server side — ALL GOOD
| Item | Status | Details |
|------|--------|---------|
| Billing plan | ✅ Blaze | `billingAccountName: 0180CE-056A0D-608306` (real SMS requires Blaze) |
| Identity Platform | ✅ IDENTITY_PLATFORM subtype | Full GCIP, not basic Firebase Auth |
| Phone provider enabled | ✅ | `signIn.phoneNumber.enabled: true` |
| Identity Toolkit API | ✅ | `identitytoolkit.googleapis.com` ENABLED |
| FCM API (iOS silent push) | ✅ | `fcm.googleapis.com` ENABLED |
| reCAPTCHA Enterprise API | ✅ | `recaptchaenterprise.googleapis.com` ENABLED |
| SMS region allowlist | ✅ | Only `VN` allowed — anti SMS pumping |
| Test phone numbers | ✅ | `+84393405621` → `123456` |
| Authorized domains | ✅ (dev) | `localhost`, `anmates-studio.firebaseapp.com`, `anmates-studio.web.app` |

### ✅ Android — FIXED THIS SESSION
| Item | Before | After |
|------|--------|-------|
| SHA-1 in Firebase | 0 entries | `40:7E:28:30:F5:D5:7C:23:87:38:03:93:AD:A6:A4:4D:7E:24:19:6F` |
| SHA-256 in Firebase | 0 entries | `93:DF:15:AC:9D:F7:46:BF:00:2F:20:08:5B:CF:4B:B8:03:05:72:D7:97:E8:02:37:56:05:46:A1:C9:DA:E9:DD` |
| Debug keystore | missing | Generated at `~/.android/debug.keystore` (standard `android`/`android` creds) |
| `android/app/google-services.json` | stale (no oauth_client) | Re-downloaded from Firebase |

Commands used:
```bash
keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android \
  -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
  -validity 10950 -dname "CN=Android Debug,O=Android,C=US"

firebase apps:android:sha:create 1:492509819332:android:8ed3f6ed617acc3f5b3491 \
  <SHA1> --project anmates-studio
firebase apps:android:sha:create 1:492509819332:android:8ed3f6ed617acc3f5b3491 \
  <SHA256> --project anmates-studio

firebase apps:sdkconfig ANDROID 1:492509819332:android:8ed3f6ed617acc3f5b3491 \
  --project anmates-studio --out android/app/google-services.json
```

### ❌ iOS — STILL BLOCKED (manual steps needed)
| Item | Status | Required? |
|------|--------|-----------|
| Bundle ID match | ✅ `com.anmates.anmates` everywhere | — |
| `Runner.entitlements` file | ❌ MISSING | Required for real OTP |
| Push Notifications capability | ❌ Not in Xcode project | Required for silent push verification |
| `aps-environment` entitlement | ❌ Missing | Required |
| `UIBackgroundModes` (remote-notification) | ❌ Missing in Info.plist | Required |
| APNs Auth Key (.p8) uploaded to Firebase | ❌ Cannot verify via API | **REQUIRED** — without this, iOS OTP fails |
| `CFBundleURLTypes` (reCAPTCHA fallback) | ❌ Missing | Optional but recommended |
| `REVERSED_CLIENT_ID` in GoogleService-Info.plist | ❌ Missing | Only needed if Google Sign-In used; not strictly required for phone-only |

### ⚠️ Optional / Production hardening
- **Firebase App Check** — API not enabled (`firebaseappcheck.googleapis.com`). Recommended for production to block abuse. Without App Check, phone OTP still works but is more vulnerable to abuse from cloned apps.
- **Custom authorized domain** — If shipping production web with custom domain (e.g. `anmates.studio`), need to add to Authentication → Settings → Authorized domains.
- **SMS quota** — Default Firebase quota = 10/hour per IP, 5/day per phone. For higher traffic, contact Firebase support.
- **Daily SMS budget** — Set in Console → Authentication → Settings → Phone numbers for testing (limits accidental over-billing).

---

## Action checklist for user

### 🔴 CRITICAL — must do for iOS to work
1. **Upload APNs Auth Key**
   - https://developer.apple.com → Certificates, Identifiers & Profiles → **Keys** → "+"
   - Tick **Apple Push Notifications service (APNs)** → Continue → Register
   - Download `.p8` file. Note **Key ID** (10 chars) and **Team ID** (10 chars).
   - Firebase Console → ⚙ → **Project settings** → **Cloud Messaging** tab
   - Under "Apple app configuration" for `com.anmates.anmates` → **APNs Authentication Key** → Upload → fill in `.p8`, Key ID, Team ID.
2. **Enable Push Notifications capability in Xcode**
   - `open /Users/thanhit/Downloads/AnMates/AnMatesApp/anmates_flutter/ios/Runner.xcworkspace`
   - Select **Runner** target → **Signing & Capabilities** tab
   - Click **+ Capability** → add **Push Notifications**
   - Click **+ Capability** again → add **Background Modes** → tick **Remote notifications**
   - This auto-creates `Runner.entitlements` and adds `aps-environment` + `UIBackgroundModes`.

### 🟡 RECOMMENDED — production hardening
3. **Add release keystore SHA** (when ready to publish Android)
   - For Play App Signing: Google Play Console → app → Setup → App signing → copy "App signing key certificate SHA-1 + SHA-256"
   - Add via `firebase apps:android:sha:create <appId> <sha>` or Firebase Console.
4. **Enable Firebase App Check**
   - Firebase Console → **App Check** → Get started
   - Android: Play Integrity provider
   - iOS: App Attest (iOS 14+) or DeviceCheck
   - Web: reCAPTCHA Enterprise
   - Then enforce on Authentication: App Check → APIs → Authentication → Enforce
5. **Production web domain**
   - When deploying to `anmates.studio` (or any custom domain), add to:
     Authentication → Settings → **Authorized domains** → Add domain.

### 🟢 NICE TO HAVE
6. **Increase SMS quota** if expecting >10 OTP/hour from same IP — contact Firebase support.
7. **Configure SMS templates** — Authentication → Templates → SMS verification (already has Vietnamese default).
8. **Set daily SMS budget cap** — Authentication → Settings → SMS region policy (already set to VN-only).

---

## Test command (after iOS steps done)
```bash
# Android emulator/device
cd /Users/thanhit/Downloads/AnMates/AnMatesApp/anmates_flutter
flutter run -d <android-device>
# Then trigger phone OTP with a real VN number

# iOS (requires real device, NOT simulator — silent push doesn't work in simulator)
flutter run -d <ios-device>
```

## Files touched this session
- Created: `~/.android/debug.keystore`
- Updated (Firebase server-side): SHA list for app `1:492509819332:android:8ed3f6ed617acc3f5b3491`
- Updated: `AnMatesApp/anmates_flutter/android/app/google-services.json`
- Installed: `/opt/homebrew/share/google-cloud-sdk/` (gcloud v569.0.0)

## Things NOT done (require user action)
- Xcode capability changes (Push Notifications, Background Modes)
- APNs `.p8` upload to Firebase
- App Check enablement (optional)
- Release keystore SHA (when shipping Android)
