# Azure APIM Policy Security Best Practices

Research project focused on securing individual API policies in Azure API Management using various security patterns and policy expressions.

## Overview

While network security protects APIM at the infrastructure level, policy security protects individual APIs at the application level. This research explores authentication, authorization, rate limiting, input validation, and other security policies that can be applied to APIs in APIM.

## Key Concepts

### Policy Scopes

APIM policies can be applied at different scopes (from broadest to most specific):

1. **Global scope**: Applies to all APIs
2. **Product scope**: Applies to all APIs in a product
3. **API scope**: Applies to all operations in an API
4. **Operation scope**: Applies to a specific operation

Policies inherit from broader scopes and can be overridden at more specific scopes.

### Policy Sections

Each policy has four sections:
- **inbound**: Policies applied to the request before forwarding to backend
- **backend**: Policies that modify backend behavior
- **outbound**: Policies applied to the response before returning to client
- **on-error**: Policies executed when an error occurs

## Research Goals

- [ ] Understand and implement authentication policies (API keys, OAuth 2.0, JWT)
- [ ] Configure rate limiting and quota policies
- [ ] Implement IP whitelisting and geofencing
- [ ] Set up request/response validation
- [ ] Configure CORS policies
- [ ] Implement caching strategies for security and performance
- [ ] Test transformation policies for security (header manipulation, payload filtering)
- [ ] Document policy best practices for different scenarios
- [ ] Create reusable policy templates
- [ ] Test policy inheritance and override behavior

## Key Security Policies

### 1. Authentication Policies

#### API Key Authentication (Subscription Key)
```xml
<inbound>
    <!-- Validate subscription key is present -->
    <check-header name="Ocp-Apim-Subscription-Key" failed-check-httpcode="401" failed-check-error-message="Missing subscription key">
        <value>*</value>
    </check-header>
</inbound>
```

#### OAuth 2.0 / JWT Validation
```xml
<inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">
        <openid-config url="https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration" />
        <required-claims>
            <claim name="aud">
                <value>your-api-identifier</value>
            </claim>
            <claim name="scope" match="any">
                <value>api.read</value>
                <value>api.write</value>
            </claim>
        </required-claims>
    </validate-jwt>
</inbound>
```

#### Azure AD Managed Identity
```xml
<inbound>
    <authentication-managed-identity resource="https://your-backend-resource.azure.com" output-token-variable-name="msi-access-token" />
    <set-header name="Authorization" exists-action="override">
        <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
    </set-header>
</inbound>
```

### 2. Rate Limiting & Quotas

#### Rate Limiting by Key
```xml
<inbound>
    <!-- Rate limit: 100 calls per 60 seconds per subscription -->
    <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription.Id)" />
</inbound>
```

#### Quota by Subscription
```xml
<inbound>
    <!-- Quota: 10,000 calls per month per subscription -->
    <quota-by-key calls="10000" renewal-period="2629800" counter-key="@(context.Subscription.Id)" />
</inbound>
```

#### Advanced Rate Limiting with Multiple Tiers
```xml
<inbound>
    <choose>
        <when condition="@(context.Subscription.Name.Contains("Premium"))">
            <rate-limit-by-key calls="1000" renewal-period="60" counter-key="@(context.Subscription.Id)" />
        </when>
        <when condition="@(context.Subscription.Name.Contains("Standard"))">
            <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription.Id)" />
        </when>
        <otherwise>
            <rate-limit-by-key calls="10" renewal-period="60" counter-key="@(context.Subscription.Id)" />
        </otherwise>
    </choose>
</inbound>
```

### 3. IP Filtering & Geofencing

#### IP Whitelist
```xml
<inbound>
    <ip-filter action="allow">
        <address>13.66.201.169</address>
        <address-range from="13.66.140.128" to="13.66.140.143" />
    </ip-filter>
</inbound>
```

#### IP Blacklist
```xml
<inbound>
    <ip-filter action="forbid">
        <address>13.66.201.169</address>
    </ip-filter>
</inbound>
```

#### Geographic Filtering
```xml
<inbound>
    <choose>
        <when condition="@{
            string country = context.Request.IpAddress.GetCountry();
            return !new[] { "US", "CA", "GB" }.Contains(country);
        }">
            <return-response>
                <set-status code="403" reason="Forbidden" />
                <set-body>Access denied from your location</set-body>
            </return-response>
        </when>
    </choose>
</inbound>
```

### 4. Request/Response Validation

#### JSON Schema Validation
```xml
<inbound>
    <validate-content unspecified-content-type-action="prevent" max-size="1024" errors-variable-name="validationErrors">
        <content type="application/json" validate-as="json" schema-id="user-schema" action="prevent" />
    </validate-content>
    <choose>
        <when condition="@(context.Variables.ContainsKey("validationErrors"))">
            <return-response>
                <set-status code="400" reason="Bad Request" />
                <set-body>@((string)context.Variables["validationErrors"])</set-body>
            </return-response>
        </when>
    </choose>
</inbound>
```

