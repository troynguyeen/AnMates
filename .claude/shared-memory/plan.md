# Plan — Phase 0 (Foundation) + Phase 1 (Onboarding screens 01-07)

**Owner:** team-leader → coder → qa
**Date:** 2026-05-26
**Velocity preference:** ship phase-end (not screen-end). QA runs once at end of Phase 1.

---

## Phase 0 — Foundation (no screens; ships primitives + theme)

### Step P0.1 — Pubspec + asset folder

- Add `flutter_svg: ^2.0.10+1` to `pubspec.yaml` dependencies (keep existing deps untouched).
- DO NOT add `lottie` this session — Sparkle uses CustomPainter or inline SVG.
- Add asset declarations:
  ```yaml
  flutter:
    uses-material-design: true
    assets:
      - assets/sparkles/
      - assets/logo/
  ```
- Create folders: `assets/sparkles/`, `assets/logo/` (empty placeholders OK — Sparkle will fall back to CustomPainter).

### Step P0.2 — Theme extension

In `lib/theme/app_theme.dart`:

- Add `AppSpacing` class with constants `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`, `xxxl=48`.
- Add `AppSemanticColors` class: `success=#00A86B`, `warning=#FFA500`, `error=#E74C3C`, `neutral=#95A5A6`.
- Add `AppRadius` class: `sm=8`, `md=12`, `lg=16`, `xl=20`, `pill=999`.
- Add `AppShadows` class with elevation presets (card, button, modal).
- Keep existing `AppColors`, `AppTextStyles`, `AppTheme` untouched — extend, do not break.

### Step P0.3 — Services (reduce-motion + haptic)

Create:
- `lib/services/motion_service.dart` — `MotionService` singleton with `ValueNotifier<bool> reduceMotion`. Defaults `false`; reads from `MediaQuery.of(context).disableAnimations` when widget tree available.
- `lib/services/haptic_service.dart` — `HapticService` with `light()`, `medium()`, `success()`, `error()` methods. Uses `HapticFeedback.lightImpact()` etc. No-ops on web (Flutter HapticFeedback is mobile-only).
- `lib/services/app_loader_service.dart` — Provider-based stack-aware loader controller. API per design-system.md §AppLoader: `show({mode, caption, determinate})`, `setProgress(tokenId, value)`, `hide(tokenId)`, `withLoader(Future)` helper.

### Step P0.4 — Primitives (in `lib/widgets/anm/`)

Create folder `lib/widgets/anm/` + barrel file `anm.dart` that re-exports everything.

1. `sparkle.dart` — `Sparkle` widget. Props: `size`, `color`, `delayMs`, `durationMs`. Twinkle animation 1500-2500ms randomized + 0-2000ms delay. CustomPainter draws 4-point or 6-point star. Reduce-motion = opacity-only pulse.
2. `app_loader.dart` — `AppLoader` widget with `LoaderMode` enum (splash / overlay / topBar). Each mode renders horizontal pill bar per spec. Provider-driven for overlay/topBar; `splash` is direct widget.
3. `app_button.dart` — `AppButton` with `AppButtonVariant` enum (primary/secondary/outline/danger/ghost). Tap scale 0.97 micro-feedback. Disabled state opacity 50%. Hit target ≥44×44.
4. `app_chip.dart` — `AppChip` with `AppChipVariant` (filter/tag/mood/state). Selectable mode with white check ✓ on select. Spring scale on tap.
5. `app_input.dart` — `AppInput` with `AppInputType` (text/phone/otp/search). Focus = 2px Berry Crush border (150ms morph). Error = shake animation + red text.
6. `app_card.dart` — `AppCard` base + `RestaurantCard`, `MateCard`, `BookingCard` variants. Tap scale 0.97. Shared element hero tag support.
7. `avatar.dart` — `Avatar` widget with optional `TrustBadge` ring. Sizes: 32/48/64/96/128.
8. `vibe_ring.dart` — `VibeRing` circular progress 0-100. Sizes: small (28-32) / hero (64-80) / xl (180 for Screen 04). Wisteria→Berry Crush gradient fill. Animated draw on value change (600ms ease-out). Unlock pulse at 70.
9. `trust_badge.dart` — `TrustBadge` widget; renders Perfect Mate (≥90, gold ✨) / Trusted (80-89, Glaucous ✓) / Limited (<80, Caviar ⚠).

### Step P0.5 — Reduce-motion + haptic verification

- All primitives MUST check `MotionService.reduceMotion` before running animations.
- All tap-feedback widgets MUST call `HapticService.light()` on tap (no-op gracefully on web).

---

## Phase 1 — Onboarding screens 01-07

For EACH screen: open `plan/lastest/design/<file>.html` side-by-side; match layout/colors/typography pixel-close; implement animation timeline from `design-system.md`; build all 5 states (default/loading/empty/error/success) where applicable.

