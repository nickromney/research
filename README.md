# research
Research repository for LLM coding agents. Heavily inspired by simonw/research and https://simonwillison.net/2025/Nov/6/async-code-research/

## Projects

### github-release-action (2025-11-07)

A TypeScript GitHub Action that checks GitHub release versions against configurable expiry policies. This is a conversion of the [github-release-version-checker](https://github.com/nickromney-org/github-release-version-checker) Go CLI tool into a reusable GitHub Action for CI/CD workflows.

Features:
- Check if your version is current, approaching expiry, or expired
- Days-based policy (e.g., runners must update within 30 days)
- Version-based policy (e.g., Kubernetes N-3 minor version support)
- Multiple output formats for GitHub Actions

## API Learning Guides for Infrastructure Engineers (2025-11-07)

Comprehensive guides designed for infrastructure engineers transitioning into API-driven architectures. These guides bridge traditional infrastructure knowledge with modern API concepts using command-line tools and hands-on labs.

### [api-fundamentals-for-infrastructure](./api-fundamentals-for-infrastructure/)

A complete guide to API fundamentals tailored for infrastructure engineers, focusing on command-line tools and practical examples.

Topics:
- REST API basics from an infrastructure perspective
- Command-line HTTP clients (curl, xh, httpie, bruno-cli)
- HTTP methods, status codes, and headers explained for ops engineers
- Working with JSON using jq and command-line tools
- API authentication methods (API keys, Basic Auth, Bearer tokens, JWT, OAuth 2.0)
- Practical examples with public APIs (GitHub, httpbin, JSONPlaceholder)
- Bash scripting for API automation
- Debugging and troubleshooting APIs
- API infrastructure patterns (rate limiting, pagination, webhooks, health checks)

**Why this guide?**
- Command-line focused (no GUI required)
- Infrastructure perspective (analogies to SSH, file systems, exit codes)
- Hands-on examples with real APIs
- Bash automation scripts included

### [mock-api-lab](./mock-api-lab/)

Hands-on laboratory for building and testing APIs locally before deploying to Azure APIM. Provides a cost-free sandbox to practice API concepts.

Topics:
- Building REST APIs with LoopBack (Node.js framework)
- Creating mock OAuth 2.0 servers for testing
- Simulating Azure APIM scenarios (rate limiting, subscription keys, policies)
- Command-line testing with curl, xh, and bruno-cli
- JWT authentication implementation
- APIM gateway simulation with Node.js
- Circuit breaker patterns
- Request/response transformation
- Alternative mock tools (JSON Server, Mockoon, Prism, WireMock)

**Why this lab?**
- No Azure APIM simulator exists - this fills the gap
- Practice locally before cloud deployment
- Free to run (no cloud costs)
- Working code examples (LoopBack, OAuth2 server, APIM simulator)
- Command-line focused for infrastructure engineers
- Bash scripts for testing and automation

**Lab Components:**
1. **LoopBack API**: Full REST API with CRUD operations
2. **Mock OAuth2 Server**: Client credentials and password grant flows
3. **APIM Simulator**: Rate limiting, subscription keys, policy execution
4. **Test Scripts**: Automated testing with bash

## Azure API Management Research Projects (2025-11-07)

A comprehensive set of research projects focused on learning Azure API Management (APIM) with an emphasis on security, cost-effectiveness, and practical implementation patterns.

### [apim-internal-mode-network-security](./apim-internal-mode-network-security/)

Research focused on securing Azure APIM at the infrastructure level by deploying in "Internal" mode with VNet integration.

Topics:
- APIM network connectivity modes (External, Internal, None)
- VNet integration and subnet planning
- DNS configuration for internal endpoints
- NSG requirements and security rules
- Integration with Application Gateway and Azure Firewall
- Private endpoints vs service endpoints
- Cost analysis across different deployment models

### [apim-policy-security](./apim-policy-security/)

Research focused on securing individual API policies using authentication, authorization, rate limiting, and other security patterns.

Topics:
- Authentication policies (API keys, OAuth 2.0, JWT validation)
- Rate limiting and quota management
- IP filtering and geofencing
- Request/response validation
- CORS configuration
- Header security and manipulation
- Circuit breaker and retry patterns
- Backend security and error handling

### [apim-multitenant-access](./apim-multitenant-access/)

Research focused on configuring APIM to support multiple development teams or projects with segmented access using Products, Subscriptions, and Groups.

Topics:
- APIM organization model (Products, APIs, Groups, Users)
- Multi-project access segmentation patterns
- Azure AD integration for user management
- Subscription and API key management
- Developer portal customization per tenant
- Product-level policies for isolation
- Monitoring and analytics per project
- Real-world multi-tenant scenarios

### [apim-developer-tier-patterns](./apim-developer-tier-patterns/)

Research focused on cost-effective learning strategies for Azure APIM, including Developer tier usage and Pluralsight sandbox optimization.

Topics:
- APIM tier comparison and cost analysis
- Developer tier capabilities and limitations
- Deploy-test-destroy patterns for cost savings
- Pluralsight sandbox strategies (4-hour sessions)
- Infrastructure as Code templates (Bicep/Terraform)
- Free/cheap backend services for testing
- Cost monitoring and billing alerts
- Learning path with cost optimization
- Avoiding expensive samples and patterns

### [apim-backend-integration](./apim-backend-integration/)

Research focused on integrating APIM with various backend services including Azure Functions, AKS, App Services, and Container Apps.

Topics:
- Backend integration patterns (Functions, AKS, App Service, Container Apps)
- Backend authentication methods (Managed Identity, certificates, OAuth)
- Service discovery and DNS configuration
- Load balancing and backend pools
- Circuit breaker and retry policies
- Request/response transformation
- Performance optimization and caching
- Health monitoring and observability
- Multi-backend routing scenarios
