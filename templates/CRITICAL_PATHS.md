# Critical Paths

This document outlines the critical components and code paths in the system architecture. Changes to these areas require extra caution and thorough testing.

## Legend

- 🔴 **Critical**: Breaking changes can cause system failures or security issues
- 🟡 **Important**: Changes need careful testing
- 🟢 **Standard**: Normal caution applies

## Architecture Overview

```
[PROJECT_NAME]
├── 🔴 [AUTHENTICATION_LAYER]
├── 🟡 [DATA_LAYER]
├── 🟡 [API_LAYER]
├── 🟢 [FRONTEND_LAYER]
└── 🟡 [BACKGROUND_TASKS]
```

## Critical Components

### 🔴 Authentication & Security

**Location**: `[AUTH_FILE_PATH]`

**Critical Lines**: 
- Lines XX-YY: Token validation
- Lines AA-BB: Password hashing

**Why Critical**: Security boundary - errors could allow unauthorized access or expose user data.

**Invariants**:
- Always verify JWTs with proper signature
- Never store plaintext passwords
- All routes must check authentication

**Recovery**: If authentication breaks, users will be unable to log in. Check the auth logs for errors.

### 🔴 Data Layer

**Location**: `[DATA_LAYER_PATH]`

**Critical Lines**:
- Lines XX-YY: Database connection pool
- Lines AA-BB: Transaction management

**Why Critical**: Database corruption can lead to permanent data loss.

**Invariants**:
- Always use transactions for multi-step operations
- Handle connection errors with exponential backoff
- Never execute user-provided SQL without parameterization

**Recovery**: If database access breaks, check connection strings in .env and database logs.

### 🟡 API Layer

**Location**: `[API_LAYER_PATH]`

**Critical Lines**:
- Lines XX-YY: Rate limiting
- Lines AA-BB: Request validation

**Why Critical**: Public-facing surface for potential attacks.

**Invariants**:
- All endpoints must validate input
- Rate limiting must be applied to public endpoints
- Error responses should not expose system details

**Recovery**: If API fails, check logs for error patterns and recent changes.

### 🟡 Background Tasks

**Location**: `[BACKGROUND_TASKS_PATH]`

**Critical Lines**:
- Lines XX-YY: Job scheduling
- Lines AA-BB: Error handling

**Why Critical**: Background failures can be silent and accumulate.

**Invariants**:
- All jobs must be idempotent
- Jobs should have timeouts
- Failed jobs must be logged and retried

**Recovery**: Check job logs and queue status.

## Infrastructure Critical Paths

### 🔴 Database

**Configuration**: `[DB_CONFIG_PATH]`

**Critical Settings**:
- Connection pooling
- Indices
- Backup schedule

**Why Critical**: Performance and data integrity.

**Invariants**:
- Never remove indices without analyzing query impact
- Always have automated backups enabled
- Connection pool should match expected load

### 🟡 Caching Layer

**Configuration**: `[CACHE_CONFIG_PATH]`

**Critical Settings**:
- TTL values
- Eviction policies

**Why Critical**: Performance and consistency.

**Invariants**:
- Cache keys should include version information
- Never rely on cache presence for correctness
- Clear caches when deploying schema changes

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