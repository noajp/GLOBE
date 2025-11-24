# Service Layer Architecture - GLOBE Project

## 📋 Current State Analysis

### SupabaseService.swift (1010 lines)
**Status**: God Object - Single class handles all database operations

**Current Responsibilities:**
- Posts CRUD (399 lines, 40%)
- Follow/Unfollow (295 lines, 29%)
- Notifications (107 lines, 11%)
- Likes (66 lines, 7%)
- User Search (34 lines, 3%)
- Delete Posts (32 lines, 3%)
- Comments (embedded in posts)

**Problems:**
- Violates Single Responsibility Principle
- Difficult to test individual features
- High coupling between unrelated features
- 1010 lines makes maintenance difficult

---

## 🎯 Proposed Architecture

### Phase 1: Extract Major Services (Priority: High)

#### 1. PostService.swift (NEW - 400 lines)
**Responsibilities:**
- `fetchUserPosts(userId:) async -> [Post]`
- `fetchPostsInBounds(minLat:maxLat:minLng:maxLng:zoomLevel:) async`
- `createPost(content:imageData:location:locationName:isAnonymous:) async throws`
- `deletePost(postId:) async throws`
- `updatePost(postId:content:) async throws`

**Dependencies:**
- SupabaseClient
- SecureLogger
- AuthManager (for user validation)

**Migration Strategy:**
- Extract all post-related methods
- Keep SupabaseService as facade for backward compatibility
- Gradually migrate callers to use PostService directly

---

#### 2. FollowService.swift (NEW - 300 lines)
**Responsibilities:**
- `followUser(userId:) async -> Bool`
- `unfollowUser(userId:) async -> Bool`
- `isFollowing(userId:) async -> Bool`
- `getFollowerCount(userId:) async -> Int`
- `getFollowingCount(userId:) async -> Int`
- `getFollowers(userId:) async -> [UserProfile]`
- `getFollowing(userId:) async -> [UserProfile]`

**Dependencies:**
- SupabaseClient
- SecureLogger
- FollowManager (caching layer)

**Migration Strategy:**
- FollowManager.swift already exists as business logic layer
- Extract database operations to FollowService
- FollowManager calls FollowService for persistence

---

### Phase 2: Extract Remaining Services (Priority: Medium)

#### 3. NotificationService.swift (NEW - 110 lines)
**Responsibilities:**
- `createNotification(userId:type:relatedId:message:) async throws`
- `fetchNotifications(userId:limit:) async -> [Notification]`
- `markAsRead(notificationId:) async throws`
- `deleteNotification(notificationId:) async throws`

---

#### 4. LikeService.swift (Expand existing - 66 → 150 lines)
**Current**: Already exists as LikeService.swift
**Action**: Verify completeness, no changes needed

---

#### 5. CommentService.swift (Expand existing - ? lines)
**Current**: Already exists as CommentService.swift
**Action**: Verify completeness, no changes needed

---

#### 6. UserService.swift (NEW - 100 lines)
**Responsibilities:**
- `getUserProfile(userId:) async -> UserProfile?`
- `updateUserProfile(userId:displayName:bio:avatarUrl:) async throws`
- `searchUsers(query:) async -> [UserProfile]`
- `getUserStats(userId:) async -> UserStats`

---

## 🏗️ Layered Architecture

```
┌─────────────────────────────────────────────┐
│              Views (SwiftUI)                │
│  PostPin, UserProfileView, MainTabView      │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│         ViewModels / Managers               │
│  PostManager, FollowManager, AuthManager    │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│            Services Layer                    │
│  PostService, FollowService, UserService    │
│  (Business Logic + Validation)              │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│          Repository Layer                    │
│  SupabaseService (Facade)                   │
│  (Database Operations Only)                  │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│          Supabase Client                     │
│  (Network Layer)                             │
└─────────────────────────────────────────────┘
```

---

## 📝 Migration Steps

### Step 1: Create PostService.swift
1. Copy post-related methods from SupabaseService
2. Add proper error handling and logging
3. Write unit tests
4. Update SupabaseService to delegate to PostService
5. Gradually update callers

### Step 2: Create FollowService.swift
1. Extract follow/unfollow methods
2. Integrate with FollowManager for caching
3. Update SupabaseService facade
4. Test thoroughly

### Step 3: Extract remaining services
1. NotificationService
2. UserService
3. Verify LikeService and CommentService completeness

### Step 4: Refactor SupabaseService
1. Remove extracted code
2. Keep only facade methods for backward compatibility
3. Add deprecation warnings
4. Document migration path

### Step 5: Update Dependent Code
1. PostManager → PostService
2. FollowManager → FollowService
3. Update all direct SupabaseService calls
4. Remove facade layer gradually

---

## ✅ Benefits

**Testability**: Each service can be tested independently
**Maintainability**: Smaller, focused classes
**Scalability**: Easy to add new features
**Team Collaboration**: Clear ownership boundaries
**Code Reusability**: Services can be reused across features

---

## 📊 Estimated Effort

| Task | Lines | Complexity | Time Estimate |
|------|-------|------------|---------------|
| PostService extraction | 400 | High | 3-4 hours |
| FollowService extraction | 300 | Medium | 2-3 hours |
| NotificationService | 110 | Low | 1-2 hours |
| UserService | 100 | Medium | 2 hours |
| Testing & Integration | - | High | 4-5 hours |
| **Total** | **910** | - | **12-16 hours** |

---

## 🚨 Risks & Mitigation

**Risk 1**: Breaking existing functionality
- **Mitigation**: Keep SupabaseService facade, extensive testing

**Risk 2**: Increased complexity initially
- **Mitigation**: Clear documentation, gradual migration

**Risk 3**: Circular dependencies
- **Mitigation**: Careful dependency design, use protocols where needed

---

## 📚 Next Actions

1. Review and approve this architecture
2. Create PostService.swift (highest priority)
3. Set up unit test infrastructure
4. Begin gradual migration
5. Monitor for issues and iterate

---

*Document created: 2025-11-24*
*Status: Proposed - Awaiting approval*
