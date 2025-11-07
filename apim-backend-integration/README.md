# Azure APIM Backend Integration Patterns

Research project focused on integrating Azure API Management with various backend services including Azure Functions, Azure Kubernetes Service (AKS), App Services, Container Apps, and external APIs.

## Overview

APIM acts as a gateway/facade in front of backend services. This research explores different backend integration patterns, authentication methods, service discovery, load balancing, and best practices for connecting APIM to various Azure compute services and external APIs.

## Key Concepts

### Backend Service Types

1. **Azure Functions**
   - Serverless, consumption-based
   - Function-level or app-level endpoints
   - Built-in authentication options

2. **Azure Kubernetes Service (AKS)**
   - Container orchestration
   - Internal/external services
   - Service mesh integration

3. **Azure App Service**
   - Web Apps, API Apps
   - Built-in authentication
   - Scaling options

4. **Azure Container Apps**
   - Serverless containers
   - Event-driven scaling
   - Revisions and traffic splitting

5. **Azure Logic Apps**
   - Workflow automation
   - HTTP trigger integration

6. **External APIs**
   - Third-party services
   - On-premises systems
   - Partner APIs

### Backend Authentication Methods

1. **No authentication** (public endpoints)
2. **API Keys/Subscription keys** (APIM → Backend)
3. **Certificate-based** authentication
4. **Managed Identity** (recommended for Azure services)
5. **OAuth 2.0 / JWT** tokens
6. **Basic authentication** (username/password)
7. **Custom authentication** headers

## Research Goals

- [ ] Deploy Azure Function App and integrate with APIM
- [ ] Deploy AKS cluster with sample API and connect to APIM
- [ ] Test managed identity authentication from APIM to backends
- [ ] Configure certificate-based backend authentication
- [ ] Test backend URL rewriting and routing patterns
- [ ] Implement circuit breaker pattern for backend failures
- [ ] Configure backend pools and load balancing
- [ ] Test service discovery patterns (especially with AKS)
- [ ] Document performance considerations for each backend type
- [ ] Create reusable backend configuration templates

## Backend Pattern 1: Azure Functions

### Scenario
- Project 1 has 10 APIs served by Function App 1
- Project 1 has 5 APIs served by Function App 2
- Need to route APIM requests to correct Function App

### Architecture
```
APIM
├── API: Orders (5 operations)
│   └── Backend: project-1-function-app-1.azurewebsites.net
├── API: Inventory (5 operations)
│   └── Backend: project-1-function-app-1.azurewebsites.net
└── API: Customers (5 operations)
    └── Backend: project-1-function-app-2.azurewebsites.net
```

### Deployment: Azure Function Backend

#### Step 1: Create Function App
```bash
# Create storage account for Function App
az storage account create \
  --name stgfuncapim${RANDOM} \
  --resource-group rg-apim \
  --location eastus \
  --sku Standard_LRS

# Create Function App (Consumption plan)
az functionapp create \
  --resource-group rg-apim \
  --name project-1-function-app-1 \
  --storage-account stgfuncapim \
  --consumption-plan-location eastus \
  --runtime node \
  --runtime-version 18 \
  --functions-version 4
```

#### Step 2: Deploy Sample Function
```javascript
// HttpTrigger function (index.js)
module.exports = async function (context, req) {
    context.log('Processing request from APIM');

    const name = req.query.name || (req.body && req.body.name) || 'World';

    context.res = {
        status: 200,
        body: {
            message: `Hello ${name} from Function App`,
            timestamp: new Date().toISOString(),
            backend: 'project-1-function-app-1'
        },
        headers: {
            'Content-Type': 'application/json'
        }
    };
};
```

```json
// function.json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get", "post"],
      "route": "orders/{id?}"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
```

#### Step 3: Configure APIM Backend

##### Option A: Direct Backend URL in API
```bash
# Create API with Function backend
az apim api create \
  --resource-group rg-apim \
  --service-name apim-dev \
  --api-id orders-api \
  --display-name "Orders API" \
  --path "orders" \
  --service-url "https://project-1-function-app-1.azurewebsites.net/api" \
  --protocols https
```

