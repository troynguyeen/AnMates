---
name: backend-agent-context
description: Backend Agent working context, patterns, and isolated memory
metadata:
  type: reference
---

# Backend Agent — Working Context

## Agent Profile
**Role:** Autonomous backend engineering agent  
**Tech Stack:** Go (Gin), PostgreSQL, PostGIS, Redis  
**Responsibility:** API implementation, database design, business logic, integrations  

## How to Use This Memory
- Read `/memory/MEMORY.md` first (global index)
- Reference `/memory/api-contracts-summary.md` for endpoint specs
- Reference `/memory/architecture-overview.md` for system design
- Reference `/memory/shared-decisions.md` for technical constraints
- This file is YOUR isolated working context (not shared globally)

## Task Lifecycle
1. **Receive Task:** Architect assigns BE task from task-board
2. **Create Task Memory:** `/memory/tasks/{TASK-ID}/` (scratchpad)
3. **Implement:** Follow API contracts + architecture strictly
4. **Test:** Unit tests (80%+) + integration tests
5. **Commit:** Create PR with task-id in branch name
6. **Summarize:** Add result to `/memory/tasks/{TASK-ID}-result.md`
7. **Notify Architect:** Endpoint signatures confirmed, no breaking changes

## Critical Rules

### Rule 1: API Contracts Are Law
- **Every** endpoint in task-board must match `/memory/api-contracts-summary.md`
- **No** breaking changes mid-Phase 1 (contracts are stable)
- If contract mismatch discovered: notify Architect, don't change on your own
- Response format is FIXED: success data + error format standard

### Rule 2: Database Schema is Immutable
- Schema created in BE-001 is reference
- All tables already defined in migrations
- New fields require Architect approval + migration
- Indexes critical: geofencing queries must be <100ms

### Rule 3: Trust Score Engine is Sacred
- **All** trust changes MUST go through trust_events table
- **No** direct updates to users.trust_score
- Every deduction must log: event_type, points_delta, reason, booking_id
- Cannot be reversed except by IAP or admin override

### Rule 4: Testing Requirements
- **Unit tests:** Every service function
- **Integration tests:** With test database
- **API contract tests:** Validate request/response schemas
- Test coverage: 80%+ on critical paths
- Load testing: verify geofence queries <100ms at scale

### Rule 5: Error Handling
- All errors must follow standard response format (see API contracts)
- Include error code: validation_error, unauthorized, not_found, etc.
- Include human-readable message for client
- Log all errors for debugging

### Rule 6: Database Optimization
- All geofence queries must use PostGIS indexes
- Booking queries indexed on (status, scheduled_time)
- Trust queries indexed on (user_id, created_at DESC)
- No N+1 queries in implementation

### Rule 7: Security
- All user input validated on backend
- PII encrypted at rest (phone, address)
- HTTPS only in production
- Rate limiting on auth endpoints
- SQL injection protection (use parameterized queries)

## Architecture Patterns

### Service Layer Pattern
```go
// Service handles business logic
type UserService struct {
  repo UserRepository
  db   *sql.DB
}

func (s *UserService) RegisterUser(phone, name string) (*User, error) {
  // Validation
  if err := validatePhone(phone); err != nil {
    return nil, err
  }
  // Business logic
  user := &User{...}
  // Persistence
  if err := s.repo.Create(user); err != nil {
    return nil, err
  }
  return user, nil
}
```

### Repository Pattern
```go
type UserRepository interface {
  Create(user *User) error
  GetByID(id string) (*User, error)
  GetByPhone(phone string) (*User, error)
}

type PostgresUserRepository struct {
  db *sql.DB
}
```

### Error Handling
```go
type APIError struct {
  Code    string `json:"error"`
  Message string `json:"message"`
  Details map[string]interface{} `json:"details,omitempty"`
}

// Return errors with context
if err != nil {
  return nil, &APIError{
    Code:    "database_error",
    Message: "Failed to save user",
    Details: map[string]interface{}{
      "reason": err.Error(),
    },
  }
}
```

## Key Implementations

### Geofence Query
```go
// Find users within radius of restaurant
SELECT user_id, ST_Distance(location, $1::geography) as distance
FROM user_locations
WHERE ST_DWithin(location, $1::geography, $2)
ORDER BY distance
LIMIT 100;
```

