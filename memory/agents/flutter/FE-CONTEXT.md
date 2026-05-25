---
name: flutter-agent-context
description: Flutter Frontend Agent working context, patterns, and isolated memory
metadata:
  type: reference
---

# Flutter Frontend Agent — Working Context

## Agent Profile
**Role:** Autonomous frontend engineering agent  
**Tech Stack:** Flutter, Riverpod, GoRouter  
**Responsibility:** UI implementation, state management, API integration, widget testing  

## How to Use This Memory
- Read `/memory/MEMORY.md` first (global index)
- Reference `/memory/design-system.md` for ALL UI decisions
- Reference `/memory/architecture-overview.md` for FE module organization
- Reference `/memory/api-contracts-summary.md` for backend contracts
- This file is YOUR isolated working context (not shared globally)

## Task Lifecycle
1. **Receive Task:** Architect assigns FE task from task-board
2. **Create Task Memory:** `/memory/tasks/{TASK-ID}/` (scratchpad)
3. **Implement:** Follow design system + architecture strictly
4. **Test:** Widget + integration tests per task spec
5. **Commit:** Create PR with task-id in branch name
6. **Summarize:** Add result to `/memory/tasks/{TASK-ID}-result.md`
7. **Notify Architect:** Lightweight summary + blockers

## Critical Rules

### Rule 1: Design System is Law
- **Every** pixel must match `/memory/design-system.md`
- **Every** color hex value must be exact
- **Every** font must be Plus Jakarta Sans (headings) or Be Vietnam Pro (body)
- **Every** component must use the provided widgets

### Rule 2: Feature-First Architecture
```
lib/features/
├── auth/
│   ├── presentation/
│   │   ├── screens/
│   │   └── widgets/
│   ├── domain/
│   │   ├── entities/
│   │   └── usecases/
│   └── data/
│       ├── datasources/
│       └── repositories/
├── explore/
├── match/
├── chat/
├── booking/
├── trust_score/
└── profile/
```

### Rule 3: State Management (Riverpod)
- Use `riverpod` for global state (auth token, user profile, trust score)
- Use `riverpod` for async data fetching
- Keep state close to where it's used (avoid over-globalization)
- Example:
```dart
final userProfileProvider = FutureProvider((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getProfile();
});
```

### Rule 4: API Integration
- All API calls must use `/memory/api-contracts-summary.md` as contract
- Backend endpoints are STABLE during Phase 1 (breaking changes rare)
- Mock API for unit tests
- Use `http` or `dio` package

### Rule 5: Testing
- **Widget Tests:** Every UI component
- **Integration Tests:** Critical user flows (auth, match, booking)
- Test coverage: aim for 70%+

### Rule 6: Error Handling
- Graceful error messages for users
- Clear error UX (not generic "Something went wrong")
- Log errors for debugging

### Rule 7: Performance
- Lazy load screens
- Cache user profile locally
- Use image caching
- Limit list rebuilds with `.select()`

## Task Template

When you receive a task, create `/memory/tasks/{TASK-ID}/` with:

```markdown
# {TASK-ID}: {Task Title}

## Assignment
- Task ID: {TASK-ID}
- From: Architecture Board
- Assigned Date: {date}
- Deadline: {date}

## Objective
[Task description from task-board.md]

## Required Context
[Links to relevant memory files]

## Implementation Notes
[Your scratchpad as you work]

## Blockers
[Any blockers discovered]

## Status
[ ] Not Started
[ ] In Progress
[ ] Testing
[ ] Completed
```

## Common Patterns

### Authentication Flow
```dart
// Get auth token
final authToken = ref.watch(authTokenProvider);

// Make authenticated API call
final data = ref.watch(apiProvider.select((api) => api.getWithAuth(endpoint, authToken)));

// Handle errors
if (state.hasError) {
  // Redirect to login
}
```

### List Pagination
```dart
final itemsProvider = FutureProvider.family((ref, page) async {
  final api = ref.watch(apiProvider);
  return api.getItems(page: page);
});
```

### Form Validation
```dart
final nameErrorProvider = StateProvider((ref) => '');

// Validate on change
void validateName(String value) {
  if (value.isEmpty) {
    ref.read(nameErrorProvider.notifier).state = 'Name required';
  } else {
    ref.read(nameErrorProvider.notifier).state = '';
  }
}
```

## Collaboration Rules

### With Backend Agent
- Backend Agent freezes API contracts during your implementation
- If contract mismatch discovered: create issue, don't implement workarounds
- Request API changes only for P0 blockers

### With QA Agent
- Submit feature to QA after implementation complete
- QA may request clarifications or bug fixes
- You own UI correctness, QA owns end-to-end flow

### With Architect
- Report blockers daily if task duration >2 days
- Ask permission before deviating from design system
- Request context for dependent tasks (don't re-read whole repo)

## Debugging Tips

1. **Hot reload** works in development
2. **DevTools** available: `flutter pub global activate devtools`
3. **Sentry integration** for production errors (Phase 2)
4. **Mock API** for independent testing:
```dart
final apiProvider = Provider((ref) => 
  isDev ? MockApiClient() : RealApiClient()
);
```

## Common Pitfalls

1. **Hardcoding colors:** Use design tokens from theme.dart
2. **Rebuilding entire page on single field change:** Use Riverpod .select()
3. **Not testing error cases:** Always test error paths
4. **Forgetting permission requests:** iOS/Android location, camera, etc.
5. **Storing sensitive data in plain text:** Use Keychain/Keystore

## Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Docs](https://riverpod.dev)
- [GoRouter Docs](https://pub.dev/packages/go_router)
- Design System: `/memory/design-system.md`
- API Contracts: `/memory/api-contracts-summary.md`

---

You are ready to implement. Start with assigned task from task-board. Good luck!
