# Azure APIM Multi-tenant Access Segmentation

Research project focused on understanding how to use Azure API Management to segment access for multiple development teams, projects, or tenants using Products, Subscriptions, Groups, and other APIM constructs.

## Overview

A key scenario for APIM is supporting multiple development teams or projects within a single APIM instance. This research explores how to configure APIM so that:
- Project 1 has 15 APIs backed by Azure Functions (project-1-function-app-1, project-1-function-app-2)
- Project 2 has 5 APIs backed by AKS pods
- Developers can only access APIs relevant to their project
- Each project has isolated subscriptions, keys, and access controls

This is critical for organizations using APIM as a centralized API gateway serving multiple teams or business units.

## Key Concepts

### APIM Organization Model

```
Azure APIM Instance
├── Products (API bundles with access controls)
│   ├── Product 1 (e.g., "Project 1 APIs")
│   │   ├── APIs (15 APIs for Project 1)
│   │   ├── Subscriptions (access keys)
│   │   └── Groups (who can access)
│   └── Product 2 (e.g., "Project 2 APIs")
│       ├── APIs (5 APIs for Project 2)
│       ├── Subscriptions (access keys)
│       └── Groups (who can access)
├── APIs (individual API definitions)
│   ├── API operations
│   ├── Backend services (Function App, AKS, etc.)
│   └── Policies
├── Groups (user collections)
│   ├── Administrators (built-in)
│   ├── Developers (built-in)
│   ├── Guests (built-in)
│   ├── Project 1 Team (custom)
│   └── Project 2 Team (custom)
└── Users
    └── Assigned to Groups
```

### Core APIM Constructs for Multi-tenancy

1. **Products**: Bundle of APIs with access control and usage quotas
2. **Subscriptions**: Keys that provide access to Product APIs
3. **Groups**: Collections of users with permissions to Products
4. **Users**: Individual accounts (from Azure AD, Microsoft Account, or local APIM users)
5. **Policies**: Rules applied at Product, API, or Operation level

## Research Goals

- [ ] Understand Products vs APIs vs Operations hierarchy
- [ ] Configure Products for different projects/teams
- [ ] Create custom Groups for team-based access
- [ ] Generate and manage Subscriptions (API keys)
- [ ] Test access segmentation between projects
- [ ] Implement Azure AD integration for user management
- [ ] Configure developer portal for self-service access
- [ ] Test subscription key isolation
- [ ] Document delegation patterns for user management
- [ ] Create governance model for multi-project APIM

## Scenario: Two Projects, One APIM

### Project 1: Internal Business APIs
- **APIs**: 15 APIs for internal business processes
- **Backend**:
  - `project-1-function-app-1.azurewebsites.net` (10 APIs)
  - `project-1-function-app-2.azurewebsites.net` (5 APIs)
- **Team**: 5 developers
- **Access**: Internal only, authenticated via Azure AD
- **Usage Quotas**: 100,000 calls/month per developer

### Project 2: External Partner APIs
- **APIs**: 5 APIs for external partner integration
- **Backend**: AKS cluster at `project-2-aks.internal.contoso.com`
- **Team**: 3 developers + external partners
- **Access**: Internal developers + partner organizations
- **Usage Quotas**:
  - Internal developers: unlimited
  - Partners: 10,000 calls/month per partner

## Implementation Architecture

### Step 1: Define Products

#### Product 1: "Project 1 - Internal Business APIs"
```bash
# Create Product 1
az apim product create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --product-id project-1-apis \
  --product-name "Project 1 - Internal Business APIs" \
  --description "Internal business process APIs for Project 1 team" \
  --subscription-required true \
  --approval-required true \
  --state published
```

Configuration:
- **Subscription required**: Yes (requires API key)
- **Approval required**: Yes (admin must approve subscription requests)
- **Published**: Yes
- **Terms of use**: Internal use only

#### Product 2: "Project 2 - Partner Integration APIs"
```bash
# Create Product 2
az apim product create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --product-id project-2-apis \
  --product-name "Project 2 - Partner Integration APIs" \
  --description "Partner integration APIs for Project 2" \
  --subscription-required true \
  --approval-required true \
  --state published
```

### Step 2: Create Custom Groups

#### Group for Project 1 Team
```bash
# Create Group for Project 1
az apim group create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --group-id project-1-team \
  --display-name "Project 1 Team" \
  --description "Developers working on Project 1"
```

#### Group for Project 2 Team
```bash
# Create Group for Project 2
az apim group create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --group-id project-2-team \
  --display-name "Project 2 Team" \
  --description "Developers and partners for Project 2"
```

