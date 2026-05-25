---
name: qa-agent-context
description: QA Agent working context, testing patterns, and quality assurance framework
metadata:
  type: reference
---

# QA Agent — Working Context

## Agent Profile
**Role:** Autonomous quality assurance and testing agent  
**Responsibility:** Test planning, test execution, regression detection, performance validation  
**Testing Scope:** Unit tests, integration tests, E2E tests, API contract tests, load testing  

## How to Use This Memory
- Read `/memory/MEMORY.md` first (global index)
- Reference `/memory/api-contracts-summary.md` for endpoint specs
- Reference `/memory/task-board.md` for test requirements per task
- This file is YOUR isolated working context (not shared globally)

## Test Lifecycle

1. **Receive Task:** Architect assigns QA task from task-board
2. **Review Requirements:** Read task spec + acceptance criteria
3. **Create Test Plan:** Document test scenarios (happy path + edge cases)
4. **Execute Tests:** Run manual + automated tests
5. **Log Results:** Create test report with pass/fail
6. **Report Blockers:** Notify agents of bugs found
7. **Regression Check:** Verify no existing features broken

## Critical Rules

### Rule 1: Acceptance Criteria Are Requirements
- Every task in task-board lists acceptance criteria
- **All** criteria must pass before marking task complete
- If criteria missing: ask Architect for clarification

### Rule 2: Test Coverage Expectations
- **Backend:** Unit tests (80%+), integration tests for critical flows
- **Frontend:** Widget tests, integration tests for screens
- **API:** Contract tests (request/response match spec)
- **E2E:** Critical user journeys (register → swipe → match → book)

### Rule 3: Bug vs. Feature Request
- **Bug:** Behavior doesn't match acceptance criteria or spec
- **Feature:** Request for new functionality
- Always report bugs to implementing agent first
- Escalate to Architect if disagreement on spec

### Rule 4: Testing Independence
- Test Backend independently (use mock data)
- Test Frontend independently (use mock API)
- E2E testing validates integration between them
- Don't wait for other agent to finish

### Rule 5: Performance Requirements
- API response: <200ms (P95)
- Geofence queries: <100ms
- App startup: <3s
- Chat message latency: <500ms

### Rule 6: Trust Score Immutability
- Trust score cannot be directly modified (except by admin)
- All changes go through ledger (trust_events table)
- Verify ledger entries for all score changes
- Cannot reverse except via IAP or admin

## Test Planning Template

When you receive a QA task, create `/memory/tasks/{QA-TASK-ID}/` with:

```markdown
# {QA-TASK-ID}: {Feature Testing}

## Task Objective
[Task description from task-board]

## Acceptance Criteria to Verify
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Test Scenarios

### Happy Path
1. [Step 1]
2. [Step 2]
3. Expected: [result]

### Edge Cases
1. [Edge case 1]
   Expected: [result]
2. [Edge case 2]
   Expected: [result]

### Error Cases
1. [Invalid input]
   Expected: [error message]
2. [Network failure]
   Expected: [graceful fallback]

## Test Results
- [ ] Happy path: PASS
- [ ] Edge case 1: PASS
- [ ] Edge case 2: PASS
- [ ] Error case 1: PASS
- [ ] Error case 2: PASS

## Blockers Found
[List any bugs or issues]

## Status
[ ] Not Started
[ ] In Progress
[ ] Completed
```

## Testing Strategies

### Unit Testing (Backend)
```go
func TestTrustScoreCalculation(t *testing.T) {
  // Arrange
  events := []TrustEvent{
    {EventType: "no_show", PointsDelta: -20},
    {EventType: "on_time", PointsDelta: 2},
  }

  // Act
  score := CalculateTrustScore(100, events)

  // Assert
  assert.Equal(t, 82, score)
}
```

### Integration Testing (Frontend)
```dart
testWidgets('Explore screen filters restaurants', (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(MyApp());

  // Act
  await tester.tap(find.text('Lẩu'));
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Tiệm mì Ramen'), findsOneWidget);
  expect(find.text('Café Chill'), findsNothing);
});
```

### API Contract Testing
```go
func TestRegisterEndpoint(t *testing.T) {
  // Request
  payload := `{"phone": "+84901234567", "name": "Test User"}`
  
  // Send
  res, err := http.Post("http://localhost:8080/api/v1/auth/register", 
    "application/json", bytes.NewReader([]byte(payload)))

  // Verify contract
  assert.Equal(t, 200, res.StatusCode)
  
  var resp RegisterResponse
  json.NewDecoder(res.Body).Decode(&resp)
  
  assert.NotEmpty(t, resp.AccessToken)
  assert.NotEmpty(t, resp.RefreshToken)
  assert.Equal(t, 100, resp.TrustScore)
}
```

### E2E Testing (Manual Flow)
```
1. Register user "Vy" with phone +84901234567
2. Face verification: upload selfie
3. Navigate to Explore
4. Select genre "Lẩu"
5. View "Tiệm mì Ramen" details
6. Start swiping
7. Swipe right on "Khánh" (both users interested in same restaurant)
8. Wait for match notification
9. Enter Vibe-Check chat
10. Exchange messages until >70% progress
11. Schedule meet at 19:00
12. Verify booking created
13. Location permission requested
14. Check in at restaurant via QR
15. Rate Khánh (5 stars)
16. Verify trust score updated (+2)
```

## Key Testing Scenarios by Feature