##### Option B: Named Backend (Reusable)
```bash
# Create named backend
az apim backend create \
  --resource-group rg-apim \
  --service-name apim-dev \
  --backend-id func-app-1-backend \
  --url "https://project-1-function-app-1.azurewebsites.net/api" \
  --protocol http \
  --description "Project 1 Function App 1"

# Reference in API policy
```

```xml
<policies>
    <inbound>
        <set-backend-service backend-id="func-app-1-backend" />
    </inbound>
</policies>
```

### Function Authentication Patterns

#### Pattern 1: Function Key in APIM Policy
```xml
<policies>
    <inbound>
        <!-- Get Function key from Named Value -->
        <set-header name="x-functions-key" exists-action="override">
            <value>{{function-app-1-key}}</value>
        </set-header>
    </inbound>
</policies>
```

**Setup**: Store Function key in APIM Named Values (linked to Key Vault)

#### Pattern 2: Managed Identity (Recommended)
```bash
# Enable managed identity on APIM
az apim update \
  --resource-group rg-apim \
  --name apim-dev \
  --set identity.type=SystemAssigned

# Get APIM managed identity
APIM_IDENTITY=$(az apim show --resource-group rg-apim --name apim-dev --query identity.principalId -o tsv)

# Grant APIM access to Function App
az role assignment create \
  --role "Website Contributor" \
  --assignee $APIM_IDENTITY \
  --scope /subscriptions/{sub-id}/resourceGroups/rg-apim/providers/Microsoft.Web/sites/project-1-function-app-1
```

**APIM Policy**:
```xml
<policies>
    <inbound>
        <!-- Use managed identity to authenticate -->
        <authentication-managed-identity resource="https://management.azure.com/" />
    </inbound>
</policies>
```

#### Pattern 3: Azure AD Authentication
```xml
<policies>
    <inbound>
        <!-- Get token for Function App -->
        <authentication-managed-identity resource="https://project-1-function-app-1.azurewebsites.net" output-token-variable-name="function-token" />
        <set-header name="Authorization" exists-action="override">
            <value>@("Bearer " + (string)context.Variables["function-token"])</value>
        </set-header>
    </inbound>
</policies>
```

## Backend Pattern 2: Azure Kubernetes Service (AKS)

### Scenario
- Project 2 has 5 APIs served by pods in AKS
- APIM needs to route to internal AKS service
- Load balancing across pods
- Service mesh integration (Istio/Linkerd)

### Architecture
```
APIM (External or Internal mode)
  ↓
  VNet Peering or Internal Network
  ↓
AKS Cluster
├── Service: partner-api (LoadBalancer or ClusterIP)
│   ├── Pod 1
│   ├── Pod 2
│   └── Pod 3
└── Ingress Controller (optional)
```

### Deployment: AKS Backend

#### Step 1: Create AKS Cluster
```bash
# Create AKS cluster
az aks create \
  --resource-group rg-apim \
  --name aks-apim-backend \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-managed-identity \
  --generate-ssh-keys

# Get credentials
az aks get-credentials \
  --resource-group rg-apim \
  --name aks-apim-backend
```

#### Step 2: Deploy Sample API to AKS
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: partner-api
  labels:
    app: partner-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: partner-api
  template:
    metadata:
      labels:
        app: partner-api
    spec:
      containers:
      - name: api
        image: kennethreitz/httpbin
        ports:
        - containerPort: 80
        env:
        - name: BACKEND_NAME
          value: "AKS-PartnerAPI"
---
apiVersion: v1
kind: Service
metadata:
  name: partner-api-service
spec:
  type: LoadBalancer  # Or ClusterIP if APIM is internal
  selector:
    app: partner-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

```bash
# Deploy to AKS
kubectl apply -f deployment.yaml

# Get service external IP (if LoadBalancer)
kubectl get service partner-api-service
```