### Step P1.1 — Screen 01 Splash (`lib/views/splash/splash_screen.dart` — REPLACE)

Reference: `plan/lastest/design/01 _ Splash.html` + design-system.md §"Splash Screen (Screen 01) — Full Animation Spec".

Implement timeline t=0 → t=1500ms entrance + idle loop (logo breathing, sparkle twinkle, loader indeterminate) + exit fade. 6-8 sparkles in upper 60%. Wisteria glow radial gradient over Berry Crush. AppLoader.splash with caption "Đang nhóm lửa nồi lẩu...".

### Step P1.2 — Screens 02/03/04 Onboard carousel (`lib/views/onboarding/onboarding_view.dart` — REPLACE)

References:
- `02 _ Onboard _ Ch_n qu_n.html` (Chọn quán — 4 genre cards drop in)
- `03 _ Onboard _ Social proof.html` (15 người đang thèm — counter tick)
- `04 _ Onboard _ N_i l_u.html` (Vibe ring unlock @ 70%)

Common framework: page indicator (3 dots, active morphs to 24×8 pill), "Bỏ qua" + "Tiếp tục →" / "Bắt đầu →" CTA with arrow nudge. Page-to-page slide+fade transition (350ms). All entrance timelines from design-system.md §"Onboarding Edu Carousel".

### Step P1.3 — Screen 05 Đăng nhập (`lib/views/auth/auth_view.dart` + `phone_input_view.dart` — REPLACE)

Reference: `05 _ _ng nh_p.html` + design-system.md §"Screen 05 — Đăng nhập".

CRITICAL: preserve Firebase Phone Auth wiring from R-001. `PhoneInputView` keeps existing service calls but UI is rewritten. Inherit bg gradient from splash (no re-paint flash). Headline "Va Mates, ăn miết." + body + phone Input (focus border morph) + primary CTA "Gửi mã xác minh" + "HOẶC" divider + Apple button + footnote.

### Step P1.4 — Screen 06 OTP (`lib/views/auth/otp_view.dart` — REPLACE UI, keep wiring)

Reference: `06 _ OTP.html` + design-system.md §"Screen 06 — OTP Entry".

6 digit slots with scale-in entrance + auto-advance underline focus migration. Per-digit haptic light. Auto-submit on 6th. Countdown timer "Gửi lại (00:62)" → resend at 00:00. Success = green ✓ cell flip. Failure = shake + red underline + clear. Preserve Firebase signInWithCredential.

### Step P1.5 — Screen 07 Face verify (NEW: `lib/views/auth/face_verify_view.dart`)

Reference: `07 _ Face verify.html` + design-system.md §"Screen 07 — Face verify".

UI ONLY (no real ML — mock 4-step liveness flow: look straight → blink → turn left → turn right). Circular camera frame placeholder + ring progress 0→100% in 25% steps. Auto-advance with mock 1.5s timer per step. Completion → 8 sparkles burst + "Xác minh thành công ✨" + AppLoader.overlay → navigate to Screen 08 (placeholder; Phase 2 will implement).

### Step P1.6 — Router/navigation glue

Update `lib/main.dart` initial route logic. Splash → onboarding (if not done) → auth → otp → face verify → home placeholder. Add `assets/` declarations to pubspec if not done in P0.

---

## Dispatch order (this session)

1. **coder pass 1**: Phase 0 (P0.1 → P0.5) — foundation only, no screens yet
2. **coder pass 2**: Phase 1 (P1.1 → P1.6) — all 7 screens + router glue
3. **qa pass**: scope = Phase 0 primitives + Phase 1 screens 01-07. Run `flutter analyze`, `flutter test`, manual visual walk through screens, compare to HTML refs. Report to `qa-reports/2026-05-26-phase-0-1.md`.
4. Loop coder→qa max 3 times if fail
5. On pass: update `current-task.md` → status `done` (this session); summarize Phase 2-7 remaining to user

## Risks / mitigations

| Risk | Mitigation |
|------|-----------|
| Sparkle SVG assets missing | Coder uses CustomPainter to draw 4-point + 6-point stars inline |
| HapticFeedback no-op on web breaks runtime | Wrap in `if (!kIsWeb)` guard inside HapticService |
| Existing Firebase wiring lost during rewrite | Coder must read existing `phone_input_view.dart` + `otp_view.dart` BEFORE replacing; preserve all service calls + error handling |
| `flutter analyze` warnings from new code | Coder runs analyze locally + cleans warnings before handoff |
| QA can't run on Windows easily | qa accepts `flutter analyze` + `flutter test` + manual code-vs-HTML walk-through if Playwright screenshots not feasible on Windows |