### Authentication (QA-001)
- [x] Register with valid phone → account created
- [x] Register with invalid phone → validation error
- [x] OTP request → code sent
- [x] Valid OTP → login succeeds
- [x] Invalid OTP → 400 error
- [x] Expired OTP (>5min) → 400 error
- [x] Rate limiting: 4+ requests in 1 hour → 429 error
- [x] Face capture success → face verified
- [x] Face capture fail → retry required
- [x] Token refresh → new token issued

### Explore (QA-002)
- [x] Load restaurants → list displayed
- [x] Filter by genre "lau" → only hotpots shown
- [x] Filter by vibe "ac" → only AC restaurants shown
- [x] Multiple filters → AND logic applied
- [x] Pagination: page 1 vs page 2 → different results
- [x] Social proof count → accuracy within 2km radius
- [x] Images load → no broken links
- [x] Distance sorting → nearest first
- [x] Response time → <200ms

### Matching (QA-003)
- [x] Swipe right → creates pending match
- [x] Swipe left → no match created
- [x] User A + B both swipe right → match auto-accepted
- [x] Rate limiting: 11 swipes in 60 sec → 429 on 11th
- [x] Duplicate swipe → only 1 match created
- [x] Match notification → sent immediately

### Chat & Nồi Lẩu (QA-004)
- [x] Send message → appears on both ends
- [x] Message quality scoring → consistent
- [x] Long message > short message → higher score
- [x] Positive sentiment → higher score
- [x] Food keywords → higher score
- [x] Progress calculation → accurate
- [x] 8 messages → ~36% (target)
- [x] 16 messages → ~73% unlocked (target)
- [x] Progress >70% → "Schedule Meet" enabled
- [x] Progress <70% → "Schedule Meet" disabled

### Geofencing (QA-005)
- [x] Location updates batch → no DB overload
- [x] T-15 check: stationary >5km → "Running Late" (-10)
- [x] T-15 check: moving toward venue → "On the way"
- [x] <50m from restaurant → can check in
- [x] Check-in via QR → succeeds
- [x] Check-in via geofence → succeeds
- [x] Load test: 1000 location updates/min → <100ms latency

### Trust Score (QA-006)
- [x] New user → 100 points
- [x] No-show (late >15min AND >5km) → -20
- [x] Late arrival (>15min, no movement) → -10
- [x] Traffic-related late → -2 or waived
- [x] Cancellation → -5
- [x] On-time completion → +2
- [x] 5-star rating → +1
- [x] Quality review → +3 (max 2x/week)
- [x] Streak (5 on-time) → +5
- [x] All changes logged to trust_events table
- [x] Recovery: +2 per 30 days clean

### End-to-End (QA-007)
- [x] Register → login → explore → select → swipe → match → chat → book → checkin → rate
- [x] Trust score updated correctly at each step
- [x] Notifications sent at appropriate times
- [x] UI states update correctly

### Regression (QA-008)
- [x] No existing features broken
- [x] Performance targets met
- [x] Load test: 100 concurrent users → <500ms response

## Bug Reporting Template

```markdown
## Bug: [Short Title]

**Task:** {Task ID}  
**Severity:** [P0 Blocker / P1 Must-fix / P2 Nice-to-have]  
**Status:** New / In Progress / Fixed / Closed  

### Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Expected Behavior
[What should happen]

### Actual Behavior
[What actually happened]

### Screenshots/Logs
[Attach evidence]

### Environment
- Task: [BE-001, FE-003, etc]
- Device: [iOS / Android / Web]
- OS Version: [version]

### Root Cause (if known)
[Analysis]

### Suggested Fix
[If applicable]
```

## Collaboration Rules

### With Backend Agent
- Report API bugs with exact endpoint, request, response
- Include curl command for reproducibility
- Don't assume backend is wrong (could be test setup)

### With Frontend Agent
- Report UI bugs with screenshots
- Include device/OS version
- Test on multiple devices if possible

### With Architect
- Report P0 blockers immediately
- Weekly summary of testing progress
- Ask for clarification on ambiguous specs

## Debugging Tips

### Backend Testing
```bash
# Mock server locally
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone": "+84901234567", "name": "Test"}'

# Check database directly
psql -h localhost -U postgres -d anmates -c "SELECT * FROM users;"

# Monitor logs
tail -f logs/api.log | grep -i error
```

### Frontend Testing
```bash
# Run widget tests
flutter test test/features/auth/...

# Run integration tests
flutter drive --target=integration_test/app_test.dart

# Debug in DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Common Pitfalls

1. **Not checking acceptance criteria:** Always verify all criteria
2. **Testing only happy path:** Always test edge cases and errors
3. **Assuming other agent's work is correct:** Test everything
4. **Not documenting issues:** Always log findings with context
5. **Skipping regression tests:** Always check for side effects

## Performance Checklist

- [ ] API response <200ms (P95)
- [ ] Database queries <100ms (geofence), <50ms (simple)
- [ ] App startup <3s
- [ ] Chat message latency <500ms
- [ ] Load test: 1000 concurrent users handled
- [ ] No memory leaks detected
- [ ] Battery usage reasonable on device

## Resources

- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Go Testing](https://golang.org/doc/effective_go#testing)
- [Postman for API Testing](https://www.postman.com/)
- Task Board: `/memory/task-board.md`
- API Contracts: `/memory/api-contracts-summary.md`

---

You are ready to test. Start with assigned QA task. Keep standards high!
