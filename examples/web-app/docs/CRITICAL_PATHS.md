# Critical Paths

This document outlines the critical components and code paths in the TaskMaster architecture. Changes to these areas require extra caution and thorough testing.

## Legend

- 🔴 **Critical**: Breaking changes can cause system failures or security issues
- 🟡 **Important**: Changes need careful testing
- 🟢 **Standard**: Normal caution applies

## Architecture Overview

```
TaskMaster
├── 🔴 Authentication Layer
├── 🟡 Data Access Layer
├── 🟡 AI Prioritization Engine
├── 🟢 Frontend Components
└── 🟡 Background Jobs
```

## Critical Components

### 🔴 Authentication System

**Location**: `backend/src/auth`

**Critical Lines**: 
- `backend/src/auth/middleware.js:25-52`: Token validation
- `backend/src/auth/controllers.js:104-135`: Password hashing and verification

**Why Critical**: Security boundary - errors could allow unauthorized access or expose user data.

**Invariants**:
- Always verify JWTs with proper signature
- Never store plaintext passwords
- All protected routes must check authentication
- Rate limit authentication attempts

**Recovery**: If authentication breaks, users will be unable to log in. Check the auth logs and revert to the last stable commit.

### 🔴 Task Data Storage

**Location**: `backend/src/models/task.js`

**Critical Lines**:
- `backend/src/models/task.js:45-78`: CRUD operations
- `backend/src/models/task.js:120-165`: Transaction management

**Why Critical**: Core data model - errors can lead to data corruption or loss.

**Invariants**:
- Always use transactions for batch operations
- Validate task data before storage
- Maintain data consistency with workspaces
- Never delete tasks (use soft delete)

**Recovery**: If task storage breaks, check database consistency and restore from backup if necessary.

### 🟡 AI Prioritization Engine

**Location**: `backend/src/services/ai`

**Critical Lines**:
- `backend/src/services/ai/prioritize.js:30-85`: Task analysis algorithm
- `backend/src/services/ai/openai.js:15-45`: API integration

**Why Critical**: Core product feature - errors affect main value proposition.

**Invariants**:
- Handle API failures gracefully
- Cache results to reduce API costs
- Never block user operations on AI availability
- Rate limit API requests to prevent cost spikes

**Recovery**: If AI features fail, disable them temporarily and continue with manual prioritization.

### 🟡 User Preferences System

**Location**: `backend/src/models/preferences.js`

**Critical Lines**:
- `backend/src/models/preferences.js:25-60`: Preference management
- `backend/src/controllers/preferences.js:30-55`: Validation

**Why Critical**: Affects user experience and data integrity.

**Invariants**:
- Validate preference data
- Default sensibly on missing preferences
- Cache frequently accessed preferences
- Handle migration for changed preference schema

**Recovery**: If preferences fail, revert to default settings.

### 🟡 Background Jobs

**Location**: `backend/src/jobs`

**Critical Lines**:
- `backend/src/jobs/scheduler.js:20-50`: Job queue management
- `backend/src/jobs/notifications.js:25-80`: Email sending

**Why Critical**: User notifications and data maintenance.

**Invariants**:
- Jobs must be idempotent
- Failed jobs must retry with backoff
- Log job failures for monitoring
- Never block user operations on job completion

**Recovery**: If job system fails, manually process critical jobs and fix the scheduler.

## Infrastructure Critical Paths

### 🔴 Database Schema

**Location**: `backend/src/migrations`

**Critical Settings**:
- Indices on task table
- Foreign key constraints
- Preference JSON validation

**Why Critical**: Schema changes can break the application or corrupt data.

**Invariants**:
- Always write down migrations
- Test migrations on staging before production
- Back up database before migrations
- Add appropriate indices for query patterns

### 🟡 Redis Cache

**Location**: `backend/src/services/cache.js`

**Critical Settings**:
- TTL values
- Key naming conventions
- Memory limits

**Why Critical**: Performance and consistency.

**Invariants**:
- Cache invalidation on data changes
- TTL on all cache entries
- Fallback to database on cache miss
- Clear cache on schema changes

## Recovery Procedures

### Database Issues

1. Check connection strings in .env
2. Verify database is running and accessible
3. Check logs for errors
4. Consider restoring from latest backup if corruption detected

### API Failures

1. Check server logs for errors
2. Verify rate limits are appropriate
3. Check for recent changes to validation logic

### Authentication Failures

1. Verify JWT secret in environment variables
2. Check token expiration settings
3. Validate auth provider connectivity

## Architecture Invariants

These principles should never be violated:

1. **Security Boundaries**: Authentication and authorization checks cannot be bypassed
2. **Data Integrity**: Transactions must be used for related changes
3. **Error Handling**: No errors should be silently ignored
4. **Logging**: Security events must always be logged
5. **Configuration**: Secrets must come from environment variables, not code

## Making Changes to Critical Paths

When modifying critical code:

1. Create a separate branch
2. Write tests specifically for the changed behavior
3. Have another agent review the change if possible
4. Deploy with extra monitoring
5. Document the change thoroughly in dev_log.md