#### Group for External Partners
```bash
# Create Group for External Partners
az apim group create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --group-id external-partners \
  --display-name "External Partners" \
  --description "External partner organizations"
```

### Step 3: Assign Groups to Products

```bash
# Assign Project 1 Team to Product 1
az apim product group add \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --product-id project-1-apis \
  --group-id project-1-team

# Assign Project 2 Team to Product 2
az apim product group add \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --product-id project-2-apis \
  --group-id project-2-team

# Assign External Partners to Product 2
az apim product group add \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --product-id project-2-apis \
  --group-id external-partners
```

### Step 4: Create APIs

#### Project 1 API Example
```bash
# Create API for Project 1 Function App 1
az apim api create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --api-id project1-orders-api \
  --display-name "Orders API" \
  --path "project1/orders" \
  --service-url "https://project-1-function-app-1.azurewebsites.net/api" \
  --protocols https

# Add API to Product 1
az apim product api add \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --product-id project-1-apis \
  --api-id project1-orders-api
```

Repeat for all 15 Project 1 APIs across both Function Apps.

#### Project 2 API Example
```bash
# Create API for Project 2 AKS Backend
az apim api create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --api-id project2-partner-api \
  --display-name "Partner Integration API" \
  --path "project2/partners" \
  --service-url "https://project-2-aks.internal.contoso.com/api" \
  --protocols https

# Add API to Product 2
az apim product api add \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --product-id project-2-apis \
  --api-id project2-partner-api
```

Repeat for all 5 Project 2 APIs.

### Step 5: User Management

#### Option 1: Azure AD Integration (Recommended)
```bash
# Configure Azure AD as identity provider
# Users authenticate with corporate credentials
# Groups can be synced from Azure AD
```

Benefits:
- Single sign-on (SSO)
- Centralized user management
- Azure AD security features (MFA, Conditional Access)
- Group membership from Azure AD

#### Option 2: Local APIM Users
```bash
# Create local user
az apim user create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --user-id developer1 \
  --email developer1@contoso.com \
  --first-name "John" \
  --last-name "Doe" \
  --password "SecurePassword123!" \
  --state active

# Add user to group
az apim group user add \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --group-id project-1-team \
  --user-id developer1
```

### Step 6: Subscription Management

#### Project 1 Developer Subscription
```bash
# Create subscription for Project 1 developer
az apim subscription create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --subscription-id project1-dev1-sub \
  --display-name "Developer 1 - Project 1 APIs" \
  --scope /products/project-1-apis \
  --state active

# Get subscription keys
az apim subscription show \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --subscription-id project1-dev1-sub
```

#### Partner Subscription with Quota
```bash
# Create subscription for partner
az apim subscription create \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --subscription-id partner1-sub \
  --display-name "Partner Organization 1" \
  --scope /products/project-2-apis \
  --state active
```

Apply quota policy at Product level:
```xml
<policies>
    <inbound>
        <!-- 10,000 calls per month for partners -->
        <quota-by-key calls="10000" renewal-period="2629800" counter-key="@(context.Subscription.Id)" />
    </inbound>
</policies>
```

## Access Control Patterns

### Pattern 1: Complete Isolation
- Project 1 users can ONLY see/access Project 1 Product
- Project 2 users can ONLY see/access Project 2 Product
- No cross-project access

**Implementation**: Assign groups to specific products only

### Pattern 2: Shared Core + Project-Specific
- Core/shared APIs available to all projects
- Project-specific APIs isolated to their teams

**Implementation**:
- Create "Shared APIs" product accessible to all
- Create project-specific products with team-only access

### Pattern 3: Hierarchical Access
- Admins can access all APIs
- Team leads can access their project + shared APIs
- Developers can access only their project APIs

**Implementation**: Use nested groups or multiple group assignments

### Pattern 4: Partner Portal Isolation
- Internal developers: Full developer portal access
- External partners: Limited portal view (only their APIs)
- Public users: No developer portal access

**Implementation**: Use portal visibility settings + custom groups

## Developer Portal Configuration

### Portal Visibility Settings

1. **Full Access** (Internal Developers)
   - See all assigned products
   - Create subscriptions
   - Test APIs in portal
   - View documentation
   - Download OpenAPI specs

2. **Limited Access** (External Partners)
   - See only assigned product
   - Request subscriptions (require approval)
   - View API documentation
   - No admin features