#### Parameter Validation
```xml
<inbound>
    <validate-parameters specified-parameter-action="prevent" unspecified-parameter-action="prevent" errors-variable-name="validationErrors">
        <headers specified-parameter-action="ignore" unspecified-parameter-action="ignore" />
        <query>
            <parameter name="userId" required="true">
                <type>string</type>
                <pattern>^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$</pattern>
            </parameter>
        </query>
    </validate-parameters>
</inbound>
```

### 5. CORS Configuration

#### Basic CORS
```xml
<inbound>
    <cors allow-credentials="true">
        <allowed-origins>
            <origin>https://www.contoso.com</origin>
            <origin>https://app.contoso.com</origin>
        </allowed-origins>
        <allowed-methods>
            <method>GET</method>
            <method>POST</method>
        </allowed-methods>
        <allowed-headers>
            <header>Content-Type</header>
            <header>Authorization</header>
        </allowed-headers>
        <expose-headers>
            <header>X-Custom-Header</header>
        </expose-headers>
    </cors>
</inbound>
```

### 6. Header Security

#### Remove Sensitive Response Headers
```xml
<outbound>
    <set-header name="X-Powered-By" exists-action="delete" />
    <set-header name="X-AspNet-Version" exists-action="delete" />
    <set-header name="Server" exists-action="delete" />
</outbound>
```

#### Add Security Headers
```xml
<outbound>
    <set-header name="X-Content-Type-Options" exists-action="override">
        <value>nosniff</value>
    </set-header>
    <set-header name="X-Frame-Options" exists-action="override">
        <value>DENY</value>
    </set-header>
    <set-header name="Strict-Transport-Security" exists-action="override">
        <value>max-age=31536000; includeSubDomains</value>
    </set-header>
    <set-header name="Content-Security-Policy" exists-action="override">
        <value>default-src 'self'</value>
    </set-header>
</outbound>
```

### 7. Backend Security

#### Remove Backend URL from Errors
```xml
<on-error>
    <set-body>@{
        return new JObject(
            new JProperty("error", new JObject(
                new JProperty("code", context.LastError.Source),
                new JProperty("message", "An error occurred processing your request")
            ))
        ).ToString();
    }</set-body>
</on-error>
```

#### Backend Certificate Validation
```xml
<authentication-certificate thumbprint="desired-thumbprint" />
```

## Policy Security Patterns

### Pattern 1: Layered Security (Defense in Depth)
```xml
<policies>
    <inbound>
        <!-- Layer 1: IP filtering -->
        <ip-filter action="allow">
            <address-range from="10.0.0.0" to="10.0.255.255" />
        </ip-filter>

        <!-- Layer 2: Rate limiting -->
        <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Request.IpAddress)" />

        <!-- Layer 3: Authentication -->
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
            <openid-config url="https://..." />
        </validate-jwt>

        <!-- Layer 4: Authorization (claims-based) -->
        <choose>
            <when condition="@(!context.User.Claims.Any(c => c.Key == "role" && c.Value == "admin"))">
                <return-response>
                    <set-status code="403" reason="Forbidden" />
                </return-response>
            </when>
        </choose>

        <!-- Layer 5: Input validation -->
        <validate-content unspecified-content-type-action="prevent" />
    </inbound>
</policies>
```

### Pattern 2: Environment-Based Policies
```xml
<policies>
    <inbound>
        <choose>
            <!-- Production: Strict security -->
            <when condition="@(context.Deployment.ServiceName.Contains("prod"))">
                <validate-jwt header-name="Authorization" />
                <rate-limit-by-key calls="100" renewal-period="60" />
            </when>

            <!-- Development: Relaxed for testing -->
            <when condition="@(context.Deployment.ServiceName.Contains("dev"))">
                <rate-limit-by-key calls="1000" renewal-period="60" />
            </when>
        </choose>
    </inbound>
</policies>
```

### Pattern 3: API Key + JWT Hybrid
```xml
<policies>
    <inbound>
        <!-- Require both subscription key AND valid JWT -->
        <check-header name="Ocp-Apim-Subscription-Key" failed-check-httpcode="401" />
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
            <openid-config url="https://..." />
        </validate-jwt>
    </inbound>
</policies>
```

## Testing Security Policies

### Test Checklist

- [ ] Test authentication rejection (no credentials)
- [ ] Test authentication with invalid credentials
- [ ] Test authentication with valid credentials
- [ ] Test rate limit enforcement
- [ ] Test quota enforcement and reset
- [ ] Test IP whitelist/blacklist
- [ ] Test CORS from allowed and disallowed origins
- [ ] Test request validation with invalid payloads
- [ ] Test policy inheritance across scopes
- [ ] Test error handling and information disclosure
- [ ] Test header manipulation
- [ ] Load test with security policies enabled

