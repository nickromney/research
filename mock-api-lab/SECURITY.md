# Security Policy

## Purpose

This is a **learning and testing environment** designed to help infrastructure engineers understand API concepts, OAuth 2.0 flows, and APIM patterns. It is **intentionally insecure** and **NOT suitable for production use**.

## Known Security Vulnerabilities

### 1. Dependencies (RESOLVED)

**Package**: `@node-oauth/oauth2-server@5.2.1`
**Status**: No known vulnerabilities
**Previous Issue**: Older `oauth2-server@3.1.1` had open redirect and code injection CVEs
**Resolution**: Upgraded to maintained fork `@node-oauth/oauth2-server` (actively maintained, no CVEs)
**npm audit**: `found 0 vulnerabilities`

### 2. Hardcoded Credentials (CRITICAL)

**Location**: All configuration files and source code
**Details**:
- OAuth client credentials: `application` / `secret`
- Test users: `user1/password1`, `admin/admin123`
- Subscription keys: `primary-key-12345`, `secondary-key-67890`
- No environment variable usage

**Impact**: Anyone with access to the code has full authentication credentials
**Mitigation for production**: Use environment variables, secret managers (Azure Key Vault, HashiCorp Vault)

### 3. Plaintext Password Storage (CRITICAL)

**Location**: `oauth-server.js`
**Details**: Passwords stored as plaintext strings in source code
**Impact**: Complete credential compromise
**Mitigation for production**: Use bcrypt, argon2, or scrypt for password hashing

### 4. SSRF Vulnerability (HIGH)

**Location**: `apim-simulator.js` - backend query parameter
**Details**: User-controlled backend URL without validation
**Code**:
```javascript
const backend = req.query.backend || 'https://httpbin.org'
// No validation - can point to internal services
```

**Impact**: Can access internal network resources, cloud metadata endpoints
**Mitigation for production**: Whitelist allowed backend URLs, validate against SSRF patterns

### 5. No Input Validation (HIGH)

**Location**: All endpoints
**Details**: No validation of request parameters, headers, or body content
**Impact**: Potential for injection attacks, buffer overflows, denial of service
**Mitigation for production**: Use validation libraries (joi, express-validator), implement rate limiting

### 6. In-Memory Storage (MEDIUM)

**Location**: All data stores (tokens, rate limits, etc.)
**Details**: Data lost on restart, no persistence
**Impact**: Lost session state, inconsistent rate limiting across restarts
**Mitigation for production**: Use Redis, database, or persistent storage

### 7. No Encryption (CRITICAL)

**Details**:
- HTTP only (no HTTPS)
- No TLS/SSL certificates
- Tokens transmitted in plaintext
- No encryption at rest

**Impact**: Man-in-the-middle attacks, credential theft, token interception
**Mitigation for production**: Use HTTPS everywhere, implement TLS 1.3, encrypt sensitive data at rest

### 8. No Rate Limiting (API Level) (MEDIUM)

**Details**: While APIM simulator has rate limiting, the OAuth server has none
**Impact**: Brute force attacks, denial of service
**Mitigation for production**: Implement rate limiting on all endpoints (express-rate-limit)

### 9. Permissive CORS (LOW)

**Location**: Both services
**Details**: Accept requests from any origin
**Impact**: Cross-site request forgery (CSRF) attacks
**Mitigation for production**: Configure strict CORS policies, use CSRF tokens

### 10. Debug/Development Mode (LOW)

**Details**: Verbose error messages, stack traces exposed to clients
**Impact**: Information disclosure, easier reconnaissance for attackers
**Mitigation for production**: Use production mode, sanitize error messages

## npm audit Results

Current status (2025-11-09):

```bash
$ npm audit
found 0 vulnerabilities
```

 **All dependency vulnerabilities resolved!**

**Changes made**:
- Upgraded from `oauth2-server@3.1.1` to `@node-oauth/oauth2-server@5.2.1`
- This is the actively maintained fork with no known CVEs
- Removed lodash override (no longer needed)

## Why These Vulnerabilities Exist

1. **Educational Purpose**: Demonstrating security concepts by showing what NOT to do
2. **Simplicity**: Keeping code simple and readable for learning
3. **Dependency Constraints**: oauth2-server has no secure stable release
4. **No Production Intent**: This is explicitly NOT for production use

## Production Recommendations

If building a production OAuth 2.0 + APIM system:

### OAuth Server Alternatives
- [node-oidc-provider](https://github.com/panva/node-oidc-provider) - Production-ready OpenID Connect provider
- [Keycloak](https://www.keycloak.org/) - Enterprise identity and access management
- Azure AD B2C - Cloud-based identity service
- Auth0 - Commercial identity platform
- AWS Cognito - AWS-managed authentication

### APIM Alternatives
- Azure API Management - Full production APIM service
- Kong Gateway - Open source API gateway
- AWS API Gateway - AWS-managed API gateway
- Apigee - Google Cloud API management
- Tyk - Open source API gateway

### Security Best Practices
1. **Never hardcode secrets** - Use Azure Key Vault, AWS Secrets Manager, HashiCorp Vault
2. **Hash passwords** - Use bcrypt (cost ≥12), argon2id, or scrypt
3. **Use HTTPS everywhere** - TLS 1.3, valid certificates, HSTS headers
4. **Validate all input** - joi, express-validator, zod
5. **Implement rate limiting** - express-rate-limit, Redis-backed limits
6. **Use secure session management** - express-session with Redis store
7. **Enable security headers** - helmet.js middleware
8. **Audit dependencies regularly** - npm audit, Snyk, Dependabot
9. **Follow OWASP Top 10** - Review and mitigate all OWASP vulnerabilities
10. **Use WAF** - Azure Front Door, Cloudflare, AWS WAF

## Reporting Security Issues

Since this is intentionally insecure for learning purposes, we do not accept security vulnerability reports for the issues listed above.

However, if you find:
- Undocumented vulnerabilities
- Issues that make the lab unsafe to run on a developer machine
- Vulnerabilities in documentation or guidance that could mislead users

Please open an issue on GitHub: https://github.com/nickromney/research/issues

## Security Testing

This lab can be used to learn about:
- OAuth 2.0 attack vectors
- APIM security patterns
- Rate limiting bypass techniques
- SSRF exploitation
- Secure vs. insecure API design

**Always test in isolated environments (containers, VMs, separate networks).**

## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. USE AT YOUR OWN RISK. THIS SOFTWARE IS NOT FIT FOR PRODUCTION USE AND CONTAINS KNOWN CRITICAL SECURITY VULNERABILITIES.

By using this software, you acknowledge that you understand the security risks and will not use it in production environments or with real user data.

---

**Last Updated**: 2025-11-09
**Security Review**: Known vulnerabilities documented and accepted for learning purposes