#### Step 3: Configure APIM to AKS Backend

##### Scenario A: AKS with Public LoadBalancer
```bash
# Get AKS service external IP
AKS_IP=$(kubectl get service partner-api-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Create APIM API pointing to AKS
az apim api create \
  --resource-group rg-apim \
  --service-name apim-dev \
  --api-id partner-api \
  --display-name "Partner API" \
  --path "partners" \
  --service-url "http://${AKS_IP}" \
  --protocols https
```

##### Scenario B: AKS with Internal Service + APIM Internal Mode
```bash
# AKS uses ClusterIP service
# APIM in Internal VNet mode
# VNet peering between APIM VNet and AKS VNet

# Use internal AKS service DNS name
# partner-api-service.default.svc.cluster.local
```

**APIM Backend Configuration**:
```bash
az apim backend create \
  --resource-group rg-apim \
  --service-name apim-dev \
  --backend-id aks-partner-backend \
  --url "http://partner-api-service.default.svc.cluster.local" \
  --protocol http
```

##### Scenario C: AKS with Ingress Controller
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: partner-api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: partner-api.internal.contoso.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: partner-api-service
            port:
              number: 80
```

**APIM Backend**:
```bash
az apim api create \
  --resource-group rg-apim \
  --service-name apim-dev \
  --api-id partner-api \
  --service-url "http://partner-api.internal.contoso.com" \
  --path "partners"
```

### AKS Authentication Patterns

#### Pattern 1: Mutual TLS (mTLS)
```xml
<policies>
    <inbound>
        <!-- Client certificate for backend authentication -->
        <authentication-certificate thumbprint="cert-thumbprint" />
    </inbound>
</policies>
```

#### Pattern 2: API Key Header
```xml
<policies>
    <inbound>
        <set-header name="X-API-Key" exists-action="override">
            <value>{{aks-backend-api-key}}</value>
        </set-header>
    </inbound>
</policies>
```

#### Pattern 3: Service Mesh (Istio) Integration
- Configure Istio ingress gateway
- APIM → Istio Ingress → Service Mesh → Pods
- mTLS within service mesh
- Policy enforcement at mesh level

## Backend Pattern 3: App Service

### Scenario
- Legacy API hosted on App Service
- Need to integrate with APIM
- Use App Service built-in authentication

### Deployment
```bash
# Create App Service
az appservice plan create \
  --name asp-apim-backend \
  --resource-group rg-apim \
  --sku B1 \
  --is-linux

az webapp create \
  --name webapp-apim-backend \
  --resource-group rg-apim \
  --plan asp-apim-backend \
  --runtime "NODE:18-lts"

# Configure APIM API
az apim api create \
  --resource-group rg-apim \
  --service-name apim-dev \
  --api-id legacy-api \
  --service-url "https://webapp-apim-backend.azurewebsites.net" \
  --path "legacy"
```

### App Service Authentication
```xml
<policies>
    <inbound>
        <!-- Use managed identity -->
        <authentication-managed-identity resource="https://webapp-apim-backend.azurewebsites.net" />
    </inbound>
</policies>
```

## Backend Pattern 4: Container Apps

### Scenario
- Modern microservices on Container Apps
- Event-driven scaling
- Multiple revisions for blue/green deployments

### Deployment
```bash
# Create Container App environment
az containerapp env create \
  --name env-apim-backend \
  --resource-group rg-apim \
  --location eastus

# Create Container App
az containerapp create \
  --name ca-partner-api \
  --resource-group rg-apim \
  --environment env-apim-backend \
  --image kennethreitz/httpbin \
  --target-port 80 \
  --ingress external \
  --query properties.configuration.ingress.fqdn

# Configure APIM
az apim api create \
  --resource-group rg-apim \
  --service-name apim-dev \
  --api-id containerapp-api \
  --service-url "https://ca-partner-api.{env-domain}" \
  --path "containerapp"