### Tools for Testing

1. **Postman/Insomnia**: API testing
2. **curl**: Command-line testing
3. **Azure Portal**: Policy testing in APIM portal
4. **Application Insights**: Monitor policy execution
5. **APIM Analytics**: Track security events

## Key Questions to Answer

1. **Performance Impact**
   - How do policies affect latency?
   - Which policies are most expensive?
   - Caching strategies to mitigate performance impact?

2. **Policy Limits**
   - Maximum policy size
   - Expression complexity limits
   - Nesting depth limits

3. **Error Handling**
   - How to properly handle policy failures?
   - Logging security events
   - Alerting on security violations

4. **Best Practices**
   - Where to apply policies (scope selection)?
   - How to organize policies for maintainability?
   - Version control for policies?

5. **Advanced Scenarios**
   - Dynamic policy configuration
   - External policy fragments
   - Policy testing and CI/CD

## Common Security Anti-Patterns to Avoid

❌ **Storing secrets in policies**
```xml
<!-- WRONG: Secret in policy -->
<set-header name="X-API-Key" exists-action="override">
    <value>super-secret-key-12345</value>
</set-header>
```

✅ **Use Named Values (with Key Vault)**
```xml
<!-- CORRECT: Reference Named Value -->
<set-header name="X-API-Key" exists-action="override">
    <value>{{backend-api-key}}</value>
</set-header>
```

❌ **Overly permissive CORS**
```xml
<!-- WRONG: Allow any origin -->
<cors allow-credentials="true">
    <allowed-origins>
        <origin>*</origin>
    </allowed-origins>
</cors>
```

✅ **Specific CORS origins**
```xml
<!-- CORRECT: Specific origins -->
<cors allow-credentials="true">
    <allowed-origins>
        <origin>https://app.contoso.com</origin>
    </allowed-origins>
</cors>
```

❌ **Exposing detailed error information**
```xml
<!-- WRONG: Leak backend details -->
<on-error>
    <set-body>@(context.LastError.Message)</set-body>
</on-error>
```

✅ **Generic error messages**
```xml
<!-- CORRECT: Generic error -->
<on-error>
    <set-body>An error occurred</set-body>
</on-error>
```

## Integration with Azure Services

### Azure Key Vault Integration
- Store certificates, secrets, keys in Key Vault
- Reference from APIM Named Values
- Use Managed Identity for Key Vault access
- Automatic rotation of secrets

### Azure AD Integration
- OAuth 2.0 authorization server
- JWT token validation
- Claims-based authorization
- B2C for external users

### Application Insights
- Policy execution tracking
- Security event logging
- Performance monitoring
- Custom metrics and alerts

## Policy Templates Library

Create reusable policy fragments:

1. **fragment-jwt-validation.xml**: Standard JWT validation
2. **fragment-rate-limit-by-tier.xml**: Tiered rate limiting
3. **fragment-security-headers.xml**: Common security headers
4. **fragment-error-handling.xml**: Standardized error responses
5. **fragment-backend-auth.xml**: Backend authentication patterns

## Resources and References

### Official Documentation
- [APIM Policy Reference](https://docs.microsoft.com/azure/api-management/api-management-policies)
- [Policy Expressions](https://docs.microsoft.com/azure/api-management/api-management-policy-expressions)
- [Secure APIs using OAuth 2.0 with Azure AD](https://docs.microsoft.com/azure/api-management/api-management-howto-protect-backend-with-aad)

### Security Guides
- [APIM Security Best Practices](https://docs.microsoft.com/azure/api-management/api-management-security-controls)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [Azure Security Baseline for API Management](https://docs.microsoft.com/security/benchmark/azure/baselines/api-management-security-baseline)

### Community Examples
- [Azure-Samples/api-management-policy-samples](https://github.com/Azure-Samples/api-management-policy-samples)
- APIM Policy Toolkit (VS Code extension)

## Findings and Notes

### [Date: TBD] Policy Performance Testing
_Document policy performance impact_

### [Date: TBD] Security Testing Results
_Document security testing outcomes_

### [Date: TBD] Real-World Policy Examples
_Document production-ready policy configurations_

## Next Steps

1. Set up test APIM instance with sample APIs
2. Implement each security policy type
3. Create test suite for policy validation
4. Measure performance impact of policies
5. Build library of reusable policy fragments
6. Document lessons learned and best practices
7. Create CI/CD pipeline for policy deployment

## Related Research Projects

- [APIM Internal Mode & Network Security](../apim-internal-mode-network-security/)
- [APIM Multi-tenant Access Segmentation](../apim-multitenant-access/)
- [APIM Developer Tier Cost-Effective Patterns](../apim-developer-tier-patterns/)
- [APIM Backend Integration Patterns](../apim-backend-integration/)

## Status

**Status**: 🟡 Not Started
**Last Updated**: 2025-11-07
**Estimated Effort**: 10-15 hours
