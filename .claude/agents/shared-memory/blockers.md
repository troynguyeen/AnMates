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
**Status:** open

### Problem
App AnMates (Flutter) gọi Firebase Phone Auth (`verifyPhoneNumber` / `signInWithPhoneNumber`) bị Google Identity Toolkit từ chối với HTTP 400 `INVALID_APP_CREDENTIAL`. Code Flutter đúng, root cause là config phía Firebase Console:
- Android: chưa có SHA-1/SHA-256 fingerprint nào được đăng ký (`google-services.json` có `oauth_client: []` rỗng).
- iOS: chưa upload APNs Auth Key (.p8) lên Firebase, app không nhận được silent push để verify.
- Web: domain phục vụ Flutter web có thể chưa nằm trong Authorized domains.

### Suggested fix
User cần đăng nhập Firebase Console (project **anmates-studio**) và thực hiện các step trong `plan.md` mục A. Coder agent không thể tự fix vì không có quyền truy cập Firebase Console.

Sau khi user xong, team-leader sẽ dispatch coder để add `Push Notifications` entitlement + `CFBundleURLTypes` (mục B trong plan), rồi qa run smoke test.