```

## Advanced Backend Patterns

### Pattern 1: Backend Load Balancing (Backend Pool)
```xml
<policies>
    <inbound>
        <set-backend-service backend-id="backend-pool-1" />
    </inbound>
</policies>
```

Create backend pool:
```bash
# Create multiple backends
az apim backend create --backend-id func-app-1 --url "https://func1.azurewebsites.net/api"
az apim backend create --backend-id func-app-2 --url "https://func2.azurewebsites.net/api"

# Create backend pool (via ARM template or portal)
# Round-robin or priority-based load balancing
```

### Pattern 2: Circuit Breaker
```xml
<policies>
    <inbound>
        <set-backend-service backend-id="primary-backend" />
    </inbound>
    <backend>
        <!-- Circuit breaker logic -->
        <forward-request timeout="10" />
    </backend>
    <on-error>
        <choose>
            <when condition="@(context.LastError.Reason == "timeout")">
                <!-- Fallback to secondary backend -->
                <set-backend-service backend-id="secondary-backend" />
                <forward-request />
            </when>
            <otherwise>
                <return-response>
                    <set-status code="503" reason="Service Unavailable" />
                </return-response>
            </otherwise>
        </choose>
    </on-error>
</policies>
```

### Pattern 3: Dynamic Backend Routing
```xml
<policies>
    <inbound>
        <!-- Route based on request path, header, or other criteria -->
        <choose>
            <when condition="@(context.Request.Url.Path.StartsWith("/v1/"))">
                <set-backend-service backend-id="backend-v1" />
            </when>
            <when condition="@(context.Request.Url.Path.StartsWith("/v2/"))">
                <set-backend-service backend-id="backend-v2" />
            </when>
            <otherwise>
                <set-backend-service backend-id="backend-default" />
            </otherwise>
        </choose>
    </inbound>
</policies>
```

### Pattern 4: Request/Response Transformation
```xml
<policies>
    <inbound>
        <!-- Transform APIM request to backend format -->
        <set-header name="X-Source" exists-action="override">
            <value>APIM</value>
        </set-header>

        <!-- Rewrite URL -->
        <rewrite-uri template="/api/v2{path}" />

        <!-- Transform body -->
        <set-body>@{
            var body = context.Request.Body.As<JObject>();
            body["timestamp"] = DateTime.UtcNow.ToString();
            return body.ToString();
        }</set-body>
    </inbound>

    <outbound>
        <!-- Transform backend response to APIM format -->
        <set-body>@{
            var response = context.Response.Body.As<JObject>();
            return new JObject(
                new JProperty("data", response),
                new JProperty("meta", new JObject(
                    new JProperty("timestamp", DateTime.UtcNow)
                ))
            ).ToString();
        }</set-body>
    </outbound>
</policies>
```

### Pattern 5: Caching Backend Responses
```xml
<policies>
    <inbound>
        <!-- Cache lookup -->
        <cache-lookup vary-by-developer="false" vary-by-developer-groups="false">
            <vary-by-header>Accept</vary-by-header>
            <vary-by-query-parameter>category</vary-by-query-parameter>
        </cache-lookup>
    </inbound>

    <outbound>
        <!-- Cache response for 5 minutes -->
        <cache-store duration="300" />
    </outbound>
</policies>
```

### Pattern 6: Backend Timeout & Retry
```xml
<policies>
    <inbound>
        <!-- Set custom timeout -->
        <set-backend-service backend-id="slow-backend" />
    </inbound>

    <backend>
        <retry condition="@(context.Response.StatusCode >= 500)" count="3" interval="1" first-fast-retry="true">
            <forward-request timeout="30" />
        </retry>
    </backend>
</policies>
```

## Backend Service Discovery

### Challenge
In dynamic environments (especially AKS), backend service IPs/endpoints may change.

### Solutions

#### 1. Azure DNS Private Zones
```bash
# Create private DNS zone
az network private-dns zone create \
  --resource-group rg-apim \
  --name internal.contoso.com

