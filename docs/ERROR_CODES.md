# Error Codes Reference

This document defines standardized error codes used throughout the project. When encountering or logging errors, reference these codes for consistency.

## Error Code Format

Error codes follow this format: `[CATEGORY]-[NUMBER]`

Example: `AUTH-001` represents the first authentication error type.

## Categories

- `AUTH`: Authentication & Authorization
- `DB`: Database
- `API`: API Endpoints
- `VAL`: Validation
- `SYS`: System
- `SEC`: Security
- `FILE`: File Operations
- `NET`: Network
- `CFG`: Configuration
- `USR`: User-related
- `DATA`: Data Processing
- `INTG`: Integration
- `PERF`: Performance
- `UI`: User Interface
- `BIZ`: Business Logic

## Error Codes

### Authentication & Authorization (AUTH)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `AUTH-001` | Missing authentication token | Ensure request includes valid token in Authorization header |
| `AUTH-002` | Invalid token format | Check token format (should be Bearer + JWT) |
| `AUTH-003` | Expired token | Refresh token or re-authenticate |
| `AUTH-004` | Insufficient permissions | Request elevated permissions or use different account |
| `AUTH-005` | Account locked | Contact administrator or wait for lockout period to end |
| `AUTH-006` | Invalid credentials | Check username/password |
| `AUTH-007` | Multi-factor authentication required | Complete MFA flow |
| `AUTH-008` | Token revoked | Re-authenticate to obtain new token |
| `AUTH-009` | Session expired | Re-authenticate to start new session |
| `AUTH-010` | IP address not allowed | Access from allowed IP or request IP allowlisting |

### Database (DB)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `DB-001` | Connection failure | Check database connectivity and credentials |
| `DB-002` | Query timeout | Optimize query or increase timeout limit |
| `DB-003` | Duplicate key | Use unique value or update existing record |
| `DB-004` | Foreign key violation | Ensure referenced record exists |
| `DB-005` | Transaction rollback | Review transaction logic and retry |
| `DB-006` | Dead lock | Restructure transactions to avoid deadlocks |
| `DB-007` | Data integrity constraint | Ensure data meets all constraints |
| `DB-008` | Connection pool exhausted | Increase pool size or optimize connection usage |
| `DB-009` | Unauthorized schema modification | Use migrations for schema changes |
| `DB-010` | Query syntax error | Check SQL syntax |

### API Endpoints (API)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `API-001` | Rate limit exceeded | Reduce request frequency or request rate limit increase |
| `API-002` | Invalid request format | Check request structure against API documentation |
| `API-003` | Endpoint not found | Verify endpoint URL |
| `API-004` | Method not allowed | Use correct HTTP method (GET, POST, etc.) |
| `API-005` | Request timeout | Optimize request or increase timeout |
| `API-006` | Response too large | Use pagination or filter criteria |
| `API-007` | Unsupported media type | Use supported content type |
| `API-008` | Invalid API version | Update API version in request |
| `API-009` | Missing required parameter | Include all required parameters |
| `API-010` | API service unavailable | Retry with exponential backoff |

### Validation (VAL)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `VAL-001` | Required field missing | Provide value for all required fields |
| `VAL-002` | Invalid field format | Check field format requirements |
| `VAL-003` | Value out of range | Provide value within acceptable range |
| `VAL-004` | Invalid email format | Provide correctly formatted email |
| `VAL-005` | Password too weak | Use stronger password meeting requirements |
| `VAL-006` | Invalid date format | Use correct date format (YYYY-MM-DD) |
| `VAL-007` | File size too large | Reduce file size or request size limit increase |
| `VAL-008` | Unsupported file type | Use supported file type |
| `VAL-009` | Duplicate submission | Avoid submitting duplicate data |
| `VAL-010` | Complex validation failure | Check detailed error message for specific issues |

### System (SYS)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `SYS-001` | Out of memory | Reduce memory usage or increase available memory |
| `SYS-002` | Disk space full | Free disk space or increase storage |
| `SYS-003` | CPU overload | Reduce system load or scale infrastructure |
| `SYS-004` | Process terminated | Check process logs for termination reason |
| `SYS-005` | System update required | Apply pending system updates |
| `SYS-006` | Dependency missing | Install required dependency |
| `SYS-007` | Incompatible system version | Update system to compatible version |
| `SYS-008` | Resource limit reached | Increase resource limits or optimize usage |
| `SYS-009` | Hardware failure | Check hardware diagnostics |
| `SYS-010` | System initialization failure | Check system logs for initialization errors |

### Security (SEC)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `SEC-001` | Potential SQL injection | Use parameterized queries |
| `SEC-002` | Potential XSS attack | Sanitize user inputs |
| `SEC-003` | CSRF token invalid | Refresh page to get new CSRF token |
| `SEC-004` | Suspicious activity detected | Review account activity |
| `SEC-005` | Brute force attempt | Temporary account lockout may be in effect |
| `SEC-006` | Insecure direct object reference | Use proper authorization checks |
| `SEC-007` | TLS/SSL error | Update TLS configuration |
| `SEC-008` | Security header missing | Configure proper security headers |
| `SEC-009` | File upload security risk | Upload only allowed file types |
| `SEC-010` | API key exposed | Rotate exposed API key immediately |

