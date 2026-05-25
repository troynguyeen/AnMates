# 📋 AnMates MVP – Scrum/Agile Planning

> Tài liệu lập kế hoạch theo mô hình Scrum/Agile, dựa trên [IMPLEMENTATION_TASKS_BREAKDOWN.md](IMPLEMENTATION_TASKS_BREAKDOWN.md)
> Cập nhật: 2026-05-22

---

## 🎯 Tóm tắt dự án

**AnMates** là app kết nối người dùng qua sở thích ăn uống (food-based social/dating), gồm:

- **Backend**: NestJS + PostgreSQL + Redis + Socket.io
- **Frontend**: Flutter
- **Tính năng cốt lõi**: Food Wishlist → Matching Algorithm → Vibe-Check Chat (Nồi Lẩu progress) → Gom Kèo Deal → Trust Score
- **Quy mô MVP**: 50 users đầu, single-machine deployment
- **Timeline**: 8 tuần (21 tasks)

---

## 🏗️ Cấu trúc Scrum

### Team Roles đề xuất

| Role | Trách nhiệm |
|---|---|
| **Product Owner** | Định nghĩa user stories, ưu tiên backlog, nghiệm thu acceptance criteria |
| **Scrum Master** | Facilitate ceremonies, gỡ blockers |
| **Dev Team** | 1 BE + 1 FE + 1 Full-stack (hoặc 2 FS) |

### Sprint cadence

- **Sprint length**: 2 tuần → 4 Sprints tổng
- **Ceremonies**:
  - Daily Standup (15m)
  - Sprint Planning (2h)
  - Sprint Review (1h)
  - Retrospective (1h)
  - Backlog Refinement (1h giữa sprint)

---

## 🗂️ Epics Mapping

| Epic | Mô tả | Tasks gốc |
|---|---|---|
| **E1 – Identity & Trust** | Auth, profile, trust score | 1, 2, 7, 17 |
| **E2 – Food Discovery** | Wishlist + Matching | 3, 4, 5, 6, 13, 14 |
| **E3 – Vibe-Check Chat** | Realtime messaging + Nồi Lẩu | 8, 9, 15 |
| **E4 – Monetization & Safety** | Payment, Block/Report | 10, 11 |
| **E5 – Viral Growth** | Gom Kèo deals | 16 |
| **E6 – Quality & Ops** | Testing, polish, deploy | 18, 19, 20, 21 |
| **E7 – Onboarding** | Đăng ký + face verify | 12 |

---

## 🏃 Sprint Breakdown

### 🔵 Sprint 1 (Week 1-2) – "Foundation"

**Goal**: User có thể đăng ký, đăng nhập, tạo wishlist món ăn.