# Link to VNet
az network private-dns link vnet create \
  --resource-group rg-apim \
  --zone-name internal.contoso.com \
  --name dns-link \
  --virtual-network vnet-apim \
  --registration-enabled true
```

APIM backend uses DNS name:
```
http://partner-api.internal.contoso.com
```

#### 2. AKS Service DNS (within cluster)
```
http://service-name.namespace.svc.cluster.local
```

Requires APIM to be able to resolve internal cluster DNS (complex setup).

#### 3. Ingress Controller with Static DNS
- Deploy NGINX/Traefik ingress in AKS
- Assign static public IP or internal IP
- Configure DNS to point to ingress IP
- APIM connects to DNS name, ingress routes to services

#### 4. Azure Application Gateway
```
Internet/VNet → APIM → Application Gateway → AKS
```

Application Gateway provides:
- Load balancing
- SSL termination
- WAF capabilities
- Health probes

## Backend Health Monitoring

### APIM Health Probes
Configure health endpoint on backend:
```javascript
// Health check endpoint in backend
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', timestamp: new Date() });
});
```

### APIM Backend Health Check Policy
```xml
<policies>
    <inbound>
        <!-- Check backend health before routing -->
        <send-request mode="new" response-variable-name="healthcheck" timeout="5">
            <set-url>@("https://backend.azurewebsites.net/health")</set-url>
            <set-method>GET</set-method>
        </send-request>

        <choose>
            <when condition="@(((IResponse)context.Variables["healthcheck"]).StatusCode != 200)">
                <return-response>
                    <set-status code="503" reason="Backend Unavailable" />
                </return-response>
            </when>
        </choose>
    </inbound>
</policies>
```

**Warning**: This adds latency to every request. Better to use out-of-band health monitoring.

### External Health Monitoring
- Azure Monitor / Application Insights
- Availability tests
- Alert on backend failures
- Automated remediation (restart, scale, failover)

## Performance Considerations

### Backend Type Performance Characteristics

| Backend Type | Cold Start | Latency | Throughput | Cost Model |
|-------------|-----------|---------|------------|-----------|
| Functions (Consumption) | 1-3s | Low | Medium | Per execution |
| Functions (Premium) | <1s | Low | High | Always-on |
| App Service | None | Low | High | Fixed |
| AKS | None | Very Low | Very High | Fixed |
| Container Apps | <1s | Low | High | Per second |
| Logic Apps | 1-2s | Medium | Medium | Per action |

### Optimizations

1. **Function Cold Start Mitigation**
   - Use Premium plan (always warm)
   - Pre-warm with scheduled pings
   - Use Application Insights to monitor cold starts

2. **AKS Performance**
   - HPA (Horizontal Pod Autoscaler)
   - Cluster autoscaler
   - Resource limits and requests
   - Connection pooling

3. **APIM Caching**
   - Cache GET requests when possible
   - Reduce backend load
   - Improve response time
   - Configure appropriate TTL

4. **Connection Reuse**
   - APIM reuses connections to backends (HTTP/1.1 keepalive)
   - Ensure backend supports connection reuse
   - Monitor connection pool exhaustion

## Multi-Backend Scenarios

### Scenario: 20 APIs, 2 Function Apps, 1 AKS Cluster

**Project 1**: 15 APIs
- 10 APIs → Function App 1 (project-1-function-app-1)
  - Orders API (3 operations)
  - Inventory API (3 operations)
  - Products API (2 operations)
  - Shipping API (2 operations)
- 5 APIs → Function App 2 (project-1-function-app-2)
  - Customers API (2 operations)
  - Invoices API (2 operations)
  - Payments API (1 operation)

**Project 2**: 5 APIs
- 5 APIs → AKS (project-2-aks cluster)
  - Partner API (2 operations)
  - Webhooks API (1 operation)
  - Events API (2 operations)

### Configuration Strategy

#### 1. Create Named Backends
```bash
# Backend 1: Function App 1
az apim backend create \
  --backend-id func-app-1 \
  --url "https://project-1-function-app-1.azurewebsites.net/api"