### File Operations (FILE)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `FILE-001` | File not found | Verify file path |
| `FILE-002` | Permission denied | Check file permissions |
| `FILE-003` | File too large | Reduce file size |
| `FILE-004` | Invalid file format | Use correct file format |
| `FILE-005` | File upload failed | Retry upload or check connection |
| `FILE-006` | File download failed | Retry download or check connection |
| `FILE-007` | File corrupt | Re-create or re-upload file |
| `FILE-008` | File read error | Check file integrity |
| `FILE-009` | File write error | Check disk space and permissions |
| `FILE-010` | File already exists | Use unique filename or overwrite option |

### Network (NET)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `NET-001` | Connection refused | Check service status and credentials |
| `NET-002` | Host unreachable | Verify host address and network connectivity |
| `NET-003` | DNS resolution failure | Verify DNS configuration |
| `NET-004` | Connection timeout | Check network latency or increase timeout |
| `NET-005` | TLS/SSL handshake failure | Check TLS configuration and certificates |
| `NET-006` | Network congestion | Retry with exponential backoff |
| `NET-007` | Socket error | Check network stack configuration |
| `NET-008` | Proxy error | Verify proxy configuration |
| `NET-009` | VPN connection failure | Check VPN credentials and configuration |
| `NET-010` | API gateway error | Check API gateway configuration |

### Configuration (CFG)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `CFG-001` | Missing configuration file | Create required configuration file |
| `CFG-002` | Invalid configuration format | Fix configuration syntax |
| `CFG-003` | Required configuration missing | Add required configuration values |
| `CFG-004` | Configuration value out of range | Adjust configuration value to valid range |
| `CFG-005` | Conflicting configuration | Resolve configuration conflicts |
| `CFG-006` | Environment variable missing | Set required environment variable |
| `CFG-007` | Configuration deprecated | Update to current configuration format |
| `CFG-008` | Insecure configuration | Update configuration to secure settings |
| `CFG-009` | Configuration load failure | Check configuration file permissions |
| `CFG-010` | Feature flag configuration error | Verify feature flag settings |

### User-related (USR)

| Code | Description | Suggested Resolution |
|------|-------------|----------------------|
| `USR-001` | User not found | Verify user ID or email |
| `USR-002` | User already exists | Use different username or email |
| `USR-003` | User account suspended | Contact administrator for account status |
| `USR-004` | User quota exceeded | Upgrade account or reduce usage |
| `USR-005` | Password change required | Set new password |
| `USR-006` | Email verification required | Complete email verification process |
| `USR-007` | Account deletion in progress | Wait for deletion to complete |
| `USR-008` | User profile incomplete | Complete required profile fields |
| `USR-009` | Too many active sessions | Close other sessions |
| `USR-010` | User action rate limited | Wait before retrying action |

## Using Error Codes

When logging errors or returning error responses, always include:

1. The error code
2. A human-readable message
3. Timestamp
4. Request ID (if applicable)
5. Suggested resolution (optional)

### Example Error Log:

```
[2025-06-11T14:23:45.123Z] [ERROR] [req-12345] [AUTH-003] Token expired. User must re-authenticate.
```

### Example API Error Response:

```json
{
  "error": {
    "code": "AUTH-003",
    "message": "Your session has expired",
    "timestamp": "2025-06-11T14:23:45.123Z",
    "requestId": "req-12345",
    "resolution": "Please log in again to continue"
  }
}
```

## Error Reporting Guidelines

1. **Be Specific**: Use the most specific error code applicable
2. **Include Context**: Add relevant contextual information
3. **Avoid Sensitive Data**: Never include passwords, tokens, or PII in error messages
4. **Suggest Solutions**: When possible, include actionable resolution steps
5. **Consistent Format**: Always use the standard error format

## Adding New Error Codes

When adding new error codes:

1. Check if an existing code already covers the error case
2. Use the next available number in the appropriate category
3. Add the new code to this document with description and resolution
4. Announce the new error code to the development team

## Language-Specific Implementation

### JavaScript/TypeScript

```typescript
enum ErrorCode {
  AUTH_001 = "AUTH-001",
  AUTH_002 = "AUTH-002",
  // ...
}

class AppError extends Error {
  constructor(
    public code: ErrorCode,
    public message: string,
    public resolution?: string
  ) {
    super(message);
    this.name = "AppError";
  }
}
```

### Python

```python
class ErrorCode:
    AUTH_001 = "AUTH-001"
    AUTH_002 = "AUTH-002"
    # ...

class AppError(Exception):
    def __init__(self, code, message, resolution=None):
        self.code = code
        self.message = message
        self.resolution = resolution
        super().__init__(f"{code}: {message}")
```