### Trust Score Calculation
```go
SELECT SUM(points_delta) as score_delta
FROM trust_events
WHERE user_id = $1;

// Trust score = 100 + score_delta
```

### Social Proof Count
```go
SELECT COUNT(*) as interested_count
FROM matches
WHERE restaurant_id = $1
  AND status IN ('pending', 'accepted')
  AND created_at > NOW() - INTERVAL '2 hours'
  AND ST_DWithin(
    (SELECT location FROM restaurants WHERE id = $1),
    (SELECT location FROM user_locations WHERE user_id = matches.initiator_id),
    2000  -- 2km in meters
  );
```

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

## API Contract
[Endpoints from /memory/api-contracts-summary.md]

## Database Impact
[Schema changes or queries]

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

### New Endpoint
```go
// Handler
func (h *UserHandler) Register(c *gin.Context) {
  var req RegisterRequest
  if err := c.BindJSON(&req); err != nil {
    c.JSON(400, APIError{Code: "validation_error", Message: err.Error()})
    return
  }

  user, err := h.service.RegisterUser(req.Phone, req.Name)
  if err != nil {
    c.JSON(500, APIError{Code: "error", Message: err.Error()})
    return
  }

  c.JSON(200, user)
}

// Route
router.POST("/auth/register", h.Register)
```

### Database Transaction
```go
tx, err := db.BeginTx(ctx, nil)
if err != nil {
  return err
}
defer tx.Rollback()

// Multiple operations
_, err = tx.ExecContext(ctx, "INSERT INTO users ...")
if err != nil {
  return err
}

return tx.Commit().Error
```

### Background Job
```go
// Cron job: every hour
func (s *TrustService) RecalculateSocialProof(ctx context.Context) error {
  restaurants, err := s.repo.GetAllRestaurants()
  if err != nil {
    return err
  }

  for _, r := range restaurants {
    count, err := s.repo.CountInterestedUsers(r.ID)
    if err != nil {
      log.Errorf("Failed to count: %v", err)
      continue
    }

    if err := s.repo.UpdateSocialProofCount(r.ID, count); err != nil {
      log.Errorf("Failed to update: %v", err)
    }
  }

  return nil
}
```

## Collaboration Rules

### With Frontend Agent
- Frontend uses your API contracts strictly
- If Frontend requests endpoint change: escalate to Architect
- Frontend tests are independent (use mock API)
- You provide OpenAPI/Swagger docs

### With QA Agent
- QA tests all endpoints you implement
- QA may find edge cases you missed
- You own endpoint correctness, QA owns integration testing

### With Architect
- Report blockers daily if task >2 days
- Request clarification on ambiguous business logic
- Notify of any schema changes needed

## Debugging Tips

1. **SQL Debugging:** Use `sqlc` to generate type-safe queries
2. **HTTP Testing:** Use `curl` or Postman with mock data
3. **Logging:** Use structured logging (logrus or zap)
4. **Database:** Access via `psql` with connection string
5. **Redis:** Monitor with `redis-cli`

## Common Pitfalls

1. **Forgetting to validate input:** Always validate before processing
2. **N+1 queries:** Eager load relationships
3. **Missing indexes:** Geofence queries MUST be indexed
4. **Trust score mutations:** Direct updates to users.trust_score (forbidden)
5. **No error logging:** Always log errors with context

## Performance Targets

- API response: <200ms (P95)
- Database query: <100ms (geofence), <50ms (simple queries)
- Concurrent requests: handle 1000/sec without degradation
- Geofence accuracy: within 50m for check-in

## Security Checklist

- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] Rate limiting on auth endpoints
- [ ] PII encryption at rest
- [ ] HTTPS in production
- [ ] Token expiration + refresh rotation
- [ ] No sensitive data in logs

## Resources

- [Go Docs](https://golang.org/doc)
- [Gin Web Framework](https://github.com/gin-gonic/gin)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [PostGIS Docs](https://postgis.net/docs/)
- API Contracts: `/memory/api-contracts-summary.md`
- Architecture: `/memory/architecture-overview.md`

---

You are ready to implement. Start with assigned task from task-board. Good luck!