# Backend 2: Function App 2
az apim backend create \
  --backend-id func-app-2 \
  --url "https://project-1-function-app-2.azurewebsites.net/api"

# Backend 3: AKS
az apim backend create \
  --backend-id aks-cluster \
  --url "http://partner-api.internal.contoso.com"
```

#### 2. Create APIs and Reference Backends
```bash
# Orders API → Function App 1
az apim api create \
  --api-id orders-api \
  --path "orders" \
  --service-url "https://project-1-function-app-1.azurewebsites.net/api/orders"

# Alternative: Use policy to set backend
# Set service-url to empty, use policy instead
```

#### 3. Use Product-Level Backend Policy
```xml
<!-- Product: Project 1 APIs -->
<policies>
    <inbound>
        <!-- Default backend for all Project 1 APIs -->
        <choose>
            <when condition="@(context.Api.Id.Contains("orders") || context.Api.Id.Contains("inventory"))">
                <set-backend-service backend-id="func-app-1" />
            </when>
            <when condition="@(context.Api.Id.Contains("customers") || context.Api.Id.Contains("payments"))">
                <set-backend-service backend-id="func-app-2" />
            </when>
        </choose>

        <!-- Authentication -->
        <authentication-managed-identity resource="https://management.azure.com/" />
    </inbound>
</policies>
```

## Backend Authentication Best Practices

### 1. Use Managed Identity (Preferred)
✅ No secrets to manage
✅ Automatic rotation
✅ Azure RBAC integration
✅ Audit trail

### 2. Store Secrets in Key Vault
If managed identity not available:
```bash
# Create Key Vault
az keyvault create --name kv-apim-secrets --resource-group rg-apim

# Store backend API key
az keyvault secret set --vault-name kv-apim-secrets --name backend-api-key --value "secret-value"

# Create Named Value in APIM linked to Key Vault
az apim nv create \
  --service-name apim-dev \
  --resource-group rg-apim \
  --named-value-id backend-api-key \
  --display-name "Backend API Key" \
  --secret true \
  --key-vault-secret-id "https://kv-apim-secrets.vault.azure.net/secrets/backend-api-key"
```

### 3. Certificate-Based Authentication
```bash
# Upload certificate to APIM
az apim certificate create \
  --resource-group rg-apim \
  --service-name apim-dev \
  --certificate-id backend-cert \
  --data @certificate.pfx \
  --password "cert-password"
```

```xml
<policies>
    <inbound>
        <authentication-certificate certificate-id="backend-cert" />
    </inbound>
</policies>
```

### 4. OAuth 2.0 Client Credentials Flow
```xml
<policies>
    <inbound>
        <!-- Get OAuth token -->
        <send-request mode="new" response-variable-name="tokenResponse" timeout="10">
            <set-url>https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token</set-url>
            <set-method>POST</set-method>
            <set-header name="Content-Type" exists-action="override">
                <value>application/x-www-form-urlencoded</value>
            </set-header>
            <set-body>@($"client_id={context.Variables["clientId"]}&client_secret={context.Variables["clientSecret"]}&scope=https://backend/.default&grant_type=client_credentials")</set-body>
        </send-request>

        <!-- Extract token -->
        <set-variable name="accessToken" value="@(((IResponse)context.Variables["tokenResponse"]).Body.As<JObject>()["access_token"].ToString())" />

        <!-- Set Authorization header -->
        <set-header name="Authorization" exists-action="override">
            <value>@("Bearer " + (string)context.Variables["accessToken"])</value>
        </set-header>
    </inbound>