3. **Public** (Anonymous)
   - View public API catalog (if enabled)
   - Sign up for account
   - No API access without approval

### Customizing Developer Portal

- Custom branding per product
- Different landing pages for different groups
- Hide/show portal sections based on group membership
- Custom documentation per product

## Azure AD Integration Deep Dive

### Benefits for Multi-tenancy

1. **Group Synchronization**
   - Sync Azure AD groups to APIM groups
   - Automatic membership management
   - Leverage existing organizational structure

2. **Security**
   - Azure AD MFA enforcement
   - Conditional Access policies
   - Identity Protection

3. **External Identities**
   - Azure AD B2B for partner access
   - Guest users with controlled permissions

### Configuration Steps

```bash
# 1. Register APIM with Azure AD
# 2. Configure Azure AD as identity provider in APIM
# 3. Map Azure AD groups to APIM groups
# 4. Configure sign-in/sign-up policies
```

Example Azure AD group mapping:
- Azure AD Group: "Engineering-Project1" → APIM Group: "project-1-team"
- Azure AD Group: "Engineering-Project2" → APIM Group: "project-2-team"
- Azure AD Group: "ExternalPartners" → APIM Group: "external-partners"

## Subscription Key Management

### Key Types

1. **Primary Key**: Main subscription key
2. **Secondary Key**: Backup key for rotation

### Key Rotation Strategy

```bash
# Step 1: Regenerate secondary key
az apim subscription regenerate-key \
  --resource-group rg-apim \
  --service-name apim-multitenant \
  --subscription-id project1-dev1-sub \
  --key-type secondary

# Step 2: Update clients to use secondary key
# Step 3: Regenerate primary key
# Step 4: Update clients back to primary key
```

### Best Practices

- Rotate keys quarterly
- Use secondary key for zero-downtime rotation
- Store keys in Azure Key Vault
- Never commit keys to source control
- Implement key expiration policies

## Product-Level Policies for Segmentation

### Project 1 Product Policy
```xml
<policies>
    <inbound>
        <!-- Require Azure AD authentication for internal teams -->
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
            <openid-config url="https://login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration" />
            <required-claims>
                <claim name="groups">
                    <value>{project-1-ad-group-id}</value>
                </claim>
            </required-claims>
        </validate-jwt>

        <!-- Rate limit: 100 calls/minute per subscription -->
        <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription.Id)" />

        <!-- Monthly quota: 100,000 calls -->
        <quota-by-key calls="100000" renewal-period="2629800" counter-key="@(context.Subscription.Id)" />

        <!-- Log to project-specific App Insights -->
        <set-header name="X-Project-Id" exists-action="override">
            <value>project-1</value>
        </set-header>
    </inbound>
</policies>
```

### Project 2 Product Policy (Partners)
```xml
<policies>
    <inbound>
        <!-- Different quotas for internal vs external -->
        <choose>
            <when condition="@(context.User.Groups.Any(g => g.Name == "project-2-team"))">
                <!-- Internal: unlimited -->
                <rate-limit-by-key calls="1000" renewal-period="60" counter-key="@(context.Subscription.Id)" />
            </when>
            <otherwise>
                <!-- External partners: limited -->
                <rate-limit-by-key calls="10" renewal-period="60" counter-key="@(context.Subscription.Id)" />
                <quota-by-key calls="10000" renewal-period="2629800" counter-key="@(context.Subscription.Id)" />
            </otherwise>
        </choose>

        <!-- Require subscription key -->
        <check-header name="Ocp-Apim-Subscription-Key" failed-check-httpcode="401" />

        <!-- Log to project-specific App Insights -->
        <set-header name="X-Project-Id" exists-action="override">
            <value>project-2</value>
        </set-header>
    </inbound>
</policies>
```

## Monitoring and Analytics per Project

### Separate Application Insights

Option 1: Single App Insights with filtering
- Use custom dimension for project ID
- Filter in queries: `customDimensions.ProjectId == "project-1"`

Option 2: Separate App Insights per project
- Configure at Product or API level
- Completely isolated telemetry
- Separate billing

### Usage Analytics

Key metrics to track per project:
- API calls per subscription
- Error rates per product
- Latency by project
- Quota consumption
- Top API consumers

## Testing Multi-tenant Segmentation

### Test Scenarios

1. **Access Control**
   - [ ] Project 1 user cannot access Project 2 APIs
   - [ ] Project 2 user cannot access Project 1 APIs
   - [ ] Admin can access all APIs
   - [ ] Unauthenticated user cannot access any APIs

