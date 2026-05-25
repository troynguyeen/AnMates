# 🎯 AnMates MVP - Task Breakdown for Local LLM
> Optimized for small context windows (local AI models like Qwen, Llama, Mistral)
> Each task ~2-4K tokens, focused, self-contained

---

## Task Sequence Overview

```
Phase 1: Backend Foundation (Weeks 1-2)
├─ Task 1: Complete User Auth Service
├─ Task 2: Create User Endpoints (Register/Login/Profile)
├─ Task 3: Build Food Wishlist Module
├─ Task 4: Implement Wishlist Endpoints
├─ Task 5: Create Matching Algorithm Service
└─ Task 6: Add Matching Endpoints

Phase 2: Core Features (Weeks 3-4)
├─ Task 7: Build Trust Score System
├─ Task 8: Create Chat/Message Module
├─ Task 9: Add Real-time Socket.io Setup
├─ Task 10: Implement Payment Integration (MoMo/ZaloPay)
└─ Task 11: Add Safety Features (Block, Report, Moderation)

Phase 3: Frontend UI (Weeks 5-6)
├─ Task 12: Build Onboarding Screen + Face Verification
├─ Task 13: Create Food Wishlist Screen
├─ Task 14: Implement Matching/Discovery Screen
├─ Task 15: Build Vibe-Check Chat UI with Progress Bar
├─ Task 16: Create Gom Kèo Deal Screen
└─ Task 17: Add Profile & Trust Score Dashboard

Phase 4: Testing & Deployment (Weeks 7-8)
├─ Task 18: API Testing & Error Handling
├─ Task 19: Frontend Testing & Polish
├─ Task 20: Docker Compose Setup
└─ Task 21: Deployment & Go-Live Checklist
```

---

## TASK 1: Complete User Auth Service

**Context**: Build the authentication logic for registration, login, and JWT token management.

**Input Files**:
- `backend/src/modules/auth/auth.service.ts` (create/update)
- `backend/src/modules/auth/strategies/jwt.strategy.ts` (already exists)

**Output**: Working auth service with:
- User registration with password hashing
- Login with JWT token generation
- Token validation and refresh

**Implementation Steps**:
1. Create `AuthService` with `register()`, `login()`, `validateToken()` methods
2. Use bcryptjs for password hashing
3. Generate JWT tokens with 24h expiration
4. Add email validation
5. Handle errors (duplicate email, wrong password, etc)

**Acceptance Criteria**:
- ✅ Register new user with email + password
- ✅ Login returns valid JWT token
- ✅ Password stored as bcrypt hash (not plain text)
- ✅ Token contains user ID and email
- ✅ Invalid credentials return error

**Local LLM Prompt Template**:
```
You are a NestJS backend expert. Implement the AuthService for user authentication.

File: backend/src/modules/auth/auth.service.ts

Requirements:
1. register(email, password, firstName, lastName) - Create new user, hash password
2. login(email, password) - Validate credentials, return JWT token
3. validateUser(id) - Verify JWT token still valid

Use:
- bcryptjs for password hashing
- JWT with 24h expiration
- PostgreSQL User entity

Keep it simple, no external APIs yet. Return only the service code.
```

---

## TASK 2: Create User Endpoints (Auth Routes)

**Context**: Build the REST API endpoints for /auth/register, /auth/login, /users/profile

**Input Files**:
- `backend/src/modules/auth/auth.controller.ts` (create/update)
- `backend/src/modules/users/users.controller.ts` (create/update)

**Output**: Working API endpoints:
- POST /auth/register
- POST /auth/login
- GET /users/profile (protected)

**Acceptance Criteria**:
- ✅ POST /auth/register accepts {email, password, firstName, lastName}
- ✅ POST /auth/login accepts {email, password}, returns {token, user}
- ✅ GET /users/profile requires JWT, returns user data
- ✅ All responses include proper error messages
- ✅ Input validation (email format, password length, etc)

**Local LLM Prompt Template**:
```
Implement REST API controllers for user authentication in NestJS.

Files:
- backend/src/modules/auth/auth.controller.ts
- backend/src/modules/users/users.controller.ts

Endpoints needed:
1. POST /auth/register - call authService.register()
2. POST /auth/login - call authService.login()
3. GET /users/profile - protected route, return current user

Use JWT guard for protected routes.
Include input validation DTOs.
Keep it minimal, focused on auth only.
```

---

## TASK 3: Build Food Wishlist Module

**Context**: Create the data model and service for managing user food preferences/wishlist.

**Input Files**:
- `backend/src/modules/food-wishlist/entities/food-wishlist.entity.ts` (already exists, may need updates)
- `backend/src/modules/food-wishlist/food-wishlist.service.ts` (create)
- `backend/src/modules/food-wishlist/food-wishlist.module.ts` (create)

