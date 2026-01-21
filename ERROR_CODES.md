# Error Codes Reference

This document provides a comprehensive reference for all error codes used in the School Parent App. Error codes are displayed to users along with user-friendly messages, while technical details are logged for developers.

## Purpose

Error codes serve two purposes:
1. **User Experience**: Display friendly, non-technical messages to users
2. **Developer Debugging**: Help developers identify the root cause of issues through error codes

## Error Code Format

Error codes are displayed in the format: `[ERROR_CODE] - [User-Friendly Message]`

Example: `401 - Unable to load the message right now due to low internet speed. Please retry in a few minutes.`

---

## Network/Connection Errors (400-499)

### 401 - Network Timeout
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**: 
- Connection timeout
- Receive timeout
- Send timeout
- Request took too long to complete

**Common Scenarios**:
- Slow internet connection
- Server taking too long to respond
- Network congestion

**Developer Action**:
- Check network connectivity
- Verify server response times
- Check timeout configurations in DioClient

---

### 402 - Network Connection Error
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- Connection error (DioExceptionType.connectionError)
- Unable to establish connection to server
- DNS resolution failure

**Common Scenarios**:
- No internet connection
- Server is down
- Firewall blocking connection
- Incorrect server URL

**Developer Action**:
- Verify server is accessible
- Check network connectivity
- Verify API endpoint URLs
- Check firewall/proxy settings

---

### 403 - Network Slow
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- Slow network connection detected
- Intermittent connectivity issues

**Common Scenarios**:
- Weak WiFi signal
- Mobile data connection issues
- Network throttling

**Developer Action**:
- Check network speed
- Verify connection stability
- Consider implementing retry logic

---

### 404 - Network Unavailable
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- SocketException
- No network connection available
- Device is offline

**Common Scenarios**:
- Airplane mode enabled
- WiFi disconnected
- Mobile data disabled
- No network coverage

**Developer Action**:
- Check device network status
- Verify internet connectivity
- Implement offline mode handling

---

## Server Errors (500-599)

### 501 - Server Error
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- HTTP 500 Internal Server Error
- Server-side application error
- Database connection issues

**Common Scenarios**:
- Server application crashed
- Database query failed
- Server configuration error

**Developer Action**:
- Check server logs
- Verify database connectivity
- Contact backend team
- Check server health status

---

### 502 - Server Unavailable
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- HTTP 502 Bad Gateway
- HTTP 503 Service Unavailable
- Server is down or overloaded

**Common Scenarios**:
- Server maintenance
- Server overloaded
- Gateway/proxy issues
- Server restarting

**Developer Action**:
- Check server status
- Verify server is running
- Check load balancer status
- Contact infrastructure team

---

### 503 - Server Timeout
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- HTTP 504 Gateway Timeout
- Server took too long to respond
- Upstream server timeout

**Common Scenarios**:
- Server processing timeout
- Database query timeout
- External service timeout

**Developer Action**:
- Check server performance
- Verify database query performance
- Check external service status
- Review timeout configurations

---

## Authentication Errors (600-699)

### 601 - Unauthorized
**User Message**: Your session has expired. Please login again.

**Technical Cause**:
- HTTP 401 Unauthorized
- HTTP 403 Forbidden
- Invalid or expired authentication token
- Insufficient permissions

**Common Scenarios**:
- Token expired
- Invalid API token
- User not authenticated
- Insufficient user permissions

**Developer Action**:
- Check token expiration
- Verify token is being sent correctly
- Check user authentication status
- Verify user permissions

---

### 602 - Session Expired
**User Message**: Your session has expired. Please login again.

**Technical Cause**:
- User session expired
- Token refresh failed
- Authentication token invalid

**Common Scenarios**:
- User logged out
- Session timeout
- Token refresh failure

**Developer Action**:
- Implement token refresh logic
- Check session management
- Verify authentication flow
- Handle session expiration gracefully

---

### 603 - Invalid Credentials
**User Message**: Invalid credentials. Please check your login details.

**Technical Cause**:
- Wrong username/password
- Account locked
- Account disabled

**Common Scenarios**:
- Incorrect login credentials
- Account security lock
- Account deactivated

**Developer Action**:
- Verify login credentials
- Check account status
- Review authentication logic
- Check account lockout policies

---

## Data Errors (700-799)

### 701 - Data Not Found
**User Message**: The requested information could not be found.

**Technical Cause**:
- HTTP 404 Not Found
- Requested resource doesn't exist
- Invalid resource ID