| Story | Task | Story Points | Owner |
|---|---|---|---|
| Là user, tôi muốn đăng ký tài khoản bằng email/password | [Task 1](IMPLEMENTATION_TASKS_BREAKDOWN.md#L42), [Task 2](IMPLEMENTATION_TASKS_BREAKDOWN.md#L90) | 5 | BE |
| Là user, tôi muốn đăng nhập và nhận JWT | [Task 1](IMPLEMENTATION_TASKS_BREAKDOWN.md#L42), [Task 2](IMPLEMENTATION_TASKS_BREAKDOWN.md#L90) | 3 | BE |
| Là user, tôi muốn thêm/sửa/xóa món ăn yêu thích | [Task 3](IMPLEMENTATION_TASKS_BREAKDOWN.md#L130), [Task 4](IMPLEMENTATION_TASKS_BREAKDOWN.md#L173) | 8 | BE |
| Tech debt: setup logging, error format | – | 2 | BE |

**Definition of Done**: API endpoints có Postman test pass, JWT guard hoạt động, DB migration chạy được.
**Velocity dự kiến**: ~18 SP

---

### 🟢 Sprint 2 (Week 3-4) – "Matching & Trust Core"

**Goal**: Hệ thống ghép cặp + Trust Score hoạt động end-to-end.

| Story | Task | SP |
|---|---|---|
| Là user, tôi muốn xem danh sách bạn ghép phù hợp | [Task 5](IMPLEMENTATION_TASKS_BREAKDOWN.md#L214), [Task 6](IMPLEMENTATION_TASKS_BREAKDOWN.md#L261) | 13 |
| Là user, tôi muốn có Trust Score thể hiện độ uy tín | [Task 7](IMPLEMENTATION_TASKS_BREAKDOWN.md#L303) | 8 |
| Là user, tôi muốn lưu/đọc tin nhắn 1-1 | [Task 8](IMPLEMENTATION_TASKS_BREAKDOWN.md#L356) | 5 |
| Tech: Redis cache cho matches | – | 2 |

**Velocity**: ~28 SP
**Risk**: thuật toán matching tốn perf — cần index DB ngay.

---

### 🟡 Sprint 3 (Week 5-6) – "Realtime + Safety + Money"

**Goal**: Chat realtime, payment sandbox, safety features.

| Story | Task | SP |
|---|---|---|
| Là user, tôi muốn chat realtime với người ghép | [Task 9](IMPLEMENTATION_TASKS_BREAKDOWN.md#L402) | 8 |
| Là user trust thấp, tôi cần đặt cọc 20k để gửi invite | [Task 10](IMPLEMENTATION_TASKS_BREAKDOWN.md#L447) | 13 |
| Là user, tôi muốn block/report kẻ quấy rối | [Task 11](IMPLEMENTATION_TASKS_BREAKDOWN.md#L503) | 5 |
| Flutter: Onboarding + Face verification | [Task 12](IMPLEMENTATION_TASKS_BREAKDOWN.md#L555) | 8 |
| Flutter: Wishlist screen | [Task 13](IMPLEMENTATION_TASKS_BREAKDOWN.md#L608) | 5 |

**Velocity**: ~39 SP (sprint nặng nhất — cân nhắc tách)
**Đề xuất**: nếu team < 3 dev, đẩy [Task 10](IMPLEMENTATION_TASKS_BREAKDOWN.md#L447) sang Sprint 4.

---

### 🔴 Sprint 4 (Week 7-8) – "Polish & Launch"

**Goal**: UI hoàn chỉnh, deploy production, go-live 50 users.

| Story | Task | SP |
|---|---|---|
| Flutter: Matching/Discovery screen | [Task 14](IMPLEMENTATION_TASKS_BREAKDOWN.md#L663) | 5 |
| Flutter: Chat + Nồi Lẩu progress bar | [Task 15](IMPLEMENTATION_TASKS_BREAKDOWN.md#L723) | 8 |
| Flutter: Gom Kèo deal sharing | [Task 16](IMPLEMENTATION_TASKS_BREAKDOWN.md#L787) | 8 |
| Flutter: Profile + Trust dashboard | [Task 17](IMPLEMENTATION_TASKS_BREAKDOWN.md#L852) | 5 |
| QA: API error handling + rate limit | [Task 18](IMPLEMENTATION_TASKS_BREAKDOWN.md#L914) | 5 |
| QA: Flutter polish + accessibility | [Task 19](IMPLEMENTATION_TASKS_BREAKDOWN.md#L981) | 3 |
| Ops: Docker Compose stack | [Task 20](IMPLEMENTATION_TASKS_BREAKDOWN.md#L1039) | 8 |
| Ops: Go-live checklist + monitoring | [Task 21](IMPLEMENTATION_TASKS_BREAKDOWN.md#L1122) | 3 |

**Velocity**: ~45 SP → **rủi ro cao**, đề xuất kéo Sprint 4 thêm 1 tuần buffer hoặc loại bớt scope (ví dụ hoãn Gom Kèo sang post-MVP).

---

## 📊 Product Backlog Prioritization (MoSCoW)

| Priority | Items |
|---|---|
| **Must Have** | Auth, Wishlist, Matching, Chat realtime, Trust Score, Deploy |
| **Should Have** | Onboarding face verify, Block/Report, Error handling |
| **Could Have** | Payment deposit, Gom Kèo viral, Badges |
| **Won't Have (MVP)** | Dark mode, AI recommendation, Premium tier |

---

## ⚠️ Rủi ro & Mitigation

| Risk | Impact | Mitigation |
|---|---|---|
| Sprint 3-4 quá tải | High | Tách team thành 2 luồng BE/FE song song từ Sprint 2 |
| Payment integration phức tạp (MoMo/ZaloPay sandbox) | Medium | Spike 1-day trước Sprint 3 để khảo sát SDK |
| Realtime socket scaling | Medium | MVP chỉ 50 users → giữ single-node Redis adapter |
| Trust Score tuning | Low | A/B test sau go-live, không block MVP |
| Face verification accuracy | Medium | MVP dùng upload ảnh đơn giản, không AI verify |

---

## ✅ Definition of Ready / Done

### Definition of Ready (story có thể vào sprint)

- [ ] Acceptance criteria rõ ràng
- [ ] Dependencies xác định
- [ ] Estimate xong (Planning Poker)
- [ ] UI mockup có (cho FE story)
- [ ] API contract đã thống nhất (cho BE story)

### Definition of Done

- [ ] Code merged + reviewed (≥ 1 reviewer approve)
- [ ] Unit test ≥ 70% coverage
- [ ] API doc cập nhật (Swagger)
- [ ] QA pass acceptance criteria
- [ ] Deploy lên staging environment
- [ ] Không có critical/high bug open

---

## 📈 Metrics theo dõi

| Metric | Mục tiêu |
|---|---|
| **Sprint Velocity** | Ổn định ±10% sau Sprint 2 |
| **Burndown chart** | Daily update, không backloaded |
| **Bug escape rate** | < 5 bugs/sprint phát hiện sau review |
| **Lead time** | Story trung bình < 5 ngày |
| **Code review turnaround** | < 24h |

---

## 🗓️ Timeline tổng quan

```
Week 1-2  [Sprint 1] ████████░░░░░░░░░░░░░░░░░░░░░░░░ Foundation
Week 3-4  [Sprint 2] ░░░░░░░░████████░░░░░░░░░░░░░░░░ Matching & Trust
Week 5-6  [Sprint 3] ░░░░░░░░░░░░░░░░████████░░░░░░░░ Realtime + Safety
Week 7-8  [Sprint 4] ░░░░░░░░░░░░░░░░░░░░░░░░████████ Polish & Launch
```

---

## 🎬 Next Steps

1. **Sprint 0 (1 ngày)**: Setup tooling — Jira/Linear board, Git repo, CI/CD skeleton
2. **Planning Poker session** để estimate lại story points với cả team
3. **Kick-off Sprint 1** với daily standup ngay từ ngày đầu
4. **Setup retrospective template** (Start/Stop/Continue hoặc Mad/Sad/Glad)

---

**Tham khảo nguồn**: [IMPLEMENTATION_TASKS_BREAKDOWN.md](IMPLEMENTATION_TASKS_BREAKDOWN.md)