**Output**: Food Wishlist service with CRUD operations

**Entity Properties**:
- id, userId, placeName, placeLat, placeLng, cuisineType, status
- status: "looking_for_company" | "solo" | "completed"
- timestamps: createdAt, updatedAt

**Acceptance Criteria**:
- ✅ Add food item to wishlist
- ✅ Get user's wishlist items
- ✅ Update wishlist item status
- ✅ Delete wishlist item
- ✅ Filter by status (looking_for_company, solo, completed)

**Local LLM Prompt Template**:
```
Create FoodWishlistService for managing user food preferences.

File: backend/src/modules/food-wishlist/food-wishlist.service.ts

Entity fields: id, userId, placeName, placeLat, placeLng, cuisineType, status, createdAt

Methods needed:
1. addItem(userId, placeName, lat, lng, cuisine) - Create wishlist item
2. getItems(userId, status?) - Get user's items, optionally filter by status
3. updateStatus(itemId, newStatus) - Change item status
4. deleteItem(itemId) - Remove item

Keep it simple CRUD, no matching logic yet.
Use TypeORM repository pattern.
```

---

## TASK 4: Implement Wishlist Endpoints

**Context**: Build API routes for managing food wishlist

**Input Files**:
- `backend/src/modules/food-wishlist/food-wishlist.controller.ts` (create)

**Output**: REST API endpoints for wishlist operations

**Endpoints**:
- POST /wishlist - Add item
- GET /wishlist - List user's items
- PATCH /wishlist/:id - Update status
- DELETE /wishlist/:id - Remove item

**Acceptance Criteria**:
- ✅ All endpoints require JWT authentication
- ✅ POST accepts {placeName, placeLat, placeLng, cuisineType}
- ✅ Returns 201 on success, 400 on validation error
- ✅ GET returns array of wishlist items
- ✅ User can only access their own wishlist

**Local LLM Prompt Template**:
```
Create REST API controller for Food Wishlist in NestJS.

File: backend/src/modules/food-wishlist/food-wishlist.controller.ts

Routes (all protected with JWT):
1. POST /wishlist - addItem()
2. GET /wishlist?status=looking_for_company - getItems()
3. PATCH /wishlist/:id - updateStatus()
4. DELETE /wishlist/:id - deleteItem()

Call FoodWishlistService methods.
Include validation DTOs.
Ensure user isolation (only see own items).
```

---

## TASK 5: Create Matching Algorithm Service

**Context**: Implement the core matching logic based on shared food wishlist items

**Input Files**:
- `backend/src/modules/matching/matching.service.ts` (create)
- `backend/src/modules/matching/entities/match.entity.ts` (already exists, update if needed)

**Output**: Matching service that finds compatible users

**Algorithm** (MVP simple version):
1. For user A, find all users B with shared wishlist items
2. Calculate match score: count of shared items * 10 points
3. Add proximity bonus: within 2km radius * 5 points
4. Filter by trust score >= 30
5. Sort by score descending, limit to top 10