**Common Scenarios**:
- Invalid ID in request
- Resource was deleted
- Incorrect API endpoint
- Data doesn't exist in database

**Developer Action**:
- Verify resource ID
- Check if resource exists
- Verify API endpoint
- Check database records

---

### 702 - Data Invalid
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- Invalid data format
- Data validation failed
- Malformed request data

**Common Scenarios**:
- Invalid JSON format
- Missing required fields
- Data type mismatch
- Validation errors

**Developer Action**:
- Verify request payload
- Check data validation rules
- Review API documentation
- Check data format requirements

---

### 703 - Data Load Failed
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- Failed to load data from server
- Data parsing error
- Response format error

**Common Scenarios**:
- Response parsing failed
- Unexpected response format
- Data corruption
- API response error

**Developer Action**:
- Check response format
- Verify data parsing logic
- Review API response structure
- Check for data corruption

---

## Generic Errors (800-899)

### 801 - Unknown Error
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- Unexpected error type
- Unhandled exception
- Unknown error occurred

**Common Scenarios**:
- Unhandled exception
- Unexpected error type
- Error not categorized

**Developer Action**:
- Check error logs
- Review exception handling
- Add error handling for this case
- Investigate root cause

---

### 802 - Operation Failed
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- Generic operation failure
- HTTP status code not specifically handled
- Request failed for unknown reason

**Common Scenarios**:
- Unhandled HTTP status code
- Operation failed without specific error
- Generic failure

**Developer Action**:
- Check HTTP status code
- Review error logs
- Verify operation requirements
- Check server response

---

### 803 - Service Unavailable
**User Message**: Unable to load the message right now due to low internet speed. Please retry in a few minutes.

**Technical Cause**:
- Service temporarily unavailable
- Maintenance mode
- Service overloaded

**Common Scenarios**:
- Service maintenance
- Service overloaded
- Temporary service outage

**Developer Action**:
- Check service status
- Verify service availability
- Check maintenance schedules
- Contact service provider

---

## Error Code Mapping

### HTTP Status Codes to Error Codes

| HTTP Status | Error Code | Description |
|------------|-----------|-------------|
| 401 | 601 | Unauthorized |
| 403 | 601 | Forbidden |
| 404 | 701 | Not Found |
| 408 | 401 | Request Timeout |
| 500 | 501 | Internal Server Error |
| 502 | 502 | Bad Gateway |
| 503 | 502 | Service Unavailable |
| 504 | 503 | Gateway Timeout |

### Exception Types to Error Codes

| Exception Type | Error Code | Description |
|---------------|-----------|-------------|
| SocketException | 404 | Network Unavailable |
| TimeoutException | 401 | Network Timeout |
| DioException.connectionTimeout | 401 | Connection Timeout |
| DioException.receiveTimeout | 401 | Receive Timeout |
| DioException.sendTimeout | 401 | Send Timeout |
| DioException.connectionError | 402 | Connection Error |
| Generic Exception | 801 | Unknown Error |

---

## Implementation Notes

### Error Handling Flow

1. **Error Occurs**: Exception is caught in try-catch block
2. **Error Code Generated**: `ErrorCodes.getErrorCode(error)` determines the error code
3. **User Message Retrieved**: `ErrorCodes.getUserMessage(code)` gets user-friendly message
4. **Error Logged**: `ErrorHandler.logError()` logs technical details for developers
5. **User Notified**: User sees error code and friendly message

### Example Usage

```dart
try {
  final data = await service.getData();
} catch (e) {
  final errorCode = ErrorHandler.getErrorCode(e);
  final errorMessage = ErrorHandler.getErrorMessage(e);
  
  ErrorHandler.logError(
    context: 'ScreenName.methodName',
    error: e,
  );
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorMessage)),
  );
}
```

### Logging

All errors are logged with:
- Context (where error occurred)
- Error type and details
- Timestamp
- Stack trace (if available)
- Additional information

Logs are printed in debug mode and can be sent to crash reporting services in production.

---

## Best Practices

1. **Always use ErrorHandler**: Don't show raw exceptions to users
2. **Log errors properly**: Include context and stack traces
3. **Use appropriate error codes**: Match error codes to actual error types
4. **Provide retry options**: For network errors, allow users to retry
5. **Handle errors gracefully**: Don't crash the app, show friendly messages

---

## Support

For questions or issues related to error codes:
1. Check this documentation
2. Review error logs
3. Check server status
4. Contact development team

---

**Last Updated**: 2024
**Version**: 1.0