2. **Subscription Isolation**
   - [ ] Project 1 subscription key works for Project 1 APIs
   - [ ] Project 1 subscription key fails for Project 2 APIs
   - [ ] Revoked subscription is immediately blocked

3. **Developer Portal**
   - [ ] Project 1 user sees only Project 1 APIs in portal
   - [ ] External partner sees only Project 2 APIs
   - [ ] Anonymous user cannot access portal

4. **Quotas and Rate Limits**
   - [ ] Project 1 quota is independent of Project 2
   - [ ] Rate limit applies per subscription
   - [ ] Quota resets properly after period

5. **Azure AD Integration**
   - [ ] Azure AD group members auto-assigned to APIM groups
   - [ ] Removed AD group members lose APIM access
   - [ ] Guest users (B2B) work for partners

## Real-World Scenarios

### Scenario 1: Adding a New Project (Project 3)
Steps:
1. Create new Product "project-3-apis"
2. Create new Group "project-3-team"
3. Assign group to product
4. Create APIs and add to product
5. Invite users and assign to group
6. Generate subscriptions

### Scenario 2: Developer Moves from Project 1 to Project 2
Steps:
1. Remove user from "project-1-team" group
2. Add user to "project-2-team" group
3. Revoke Project 1 subscriptions
4. Create new Project 2 subscription
5. User's portal view updates automatically

### Scenario 3: Partner Relationship Ends
Steps:
1. Suspend/revoke partner subscriptions
2. Remove partner user from groups
3. Archive partner data/logs
4. Document termination

### Scenario 4: Merger/Acquisition (Combining Projects)
Steps:
1. Option A: Merge products (complex)
2. Option B: Cross-assign groups to both products
3. Gradually migrate APIs
4. Update backend service URLs

## Key Questions to Answer

1. **Group Management**
   - How to efficiently manage 50+ custom groups?
   - Best practices for group naming conventions?
   - Azure AD sync vs manual group management?

2. **Product Strategy**
   - One product per project vs one product per environment?
   - How many APIs per product is optimal?
   - When to split products?

3. **Subscription Management**
   - One subscription per user or per application?
   - How to handle multiple environments (dev/test/prod)?
   - Subscription lifecycle management?

4. **Cost Allocation**
   - How to track costs per project?
   - Chargeback models for shared APIM?
   - Monitoring and reporting per tenant?

5. **Governance**
   - Who creates products/APIs/groups?
   - Approval workflows for new tenants?
   - API versioning across projects?
   - Deprecation policies?

## Resources and References

### Official Documentation
- [APIM Products](https://docs.microsoft.com/azure/api-management/api-management-howto-add-products)
- [APIM Groups](https://docs.microsoft.com/azure/api-management/api-management-howto-create-groups)
- [APIM Subscriptions](https://docs.microsoft.com/azure/api-management/api-management-subscriptions)
- [Azure AD Integration](https://docs.microsoft.com/azure/api-management/api-management-howto-aad)

### Multi-tenancy Patterns
- [Multi-tenant SaaS patterns](https://docs.microsoft.com/azure/architecture/guide/multitenant/overview)
- [APIM for ISVs (Multi-tenant)](https://docs.microsoft.com/azure/api-management/api-management-howto-provision-self-hosted-gateway)

### Developer Portal
- [Customize Developer Portal](https://docs.microsoft.com/azure/api-management/api-management-howto-developer-portal-customize)
- [Developer Portal Templates](https://docs.microsoft.com/azure/api-management/api-management-developer-portal-templates)

## Findings and Notes

### [Date: TBD] Initial Multi-tenant Setup
_Document initial configuration and lessons learned_

### [Date: TBD] Azure AD Integration Testing
_Document Azure AD integration experience_

### [Date: TBD] Scale Testing
_Test with 10+ projects, 100+ users_

## Next Steps

1. Create Products for Project 1 and Project 2
2. Set up custom Groups for each team
3. Create sample APIs for both projects
4. Configure Azure AD integration
5. Test access segmentation
6. Document best practices
7. Create automation scripts for onboarding new projects

## Related Research Projects

- [APIM Internal Mode & Network Security](../apim-internal-mode-network-security/)
- [APIM Policy Security Best Practices](../apim-policy-security/)
- [APIM Developer Tier Cost-Effective Patterns](../apim-developer-tier-patterns/)
- [APIM Backend Integration Patterns](../apim-backend-integration/)

## Status

**Status**: 🟡 Not Started
**Last Updated**: 2025-11-07
**Estimated Effort**: 12-16 hours