**Acceptance Criteria**:
- ✅ findMatches(userId) returns top 10 potential matches
- ✅ Each match includes: userId, name, avatar, matchScore, sharedItems count
- ✅ No self-matches
- ✅ No duplicate matches in list
- ✅ Respects user blocking (if user blocked A, don't show A)

**Local LLM Prompt Template**:
```
Implement matching algorithm service for food-based pairing.

File: backend/src/modules/matching/matching.service.ts

Function: findMatches(userId, userLat, userLng)

Algorithm:
1. Query all wishlist items for current user (status = "looking_for_company")
2. Find other users with same cuisine types / place names
3. Calculate score: shared_items_count * 10 + (proximity_bonus if <2km) * 5
4. Filter: trust_score >= 30, not blocked, not already matched
5. Sort by score DESC, limit 10

Return: [{userId, name, avatar, matchScore, sharedItems: []}]

Use TypeORM query builder for efficiency.
Keep it pure logic, no API calls yet.
```

---

## TASK 6: Add Matching Endpoints

**Context**: Build API to retrieve potential matches for a user

**Input Files**:
- `backend/src/modules/matching/matching.controller.ts` (create)

**Output**: REST API endpoint for discovering matches

**Endpoint**:
- GET /matches - Return list of potential matches based on location

**Acceptance Criteria**:
- ✅ Requires JWT authentication
- ✅ Returns array of match objects with user info + match reason
- ✅ Includes pagination (page, limit)
- ✅ Caches results for 1 hour (Redis)
- ✅ Returns 200 with empty array if no matches found

**Local LLM Prompt Template**:
```
Create matching controller for discovering potential dining partners.

File: backend/src/modules/matching/matching.controller.ts

Route:
GET /matches?page=1&limit=10&lat=10.8231&lng=106.6797

This calls MatchingService.findMatches(userId, lat, lng)

Response format:
{
  data: [{userId, name, avatar, matchScore, sharedItems, trustScore}],
  pagination: {page, limit, total}
}

Include input validation for lat/lng.
Require JWT auth.
```

---

## TASK 7: Build Trust Score System

**Context**: Implement the core trust scoring logic that determines user reliability

**Input Files**:
- `backend/src/modules/trust-score/trust-score.service.ts` (create)
- `backend/src/modules/trust-score/entities/trust-score.entity.ts` (already exists)

**Output**: Trust score calculation and tracking service

**Scoring Rules** (MVP):
- New user: starts at 20 points
- Complete profile: +10
- Face verification: +15
- Successful meet (both rate positive): +5
- No-show (miss scheduled meet): -15
- Negative rating received: -5
- Report filed against: -10
- Min: 0, Max: 100+

**Acceptance Criteria**:
- ✅ getTrustScore(userId) returns current score
- ✅ addPoints(userId, points, reason) logs point change
- ✅ calculateScore(userId) recalculates from history
- ✅ Points have timestamps and reasons
- ✅ Score history queryable for admin

**Local LLM Prompt Template**:
```
Implement Trust Score system for user reliability tracking.

File: backend/src/modules/trust-score/trust-score.service.ts

Methods:
1. initializeScore(userId) - New user gets 20 points
2. getTrustScore(userId) - Get current score (sum of all point changes)
3. addPoints(userId, points, reason) - Log point change
4. getScoreHistory(userId) - Get list of all changes with timestamps

Scoring events:
- Profile complete: +10
- Face verified: +15
- Positive meet rating: +5
- No-show: -15
- Negative rating: -5
- Report filed: -10

Min 0, Max 100+.
Store in TrustScore entity with userId, points, reason, createdAt.
```

---

## TASK 8: Create Chat/Message Module

**Context**: Build the data model for storing and retrieving chat messages

**Input Files**:
- `backend/src/modules/chat/chat.module.ts` (create)
- `backend/src/modules/chat/entities/message.entity.ts` (create)
- `backend/src/modules/chat/chat.service.ts` (create)

**Output**: Chat service for storing and retrieving messages

**Entity**:
- id, matchId, senderId, recipientId, content, type (text|image|audio)
- progressBar (0-100), timestamps, isRead

**Acceptance Criteria**:
- ✅ saveMessage(matchId, senderId, content, type)
- ✅ getMessages(matchId, page, limit) - paginated
- ✅ markAsRead(messageId)
- ✅ updateProgressBar(matchId, newValue)
- ✅ Messages ordered by timestamp ascending

**Local LLM Prompt Template**:
```
Create Chat/Message module for real-time conversations between matched users.

Files:
1. backend/src/modules/chat/entities/message.entity.ts
2. backend/src/modules/chat/chat.service.ts

Entity Message:
- id, matchId, senderId, recipientId, content, messageType
- progressBar (0-100, for Nồi Lẩu progress), isRead, createdAt, updatedAt

ChatService methods:
1. saveMessage(matchId, senderId, content, type) 
2. getMessages(matchId, page=1, limit=50) - paginated, ordered by time
3. markAsRead(messageIds[])
4. updateProgressBar(matchId, newValue 0-100)
5. getUnreadCount(userId)

No real-time yet, just CRUD.
```

---

## TASK 9: Add Real-time Socket.io Setup

**Context**: Configure WebSocket for real-time chat messaging

**Input Files**:
- `backend/src/modules/chat/chat.gateway.ts` (create)
- `backend/src/main.ts` (update to enable WebSocket)

**Output**: WebSocket server for live messaging

**Events**:
- 'message' - Send message in real-time
- 'message:read' - Mark message as read
- 'typing' - User is typing indicator
- 'progress:update' - Nồi Lẩu progress bar changes
- 'disconnect' - User goes offline

**Acceptance Criteria**:
- ✅ Socket.io server listening on same port as API
- ✅ Users connect with JWT token verification
- ✅ Messages broadcast to both participants
- ✅ Typing indicators work
- ✅ Progress bar updates emit to both users
- ✅ Graceful disconnect handling

**Local LLM Prompt Template**:
```
Setup WebSocket (Socket.io) for real-time messaging in NestJS.

File: backend/src/modules/chat/chat.gateway.ts

Socket events to implement:
1. connect(client, token) - Verify JWT, join room
2. message(matchId, content) - Emit to both users, save to DB
3. typing(matchId) - Broadcast to other user
4. progress:update(matchId, value) - Update Nồi Lẩu bar for both
5. disconnect() - User goes offline

Use rooms: matchId-user1-user2 for isolation.
Keep messages in DB for persistence (don't lose if offline).
No memory leaks - clean up rooms on disconnect.
```

---

## TASK 10: Implement Payment Integration (MoMo/ZaloPay)

**Context**: Integrate MoMo and ZaloPay for conditional deposits

**Input Files**:
- `backend/src/modules/payment/payment.service.ts` (create)
- `backend/src/modules/payment/payment.controller.ts` (create)
- `backend/src/modules/payment/entities/transaction.entity.ts` (create)

**Output**: Payment integration for 20k VND deposits (only for trust score < 60)

**Flow**:
1. User with trust < 60 attempts to create invite
2. API returns payment QR code (MoMo or ZaloPay)
3. User scans and pays 20k VND
4. Webhook callback confirms payment
5. Deposit stored, invite allowed

**Acceptance Criteria**:
- ✅ POST /payment/initiate - Generate payment QR
- ✅ Webhook handler for payment success/failure
- ✅ Transaction logged in database
- ✅ Refund issued after successful meet + positive rating
- ✅ No manual handling of real money

**Local LLM Prompt Template**:
```
Implement payment integration for conditional deposits.

Files:
1. backend/src/modules/payment/payment.service.ts
2. backend/src/modules/payment/payment.controller.ts
3. Transaction entity

Endpoints:
1. POST /payment/initiate?amount=20000&matchId=X
   - Returns {qrCode, paymentUrl}
   - Calls MoMo or ZaloPay API
   
2. POST /payment/webhook (from MoMo/ZaloPay)
   - Receive payment confirmation
   - Update transaction status
   - Unlock invite if paid

Methods:
- initiatePayment(userId, amount, matchId)
- handleWebhook(paymentId, status)
- getTransaction(transactionId)
- refundTransaction(transactionId)

Use MoMo/ZaloPay SDK (don't store card numbers).
Keep it simple, sandbox mode for testing.
```

---

## TASK 11: Add Safety Features (Block, Report, Moderation)

**Context**: Build user safety mechanisms

**Input Files**:
- `backend/src/modules/safety/safety.service.ts` (create)
- `backend/src/modules/safety/entities/block.entity.ts` (create)
- `backend/src/modules/safety/entities/report.entity.ts` (create)

**Output**: Block/Report/Moderation system

**Features**:
- Block users (hide from matches)
- Report inappropriate behavior
- Auto-moderate messages (ban certain words)
- Flag users for admin review

**Acceptance Criteria**:
- ✅ POST /safety/block/:userId - Block user
- ✅ POST /safety/report/:userId - File report with reason
- ✅ GET /safety/blocks - Get user's blocked list
- ✅ Messages with flagged words get marked
- ✅ Reports visible to admins only

**Local LLM Prompt Template**:
```
Implement safety features for protecting users.

Files:
1. backend/src/modules/safety/safety.service.ts
2. Block and Report entities

Methods:
1. blockUser(userId, blockTargetId) - Add to blocklist
2. unblockUser(userId, blockTargetId)
3. reportUser(userId, reportedId, reason, description)
4. getBlockedUsers(userId)
5. getReports(adminOnly, status)
6. moderateMessage(content) - Check for flagged words

Entity fields:
- Block: userId, blockedUserId, createdAt
- Report: id, reporterId, reportedId, reason, description, status, createdAt

Reasons: harassment, inappropriate, scam, other
Statuses: pending, reviewed, resolved, dismissed

Keep admin review manual (don't auto-ban).
```

---

## TASK 12: Build Onboarding Screen + Face Verification

**Context**: Create mobile UI for user signup and face verification

**Input Files**:
- `frontend/src/screens/OnboardingScreen.tsx` (update)
- `frontend/src/screens/RegisterScreen.tsx` (create)
- `frontend/src/components/FaceVerification.tsx` (create)

**Output**: Multi-step onboarding flow

**Steps**:
1. Register (email, password, name)
2. Face verification photo
3. Food preferences (cuisine tags)
4. Personality type (optional)
5. Location permission

**Acceptance Criteria**:
- ✅ Step-by-step flow with progress indicator
- ✅ Face photo upload (camera or gallery)
- ✅ Cuisine tag selection (checkboxes)
- ✅ Form validation
- ✅ All data sent to API on completion
- ✅ Navigation to home screen after success

**Local LLM Prompt Template**:
```
Create Onboarding screen flow for new user registration.

Files:
1. frontend/src/screens/RegisterScreen.tsx
2. frontend/src/screens/OnboardingStep2_FaceVerification.tsx
3. frontend/src/screens/OnboardingStep3_Preferences.tsx

Requirements:
- Multi-step flow (3-4 screens)
- Step 1: Email, Password, Name validation
- Step 2: Face photo (camera or gallery)
- Step 3: Cuisine preferences (multi-select tags)
- Progress bar showing steps
- Next/Back buttons
- Call API to register user

Style: Use brand colors (Berry Crush #D62246, Mint Cream background)
Font: Be Vietnam Pro
Keep it lightweight, React Native (Expo).

No complex UI animations yet, simple and clear.
```

---

## TASK 13: Create Food Wishlist Screen

**Context**: Build UI for users to add and manage food items they want to try

**Input Files**:
- `frontend/src/screens/WishlistScreen.tsx` (update)
- `frontend/src/components/WishlistItem.tsx` (create)
- `frontend/src/components/AddWishlistModal.tsx` (create)

**Output**: Functional wishlist management UI

**Features**:
- List all user's wishlist items
- Show status: "looking_for_company", "solo", "completed"
- Add new item (modal with location search)
- Edit status (swipe or tap)
- Delete item (swipe left)
- Filter by status

**Acceptance Criteria**:
- ✅ FlatList displaying wishlist items
- ✅ Item cards show place name, cuisine, status
- ✅ Add button opens modal
- ✅ Modal has place search (from Google Places API)
- ✅ Status change updates immediately
- ✅ Delete confirmation dialog
- ✅ Empty state message if no items

**Local LLM Prompt Template**:
```
Create Food Wishlist screen for React Native app.

File: frontend/src/screens/WishlistScreen.tsx

UI elements:
1. Header: "My Foodie Wishlist" + Add button
2. FlatList of items with:
   - Place name, cuisine tags, status badge
   - Swipe left to delete
   - Tap to edit status dropdown
3. Modal for adding new item:
   - Location search (integrate Google Places or mock)
   - Cuisine type multi-select
   - Save button calls API

Colors: Berry Crush for Add button, Mint Cream background
Font: Plus Jakarta Sans headings, Be Vietnam Pro body
Loading state while fetching items
Empty state: "Add your first food adventure!"

API calls: GET /wishlist, POST /wishlist, PATCH /wishlist/:id, DELETE /wishlist/:id
```

---

## TASK 14: Implement Matching/Discovery Screen

**Context**: Build the main discovery UI where users see potential matches

**Input Files**:
- `frontend/src/screens/MatchingScreen.tsx` (update)
- `frontend/src/components/MatchCard.tsx` (create)

**Output**: Swipe/tap card interface for discovering matches

**Features**:
- Display matches as cards (show name, avatar, shared items)
- Pull fresh matches from API
- Match reason (X shared items)
- Trust score badge
- Actions: Chat, Skip, Report
- "Hôm nay ăn gì?" roulette button

**Acceptance Criteria**:
- ✅ Card displays user avatar, name, age, match score
- ✅ Shows shared food items (e.g., "You both want to try Phở King")
- ✅ Trust score displayed as badge (color-coded: green >75, yellow 60-75, orange <60)
- ✅ Chat button opens chat screen
- ✅ Skip loads next match
- ✅ No matches returns helpful message with suggestions
- ✅ Roulette button shows random suggestion

**Local LLM Prompt Template**:
```
Create Matching Discovery screen for finding dining partners.

File: frontend/src/screens/MatchingScreen.tsx

UI:
1. Header with "Find Your Mates" + Roulette button
2. Card-based layout (or simple list) showing:
   - Avatar (large)
   - Name, age, match score
   - Shared items: "You both want to try: [Place Name]"
   - Trust score badge (color-coded)
   - Action buttons: Chat, Skip
3. Pull-to-refresh to get new matches
4. Empty state: "No matches yet. Keep adding to your wishlist!"

Card components:
- MatchCard.tsx for individual match display
- Shows matchScore reason

API: GET /matches?page=1&limit=10&lat=X&lng=Y

Actions:
- Chat button → Navigate to ChatScreen with matchId
- Skip → Remove from list, load next
- Report → Open modal

Colors: Wisteria (#80649F) for accent
```

---

## TASK 15: Build Vibe-Check Chat UI with Progress Bar

**Context**: Create the core chat interface with Nồi Lẩu progress bar

**Input Files**:
- `frontend/src/screens/ChatScreen.tsx` (update)
- `frontend/src/components/NotoiLauProgressBar.tsx` (create)
- `frontend/src/components/IceBreakerGame.tsx` (create)

**Output**: Real-time chat with progress visualization

**Features**:
- Message list (sent/received)
- Input box with send button
- Progress bar shaped like Nồi Lẩu (boiling pot)
- Ice-breaker mini-game to unlock invite
- Typing indicators
- Read receipts

**Acceptance Criteria**:
- ✅ WebSocket-based real-time messages
- ✅ Nồi Lẩu progress bar animates (0-100%)
- ✅ Ice-breaker game shows 3 quick choices
- ✅ At 70%+ progress, "Send Invite" button appears
- ✅ Messages show timestamps
- ✅ User avatars in message bubbles
- ✅ "Typing..." indicator when other user types
- ✅ Scroll to bottom auto on new message

**Local LLM Prompt Template**:
```
Create Vibe-Check Chat screen with Nồi Lẩu progress bar.

Files:
1. frontend/src/screens/ChatScreen.tsx
2. frontend/src/components/NotoiLauProgressBar.tsx
3. frontend/src/components/IceBreakerGame.tsx
4. frontend/src/components/ChatMessage.tsx

Chat features:
- Real-time messaging via Socket.io
- Message list with avatars, timestamps
- Input box + send button
- Typing indicator
- Scroll to bottom on new message

Progress bar (Nồi Lẩu):
- Animated SVG or Lottie component
- Shows 0-100% fill (like pot boiling)
- Updates when messages sent
- Color: Wisteria (#80649F)

Ice-breaker game:
- Shows 3 quick reply options (JSON-based, no API calls)
- Examples: "What's your favorite cuisine?", "Best food memory?", "Dream dinner?"
- Clicking sends message + increases progress by 10-15%

At 70%+ progress: Show "Send Dining Invite" button

Styling: Mint Cream background, Berry Crush buttons
```

---

## TASK 16: Create Gom Kèo Deal Screen

**Context**: Build the viral deal-sharing feature with shareable cards

**Input Files**:
- `frontend/src/screens/GomKeoScreen.tsx` (create)
- `frontend/src/components/VeGomKeo.tsx` (create)

**Output**: Deal discovery and sharing interface

**Features**:
- Browse deals/discounts at restaurants
- Create custom "Tấm Vé" (boarding pass style card)
- Share via QR code, link, or social
- Deep link opens chat with invited friend
- Track shares

**Acceptance Criteria**:
- ✅ List of available deals (from Places API or hardcoded)
- ✅ Deal cards show restaurant, discount, validity
- ✅ "Create Gom Kèo" button opens modal
- ✅ Generate shareable QR code (contains deep link)
- ✅ Card styled like boarding pass (9:16 aspect, dí dỏm text)
- ✅ Share button (copy link, QR image download)
- ✅ Deep link: `anmates://gom-keo/DEAL_ID` opens chat suggestion
- ✅ Track number of shares (for growth)

**Local LLM Prompt Template**:
```
Create Gom Kèo (Deal Sharing) screen for viral growth.

Files:
1. frontend/src/screens/GomKeoScreen.tsx
2. frontend/src/components/VeGomKeo.tsx (Tấm Vé card)

UI:
1. Header: "Gom Kèo Săn Deal"
2. List of deals:
   - Restaurant name, location
   - Discount (e.g., -20% off appetizers)
   - Validity period
   - Button: "Rủ ai cùng?"

3. Modal for creating Gom Kèo:
   - Select deal
   - Optional custom text
   - Generate QR code
   - Show as 9:16 card (like boarding pass)
   - Tagline: "Săn deal có hội, ăn tối có đôi"

4. Share options:
   - Copy deep link
   - Download QR image
   - Share to contacts (ask friends)

Card style: Boarding pass themed, dí dỏm tone
Colors: Berry Crush accent, Mint Cream background
Font: Plus Jakarta Sans for flashy elements

Deep link: Handle anmates://gom-keo/:dealId in navigation
QR should contain: {type: 'gom_keo', dealId, text}
```

---

## TASK 17: Add Profile & Trust Score Dashboard

**Context**: Show user profile and trust score visualization

**Input Files**:
- `frontend/src/screens/ProfileScreen.tsx` (update)
- `frontend/src/components/TrustScoreCard.tsx` (create)
- `frontend/src/components/BadgesList.tsx` (create)

**Output**: User profile with trust metrics

**Features**:
- User avatar, name, bio
- Trust score display (0-100 gauge)
- Badges (Foodie Explorer, Trusted Mate, etc)
- Verified indicators
- Stats (successful meets, rating average)
- Edit profile button
- Logout button

**Acceptance Criteria**:
- ✅ Profile photo (large)
- ✅ Trust score shown as gauge/circular progress (color-coded)
- ✅ Explanation: "Your trust score helps others feel safe"
- ✅ Badges displayed with icons
- ✅ Stats row: Meets, Avg Rating
- ✅ Edit button opens profile edit modal
- ✅ Logout button with confirmation

**Local LLM Prompt Template**:
```
Create Profile screen showing user info and Trust Score.

Files:
1. frontend/src/screens/ProfileScreen.tsx
2. frontend/src/components/TrustScoreCard.tsx
3. frontend/src/components/UserStatsRow.tsx

UI sections:
1. Avatar + Name (editable)
2. Bio/About section (editable)
3. Trust Score Card:
   - Circular progress gauge (0-100)
   - Color: Green (75+), Yellow (60-74), Orange (<60)
   - Text: "Trusted Mate" or "Building Trust"
   - Help text explaining what affects score
4. Badges section:
   - Grid of earned badges with icons
   - Examples: "Foodie Explorer", "Trusted Mate", "Vibe-Check Master"
5. Stats row:
   - Successful meets count
   - Average rating (stars)
   - "Best Ăn Mates" link
6. Edit Profile button → Modal for name, bio, photo
7. Settings + Logout

Colors: Wisteria for trust score gauge
Styling: Clean, minimal, supportive tone
```

---

## TASK 18: API Testing & Error Handling

**Context**: Add comprehensive error handling and API validation

**Input Files**:
- `backend/src/common/filters/http-exception.filter.ts` (create)
- `backend/src/common/guards/rate-limit.guard.ts` (create)
- Test files for each module

**Output**: Robust error handling across all endpoints

**Features**:
- Global exception filter
- Rate limiting (1 request per 2 seconds per user)
- Input validation (DTOs)
- Proper HTTP status codes
- Error message formatting
- Logging

**Acceptance Criteria**:
- ✅ All endpoints return consistent error format
- ✅ Rate limiting enforced (429 Too Many Requests)
- ✅ Input validation returns 400 with field errors
- ✅ 401 for missing/invalid JWT
- ✅ 403 for insufficient permissions
- ✅ 404 for not found
- ✅ 500 for server errors with unique request ID
- ✅ All errors logged with timestamp

**Local LLM Prompt Template**:
```
Implement error handling and rate limiting for AnMates API.

Files:
1. backend/src/common/filters/http-exception.filter.ts
2. backend/src/common/guards/rate-limit.guard.ts
3. backend/src/common/decorators/rate-limit.decorator.ts

Requirements:
1. Global exception filter:
   - Catch all exceptions
   - Return format: {statusCode, message, timestamp, path, requestId}
   - Log to file or console with timestamp
   
2. Rate limiting:
   - 1 request per 2 seconds per user ID
   - Return 429 with retry-after header
   - Store in Redis for distributed rate limiting

3. Input validation DTOs:
   - Use class-validator for all endpoints
   - Return 400 with field-specific errors
   - Example: {field: 'email', message: 'must be valid email'}

Error responses:
- 401: "Unauthorized - Invalid or missing token"
- 403: "Forbidden - Insufficient permissions"
- 404: "Not found"
- 400: "Validation error" + field details
- 429: "Too many requests"
- 500: "Internal server error" + requestId for support

Use middleware for rate limiting.
```

---

## TASK 19: Frontend Testing & Polish

**Context**: Test all screens and fine-tune UI/UX

**Input Files**:
- All frontend screen files
- `frontend/src/styles/theme.ts` (update)

**Output**: Polished, working app ready for beta

**Testing Checklist**:
- [ ] All screens navigate correctly
- [ ] Forms validate input
- [ ] API calls work (mock if needed)
- [ ] Images load properly
- [ ] Text doesn't overflow
- [ ] Colors match brand guidelines
- [ ] Fonts render correctly
- [ ] Touch targets are 44x44pt minimum
- [ ] Dark mode works (if supported)
- [ ] Keyboard handling on inputs

**Acceptance Criteria**:
- ✅ No console errors or warnings
- ✅ All screens load within 2 seconds
- ✅ Smooth animations (no jank)
- ✅ Forms functional with validation
- ✅ Messages in RTL work (for Vietnamese)
- ✅ Consistent spacing and alignment
- ✅ Accessible (buttons tappable, colors contrasting)

**Local LLM Prompt Template**:
```
Polish and test frontend React Native app.

Areas to check:
1. Screen navigation - All transitions work
2. Form validation - Show errors clearly
3. API integration - Mock if real API not ready
4. Loading states - Show spinner while fetching
5. Error states - Show retry option on failure
6. Empty states - Helpful messages when no data
7. Styling consistency:
   - Colors: Berry Crush, Wisteria, Mint Cream used correctly
   - Fonts: Plus Jakarta Sans (headings), Be Vietnam Pro (body)
   - Spacing: 8px grid (8, 16, 24, 32)
8. Accessibility:
   - Touch targets 44x44pt minimum
   - Color contrast WCAG AA
   - Text labels for buttons

Add loading indicators for all API calls.
Add error boundaries to catch crashes.
Add success messages for actions (toast notifications).
```

---

## TASK 20: Docker Compose Setup

**Context**: Containerize all services for production deployment

**Input Files**:
- Create: `docker-compose.yml`
- Create: `Dockerfile` (backend)
- Create: `Dockerfile` (frontend - or use Expo EAS)
- Create: `nginx/nginx.conf`
- Create: `.env.example`
- Create: `backup-mvp.sh`
- Create: `deploy-mvp.sh`

**Output**: Complete deployment stack ready to run

**Services**:
- Nginx (reverse proxy, rate limiting)
- Backend API (NestJS)
- PostgreSQL (database)
- Redis (cache, rate limiting)
- MinIO (file storage for photos)
- Prometheus + Grafana (monitoring)

**Acceptance Criteria**:
- ✅ All services defined in docker-compose.yml
- ✅ Environment variables in .env.example
- ✅ Health checks for each service
- ✅ Volumes for persistence (postgres, redis, minio)
- ✅ Networks isolated
- ✅ Nginx SSL configuration
- ✅ Deploy script runs successfully in 5 minutes
- ✅ Can view monitoring dashboard at localhost:3001

**Local LLM Prompt Template**:
```
Create Docker Compose setup for AnMates MVP deployment.

Files to create/update:
1. docker-compose-mvp.yml - Service definitions
2. Dockerfile (backend) - NestJS container
3. nginx/nginx-mvp.conf - Reverse proxy + rate limiting
4. .env.example - Template for environment variables
5. deploy-mvp.sh - Automated deployment script

Requirements:
1. Services:
   - nginx (port 80, 443)
   - backend API (port 3000, internal)
   - postgres (port 5432, internal)
   - redis (port 6379, internal)
   - minio (port 9000, 9001)
   - prometheus (port 9090)
   - grafana (port 3001)

2. Each service needs:
   - Resource limits (for MVP on single machine)
   - Health checks
   - Restart policy: unless-stopped
   - Logging configuration

3. Volumes:
   - postgres_data
   - redis_data
   - minio_data
   - prometheus_data
   - grafana_data

4. Networks:
   - anmates_net (bridge)

5. Deploy script should:
   - Check Docker installed
   - Create SSL cert if missing
   - Start all containers
   - Run DB migrations
   - Show health checks
   - Display dashboard URLs

Keep it minimal for 50 users on single machine.
```

---

## TASK 21: Deployment & Go-Live Checklist

**Context**: Final verification and production launch

**Checklist**:
- [ ] All features coded and tested
- [ ] Database migrations run
- [ ] Monitoring dashboard shows green
- [ ] Nginx rate limiting working
- [ ] SSL certificate valid
- [ ] Backup script running daily
- [ ] Team trained on how to restart services
- [ ] Support process documented
- [ ] First 50 users invited
- [ ] Analytics tracking enabled
- [ ] Daily standup scheduled
- [ ] Rollback plan documented

**Acceptance Criteria**:
- ✅ Zero critical bugs in first 24h
- ✅ API response time <200ms (p95)
- ✅ Zero unplanned downtime
- ✅ All KPI dashboards working
- ✅ Team can restart service in <5 min
- ✅ Support tickets triaged
- ✅ Success metrics tracked

**Local LLM Prompt Template**:
```
Create production deployment checklist and monitoring guide.

Documents to create:
1. DEPLOYMENT_CHECKLIST.md
2. MONITORING_GUIDE.md
3. TROUBLESHOOTING.md
4. RUNBOOK.md (how to restart/fix issues)
5. SUPPORT_FAQ.md

Checklist should cover:
- Code deployed, migrations run
- SSL cert valid
- Firewall rules configured
- Backups running
- Monitoring alerts active
- Grafana dashboards set up
- Team access granted
- Documentation complete

Monitoring targets:
- API response time (target <200ms p95)
- Error rate (target <1%)
- Database connections (target <50/100)
- Disk usage (alert at 80%)
- CPU/Memory (alert at 80%)
- Active users (for tracking growth)

Runbook for common issues:
- Service down - how to restart
- Database full - how to archive
- Rate limiting too aggressive - how to adjust
- High latency - debugging steps

All docs in README or separate folder.
```

---

## Summary: Task Execution Order

**Week 1-2** (Backend foundation):
1. Complete Auth Service → Deploy endpoints
2. Food Wishlist Module → Add endpoints
3. Matching Algorithm → Add endpoints
4. Trust Score System → Setup tracking
5. Chat Module → Setup storage
6. WebSocket Setup → Test real-time

**Week 3-4** (Core features):
7. Payment Integration → Test sandbox
8. Safety Features → Block/Report system
9. API Testing & Error Handling → Make robust
10. Database migrations + seed data

**Week 5-6** (Frontend):
11. Onboarding + Face Verification
12. Food Wishlist Screen
13. Matching Discovery Screen
14. Vibe-Check Chat + Progress Bar
15. Gom Kèo Deal Screen
16. Profile + Trust Score Dashboard
17. Frontend Testing & Polish

**Week 7-8** (Deployment):
18. Docker Compose + Nginx Setup
19. Staging environment test
20. Production deployment script
21. Monitoring dashboard
22. Go-Live & first users

---

**Each task is designed to be completed in 2-4 hours with a local LLM.**  
**Proceed with Task 1 when ready!**