</policies>
```

## Testing Backend Integrations

### Test Checklist

- [ ] APIM can reach backend (network connectivity)
- [ ] Authentication works (managed identity, keys, certs)
- [ ] Request routing is correct
- [ ] Response transformation works
- [ ] Error handling is appropriate
- [ ] Timeouts are configured properly
- [ ] Health checks detect backend failures
- [ ] Load balancing distributes traffic
- [ ] Circuit breaker activates on failures
- [ ] Performance meets requirements

### Testing Tools

1. **APIM Test Console** (in Azure Portal)
2. **Postman** with APIM subscription keys
3. **curl** for command-line testing
4. **Azure Load Testing** for performance tests
5. **Application Insights** for observability

### Sample Tests

#### Test 1: Basic Connectivity
```bash
# Get subscription key
SUBSCRIPTION_KEY=$(az apim subscription list --resource-group rg-apim --service-name apim-dev --query "[0].primaryKey" -o tsv)

# Call APIM API
curl -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" \
  https://apim-dev.azure-api.net/orders/123
```

#### Test 2: Backend Failure Simulation
```bash
# Stop backend service (Function App)
az functionapp stop --name project-1-function-app-1 --resource-group rg-apim

# Call APIM, should get circuit breaker response or error
curl -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" \
  https://apim-dev.azure-api.net/orders/123

# Restart backend
az functionapp start --name project-1-function-app-1 --resource-group rg-apim
```

#### Test 3: Load Testing
```bash
# Use Azure Load Testing or wrk
wrk -t4 -c100 -d30s \
  -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" \
  https://apim-dev.azure-api.net/orders/123
```

## Key Questions to Answer

1. **Performance**
   - Latency impact of APIM vs direct backend call?
   - How does caching improve performance?
   - Connection pooling behavior?

2. **Scalability**
   - How does APIM handle backend scale-out (multiple instances)?
   - Backend pool load balancing strategies?
   - AKS pod scaling behavior with APIM?

3. **Reliability**
   - How to implement circuit breaker effectively?
   - Retry policies best practices?
   - Health check patterns?

4. **Security**
   - Managed identity setup and limitations?
   - Certificate management strategies?
   - Least privilege backend access?

5. **Operations**
   - Backend service discovery automation?
   - Blue/green deployment with APIM?
   - Monitoring backend performance through APIM?

## Resources and References

### Official Documentation
- [APIM Backend Entity](https://docs.microsoft.com/azure/api-management/backends)
- [APIM Policies - set-backend-service](https://docs.microsoft.com/azure/api-management/set-backend-service-policy)
- [APIM with Functions](https://docs.microsoft.com/azure/api-management/import-function-app-as-api)
- [APIM with AKS](https://docs.microsoft.com/azure/api-management/api-management-kubernetes)

### Integration Guides
- [Managed Identity in APIM](https://docs.microsoft.com/azure/api-management/api-management-howto-use-managed-service-identity)
- [APIM + Function App Integration](https://docs.microsoft.com/azure/api-management/import-function-app-as-api)
- [APIM Internal VNet + AKS](https://docs.microsoft.com/azure/architecture/reference-architectures/apis/protect-apis)

### Backend Service Documentation
- [Azure Functions](https://docs.microsoft.com/azure/azure-functions/)
- [Azure Kubernetes Service](https://docs.microsoft.com/azure/aks/)
- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
- [Azure App Service](https://docs.microsoft.com/azure/app-service/)

## Findings and Notes

### [Date: TBD] Function App Integration
_Document Function App integration experience_

### [Date: TBD] AKS Integration
_Document AKS setup and service discovery challenges_

### [Date: TBD] Performance Testing Results
_Document latency and throughput findings_

## Next Steps

1. Deploy Function App and integrate with APIM
2. Deploy AKS cluster with sample API
3. Test managed identity authentication
4. Implement circuit breaker pattern
5. Load test different backend types
6. Document performance characteristics
7. Create reusable backend templates

## Related Research Projects

- [APIM Internal Mode & Network Security](../apim-internal-mode-network-security/)
- [APIM Policy Security Best Practices](../apim-policy-security/)
- [APIM Multi-tenant Access Segmentation](../apim-multitenant-access/)
- [APIM Developer Tier Cost-Effective Patterns](../apim-developer-tier-patterns/)

## Status

**Status**: 🟡 Not Started
**Last Updated**: 2025-11-07
**Estimated Effort**: 12-16 hours
