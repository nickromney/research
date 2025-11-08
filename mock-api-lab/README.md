# Mock API Lab

A hands-on laboratory for building and testing APIs using command-line tools and mock services. This lab provides a safe, cost-free environment to learn API concepts before deploying to Azure APIM.

## Overview

There's no simulator for Azure API Management, so this lab fills that gap by teaching you to:
- Build mock REST APIs with LoopBack (Node.js framework)
- Simulate OAuth 2.0 authentication flows
- Test API patterns with command-line tools
- Practice APIM-like scenarios locally
- Understand API behavior before cloud deployment

**Target Audience**: Infrastructure engineers learning APIs
**Prerequisites**: Basic Linux command line, Node.js installed
**Cost**: Free (runs locally)
**Time**: 3-4 hours for full lab

## Quick Start

### Clone and Go

```bash
# Clone the repository
git clone https://github.com/nickromney/research.git
cd research/mock-api-lab

# Run the install script
./install.sh

# Start both servers (in separate terminals)
# Terminal 1:
cd oauth-server && npm start

# Terminal 2:
cd apim-simulator && npm start

# Or start both with concurrently:
npm run start:all

# Run tests (in a new terminal)
cd scripts
./test-api.sh

# Run interactive demo
./demo.sh

# Run load test
./load-test.sh
```

### What's Included

This repository contains complete working code:

```
mock-api-lab/
├── install.sh                 # Automated setup script
├── package.json              # Root dependencies
├── oauth-server/             # Mock OAuth 2.0 server
│   ├── package.json
│   └── oauth-server.js       # Complete OAuth implementation
├── apim-simulator/           # APIM gateway simulator
│   ├── package.json
│   └── apim-simulator.js     # Rate limiting + subscription keys
└── scripts/                  # Testing scripts
    ├── test-api.sh           # Automated test suite
    ├── load-test.sh          # Load testing
    └── demo.sh               # Interactive demo
```

### Services

Once started, you'll have:

- **OAuth Server**: `http://localhost:3001`
  - Client credentials: `application` / `secret`
  - Test users: `user1/password1`, `admin/admin123`

- **APIM Simulator**: `http://localhost:8080`
  - Subscription keys: `primary-key-12345`, `secondary-key-67890`
  - Rate limiting: 100 req/min (primary), 10 req/min (secondary)

### ⚠️ Security Warning

**This is a learning and testing environment ONLY. DO NOT use in production!**

- Hardcoded credentials (OAuth secrets, API keys, passwords)
- Plaintext password storage
- No encryption or hashing
- In-memory storage (data lost on restart)
- No input validation or sanitization
- SSRF vulnerability in backend query parameter

These are intentional for learning purposes. For production:
- Use environment variables for secrets
- Hash/encrypt passwords (bcrypt, argon2)
- Use persistent databases
- Implement proper input validation
- Whitelist backend URLs
- Follow security best practices

### Quick Tests

```bash
# Test OAuth server
curl http://localhost:3001/health

# Get OAuth token
curl -X POST http://localhost:3001/oauth/token \
  -d 'grant_type=client_credentials' \
  -d 'client_id=application' \
  -d 'client_secret=secret'

# Test APIM (will fail without key)
curl http://localhost:8080/api/get

# Test APIM (with valid key)
curl -H 'Ocp-Apim-Subscription-Key: primary-key-12345' \
  http://localhost:8080/api/get
```

## Table of Contents

1. [Lab Setup](#lab-setup)
2. [Part 1: Building APIs with LoopBack](#part-1-loopback-api)
3. [Part 2: Mock OAuth 2.0 Server](#part-2-mock-oauth2)
4. [Part 3: Simulating APIM Scenarios](#part-3-apim-simulation)
5. [Part 4: Testing with Command-Line Tools](#part-4-command-line-testing)
6. [Part 5: Advanced Patterns](#part-5-advanced-patterns)
7. [Bonus: Alternative Mock Tools](#bonus-alternative-tools)

---

## Lab Setup

### Prerequisites

Install required tools:

```bash
# Node.js and npm (required)
sudo apt update
sudo apt install -y nodejs npm

# Verify versions
node --version  # Should be v14+
npm --version

# Command-line HTTP tools
sudo apt install -y curl jq

# Optional: Modern HTTP clients
cargo install xh  # or
pip install httpie

# Optional: Bruno CLI for collections
npm install -g @usebruno/cli
```

### Lab Directory Structure

```bash
mkdir -p ~/api-lab
cd ~/api-lab

# Create subdirectories
mkdir -p loopback-api
mkdir -p mock-oauth2
mkdir -p scripts
mkdir -p collections
```

---

## Part 1: LoopBack API

### What is LoopBack?

LoopBack is a Node.js framework for building REST APIs quickly. It's perfect for:
- Creating mock APIs for testing
- Prototyping API designs
- Learning API concepts
- Simulating backend services for APIM

**Why LoopBack for infrastructure engineers?**
- CLI-driven (no GUI needed)
- Quick to set up (5 minutes)
- Built-in authentication (JWT, OAuth2)
- OpenAPI/Swagger documentation auto-generated
- Can run in Docker for isolation

### Install LoopBack 4 CLI

```bash
# Install LoopBack 4 CLI
npm install -g @loopback/cli

# Verify installation
lb4 --version
```

### Create Your First API

#### Step 1: Scaffold Application

```bash
cd ~/api-lab/loopback-api

# Create new LoopBack app
lb4 app
```

**Answer prompts**:
- **Project name**: `mock-server-api`
- **Description**: `Mock server management API`
- **Project root**: `mock-server-api`
- **Application class name**: `MockServerApiApplication`
- **Select features**: Enable all (Docker, prettier, eslint, etc.)

```bash
cd mock-server-api
```

#### Step 2: Create a Model (Data Structure)

Models define the structure of your data (like a database schema).

```bash
lb4 model
```

**Create a "Server" model**:
- **Model class name**: `Server`
- **Base class**: `Entity`
- **Allow additional properties**: `No`

**Add properties**:

| Property | Type | Required | Default |
|----------|------|----------|---------|
| id | number | Y | (auto-generated) |
| name | string | Y | |
| ipAddress | string | Y | |
| status | string | Y | running |
| region | string | N | us-east-1 |
| createdAt | date | N | |

#### Step 3: Create a DataSource

DataSource defines where data is stored (memory, MySQL, MongoDB, etc.).

```bash
lb4 datasource
```

**Configuration**:
- **Datasource name**: `db`
- **Connector**: `In-memory db`

This creates an in-memory database (data lost on restart - perfect for testing).

#### Step 4: Create a Repository

Repository connects model to datasource.

```bash
lb4 repository
```

**Configuration**:
- **Datasource**: `DbDatasource`
- **Model**: `Server`
- **Repository base class**: `DefaultCrudRepository`

#### Step 5: Create a Controller (API Endpoints)

Controller creates the REST API endpoints.

```bash
lb4 controller
```

**Configuration**:
- **Controller class name**: `ServerController`
- **Controller type**: `REST Controller with CRUD functions`
- **Model**: `Server`
- **Repository**: `ServerRepository`
- **REST API path**: `/servers`

#### Step 6: Run the API

```bash
# Start the server
npm start
```

**Output**:
```
Server is running at http://127.0.0.1:3000
Try http://127.0.0.1:3000/ping
```

Open another terminal and test:
```bash
# Ping endpoint
curl http://localhost:3000/ping

# Explore API (OpenAPI spec)
curl http://localhost:3000/openapi.json | jq

# Try the API Explorer (in browser)
# Open: http://localhost:3000/explorer
```

### Testing the Server API with curl

```bash
# Create a server
curl -X POST http://localhost:3000/servers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-server-01",
    "ipAddress": "10.0.1.5",
    "status": "running",
    "region": "us-east-1"
  }'

# Response:
# {
#   "id": 1,
#   "name": "web-server-01",
#   "ipAddress": "10.0.1.5",
#   "status": "running",
#   "region": "us-east-1"
# }

# Get all servers
curl http://localhost:3000/servers | jq

# Get specific server
curl http://localhost:3000/servers/1 | jq

# Update server
curl -X PATCH http://localhost:3000/servers/1 \
  -H "Content-Type: application/json" \
  -d '{"status": "stopped"}'

# Delete server
curl -X DELETE http://localhost:3000/servers/1
```

### Adding JWT Authentication to LoopBack

LoopBack supports JWT authentication out of the box.

#### Install Authentication Component

```bash
# In your loopback app directory
npm install @loopback/authentication @loopback/authentication-jwt
```

#### Configure JWT (Simplified Example)

Edit `src/application.ts` and add JWT authentication:

```typescript
import {AuthenticationComponent} from '@loopback/authentication';
import {
  JWTAuthenticationComponent,
  UserServiceBindings,
} from '@loopback/authentication-jwt';
import {DbDataSource} from './datasources';

export class MockServerApiApplication extends BootMixin(
  ServiceMixin(RepositoryMixin(RestApplication)),
) {
  constructor(options: ApplicationConfig = {}) {
    super(options);

    // Mount authentication system
    this.component(AuthenticationComponent);
    this.component(JWTAuthenticationComponent);

    // Bind datasource
    this.dataSource(DbDataSource, UserServiceBindings.DATASOURCE_NAME);

    // ... rest of your app
  }
}
```

#### Protect Endpoints

```typescript
import {authenticate} from '@loopback/authentication';

@authenticate('jwt')  // Require JWT for all methods
export class ServerController {
  // ... your controller code
}
```

#### Get JWT Token

```bash
# Login endpoint (auto-created by JWT component)
curl -X POST http://localhost:3000/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password"
  }'

# Response includes JWT token
# {
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
# }

# Use token to access protected endpoint
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/servers
```

**Note**: Full JWT setup is complex. See [LoopBack JWT Authentication Tutorial](https://loopback.io/doc/en/lb4/Authentication-tutorial.html) for complete guide.

---

## Part 2: Mock OAuth 2.0 Server

Azure APIM uses OAuth 2.0 for authentication. Let's create a mock OAuth 2.0 server to understand the flow.

### Option 1: node-oauth2-server (Simple)

```bash
cd ~/api-lab/mock-oauth2
npm init -y
npm install express oauth2-server body-parser
```

Create `oauth-server.js`:

```javascript
const express = require('express');
const OAuth2Server = require('oauth2-server');
const Request = OAuth2Server.Request;
const Response = OAuth2Server.Response;

const app = express();
app.use(express.json());
app.use(express.urlencoded({extended: true}));

// In-memory storage (for demo only!)
const clients = [
  {
    id: 'application',
    clientId: 'application',
    clientSecret: 'secret',
    grants: ['client_credentials', 'password'],
  },
];

const tokens = [];
const users = [
  {username: 'user1', password: 'password1'},
];

// OAuth2 model (required by oauth2-server)
const model = {
  getClient: async (clientId, clientSecret) => {
    const client = clients.find(
      c => c.clientId === clientId && c.clientSecret === clientSecret
    );
    return client ? {
      id: client.id,
      grants: client.grants,
    } : false;
  },

  saveToken: async (token, client, user) => {
    const savedToken = {
      accessToken: token.accessToken,
      accessTokenExpiresAt: token.accessTokenExpiresAt,
      client: client,
      user: user,
    };
    tokens.push(savedToken);
    return savedToken;
  },

  getAccessToken: async (accessToken) => {
    return tokens.find(t => t.accessToken === accessToken);
  },

  getUserFromClient: async (client) => {
    // For client_credentials flow
    return {id: 'service-account'};
  },

  getUser: async (username, password) => {
    const user = users.find(
      u => u.username === username && u.password === password
    );
    return user || false;
  },

  verifyScope: async (token, scope) => {
    return true;  // Simplified for demo
  },
};

// Create OAuth2 server instance
const oauth = new OAuth2Server({
  model: model,
  accessTokenLifetime: 3600,  // 1 hour
  allowEmptyState: true,
});

// Token endpoint
app.post('/oauth/token', async (req, res) => {
  const request = new Request(req);
  const response = new Response(res);

  try {
    const token = await oauth.token(request, response);
    res.json(token);
  } catch (err) {
    res.status(err.code || 500).json(err);
  }
});

// Protected resource example
app.get('/api/protected', async (req, res) => {
  const request = new Request(req);
  const response = new Response(res);

  try {
    const token = await oauth.authenticate(request, response);
    res.json({
      message: 'Success! You accessed a protected resource.',
      user: token.user,
    });
  } catch (err) {
    res.status(err.code || 500).json(err);
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({status: 'ok'});
});

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`OAuth2 server running on http://localhost:${PORT}`);
  console.log('Token endpoint: http://localhost:3001/oauth/token');
});
```

### Run Mock OAuth2 Server

```bash
node oauth-server.js
```

### Test OAuth2 Flow

```bash
# 1. Client Credentials Flow (machine-to-machine)
curl -X POST http://localhost:3001/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=application" \
  -d "client_secret=secret"

# Response:
# {
#   "accessToken": "4f5a...",
#   "accessTokenExpiresAt": "2025-11-08T01:00:00.000Z",
#   "tokenType": "Bearer"
# }

# 2. Save token to variable
TOKEN=$(curl -s -X POST http://localhost:3001/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=application" \
  -d "client_secret=secret" | jq -r '.accessToken')

echo "Token: $TOKEN"

# 3. Use token to access protected resource
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3001/api/protected

# Response:
# {
#   "message": "Success! You accessed a protected resource.",
#   "user": {"id": "service-account"}
# }

# 4. Test with invalid token (should fail)
curl -H "Authorization: Bearer invalid-token" \
  http://localhost:3001/api/protected
# Response: 401 Unauthorized
```

### Password Grant Flow (User Authentication)

```bash
# Password flow (user login)
curl -X POST http://localhost:3001/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "username=user1" \
  -d "password=password1" \
  -d "client_id=application" \
  -d "client_secret=secret"

# Response includes access token
```

---

## Part 3: Simulating APIM Scenarios

Now let's combine everything to simulate Azure APIM patterns.

### Scenario 1: APIM-like Gateway with Rate Limiting

Create `apim-simulator.js`:

```javascript
const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

// Subscription key storage (APIM uses these)
const subscriptionKeys = {
  'primary-key-12345': {
    name: 'Project 1 Subscription',
    rateLimit: 100,  // requests per minute
    quota: 10000,    // requests per month
  },
  'secondary-key-67890': {
    name: 'Project 2 Subscription',
    rateLimit: 10,
  },
};

// Rate limiting tracker (in-memory)
const rateLimitTracker = {};

// Middleware: Check subscription key
const checkSubscriptionKey = (req, res, next) => {
  const subKey = req.headers['ocp-apim-subscription-key'];

  if (!subKey || !subscriptionKeys[subKey]) {
    return res.status(401).json({
      error: 'Access denied',
      message: 'Invalid subscription key',
    });
  }

  req.subscription = subscriptionKeys[subKey];
  next();
};

// Middleware: Rate limiting
const rateLimit = (req, res, next) => {
  const subKey = req.headers['ocp-apim-subscription-key'];
  const now = Date.now();
  const minute = Math.floor(now / 60000);

  if (!rateLimitTracker[subKey]) {
    rateLimitTracker[subKey] = {};
  }

  if (!rateLimitTracker[subKey][minute]) {
    rateLimitTracker[subKey][minute] = 0;
  }

  rateLimitTracker[subKey][minute]++;

  const requests = rateLimitTracker[subKey][minute];
  const limit = req.subscription.rateLimit;

  res.setHeader('X-RateLimit-Limit', limit);
  res.setHeader('X-RateLimit-Remaining', Math.max(0, limit - requests));

  if (requests > limit) {
    return res.status(429).json({
      error: 'Rate limit exceeded',
      message: `Limit: ${limit} requests per minute`,
    });
  }

  next();
};

// APIM Gateway: Proxy to backend
app.all('/api/*', checkSubscriptionKey, rateLimit, async (req, res) => {
  // Extract path after /api/
  const backendPath = req.path.replace('/api/', '');

  // Backend URL (your LoopBack API)
  const backendUrl = `http://localhost:3000/${backendPath}`;

  console.log(`[APIM] Proxying ${req.method} ${req.path} -> ${backendUrl}`);

  try {
    const response = await axios({
      method: req.method,
      url: backendUrl,
      data: req.body,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(500).json({error: 'Backend error'});
    }
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({status: 'APIM simulator running'});
});

const PORT = 8080;
app.listen(PORT, () => {
  console.log(`APIM Simulator running on http://localhost:${PORT}`);
  console.log('Gateway: http://localhost:8080/api/*');
  console.log('Backend: http://localhost:3000/');
});
```

**Install dependencies**:
```bash
npm install axios
```

**Run the simulator**:
```bash
# Terminal 1: LoopBack backend (from earlier)
cd ~/api-lab/loopback-api/mock-server-api
npm start

# Terminal 2: APIM simulator
cd ~/api-lab/mock-oauth2
node apim-simulator.js
```

**Test the APIM simulator**:

```bash
# Without subscription key (should fail)
curl http://localhost:8080/api/servers
# Response: 401 Unauthorized

# With valid subscription key
curl -H "Ocp-Apim-Subscription-Key: primary-key-12345" \
  http://localhost:8080/api/servers

# Create server through APIM gateway
curl -X POST http://localhost:8080/api/servers \
  -H "Ocp-Apim-Subscription-Key: primary-key-12345" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-server-01",
    "ipAddress": "10.0.1.5",
    "status": "running"
  }'

# Test rate limiting (run this in a loop)
for i in {1..150}; do
  curl -s -H "Ocp-Apim-Subscription-Key: primary-key-12345" \
    http://localhost:8080/api/servers | jq -r '.error // "OK"'
done
# After 100 requests, you'll see: "Rate limit exceeded"

# Check rate limit headers
curl -i -H "Ocp-Apim-Subscription-Key: primary-key-12345" \
  http://localhost:8080/api/servers | grep "X-RateLimit"
```

### Scenario 2: OAuth2 + APIM Gateway

Combine OAuth2 authentication with APIM gateway:

```javascript
// Add to apim-simulator.js

// Middleware: Validate OAuth2 token
const validateOAuthToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({error: 'Missing or invalid authorization header'});
  }

  const token = authHeader.substring(7);

  try {
    // Validate token with OAuth server
    const response = await axios.get('http://localhost:3001/api/protected', {
      headers: {Authorization: `Bearer ${token}`},
    });

    req.user = response.data.user;
    next();
  } catch (error) {
    res.status(401).json({error: 'Invalid token'});
  }
};

// Protected API endpoint (OAuth + Subscription Key)
app.all('/api/protected/*',
  checkSubscriptionKey,
  validateOAuthToken,
  rateLimit,
  async (req, res) => {
    // Proxy to backend
  }
);
```

**Test OAuth2 + APIM**:

```bash
# Get OAuth token
TOKEN=$(curl -s -X POST http://localhost:3001/oauth/token \
  -d "grant_type=client_credentials" \
  -d "client_id=application" \
  -d "client_secret=secret" | jq -r '.accessToken')

# Access API with both subscription key AND OAuth token
curl -H "Ocp-Apim-Subscription-Key: primary-key-12345" \
     -H "Authorization: Bearer $TOKEN" \
     http://localhost:8080/api/protected/servers
```

---

## Part 4: Command-Line Testing

### Create Test Scripts

```bash
cd ~/api-lab/scripts
```

#### Script 1: Test Suite

Create `test-api.sh`:

```bash
#!/bin/bash
# test-api.sh - API test suite

BASE_URL="http://localhost:8080/api"
SUB_KEY="primary-key-12345"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

test_count=0
pass_count=0

run_test() {
    test_count=$((test_count + 1))
    echo -n "Test $test_count: $1 ... "

    if eval "$2" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        pass_count=$((pass_count + 1))
    else
        echo -e "${RED}FAIL${NC}"
    fi
}

echo "========================================="
echo "API Test Suite"
echo "========================================="

# Test 1: Health check
run_test "Health check" \
    "curl -sf http://localhost:8080/health"

# Test 2: Unauthorized access (no key)
run_test "Reject missing subscription key" \
    "curl -sf http://localhost:8080/api/servers && false || true"

# Test 3: Authorized access
run_test "Accept valid subscription key" \
    "curl -sf -H 'Ocp-Apim-Subscription-Key: $SUB_KEY' $BASE_URL/servers"

# Test 4: Create server
run_test "Create server" \
    "curl -sf -X POST -H 'Ocp-Apim-Subscription-Key: $SUB_KEY' \
     -H 'Content-Type: application/json' \
     -d '{\"name\":\"test-server\",\"ipAddress\":\"10.0.1.1\",\"status\":\"running\"}' \
     $BASE_URL/servers"

# Test 5: Get servers
run_test "List servers" \
    "curl -sf -H 'Ocp-Apim-Subscription-Key: $SUB_KEY' $BASE_URL/servers | jq -e '. | length > 0'"

echo "========================================="
echo "Results: $pass_count/$test_count tests passed"
echo "========================================="
```

Make executable and run:
```bash
chmod +x test-api.sh
./test-api.sh
```

#### Script 2: Load Test

Create `load-test.sh`:

```bash
#!/bin/bash
# load-test.sh - Simple load testing

BASE_URL="http://localhost:8080/api/servers"
SUB_KEY="primary-key-12345"
REQUESTS=200
DELAY=0.1  # seconds between requests

success=0
rate_limited=0
errors=0

echo "Running load test: $REQUESTS requests"
echo "========================================="

for i in $(seq 1 $REQUESTS); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Ocp-Apim-Subscription-Key: $SUB_KEY" \
        "$BASE_URL")

    case $HTTP_CODE in
        200)
            success=$((success + 1))
            echo -n "."
            ;;
        429)
            rate_limited=$((rate_limited + 1))
            echo -n "R"
            ;;
        *)
            errors=$((errors + 1))
            echo -n "E"
            ;;
    esac

    sleep $DELAY
done

echo ""
echo "========================================="
echo "Results:"
echo "  Success (200): $success"
echo "  Rate Limited (429): $rate_limited"
echo "  Errors: $errors"
echo "========================================="
```

Run load test:
```bash
chmod +x load-test.sh
./load-test.sh
```

---

## Part 5: Advanced Patterns

### Pattern 1: Mock Response (No Backend)

Useful for API design phase:

```javascript
// In apim-simulator.js
app.get('/api/mock/servers', (req, res) => {
  // Return mock data without calling backend
  res.json([
    {id: 1, name: 'server-1', status: 'running'},
    {id: 2, name: 'server-2', status: 'stopped'},
  ]);
});
```

### Pattern 2: Circuit Breaker

```javascript
// Simple circuit breaker
class CircuitBreaker {
  constructor(threshold = 5, timeout = 60000) {
    this.failureCount = 0;
    this.threshold = threshold;
    this.timeout = timeout;
    this.state = 'CLOSED';  // CLOSED, OPEN, HALF_OPEN
    this.nextAttempt = Date.now();
  }

  async call(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }

  onFailure() {
    this.failureCount++;
    if (this.failureCount >= this.threshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.timeout;
    }
  }
}

// Usage in APIM simulator
const breaker = new CircuitBreaker();

app.all('/api/*', async (req, res) => {
  try {
    const result = await breaker.call(async () => {
      // Call backend
      return await axios({...});
    });
    res.json(result.data);
  } catch (error) {
    if (error.message === 'Circuit breaker is OPEN') {
      res.status(503).json({error: 'Service temporarily unavailable'});
    }
  }
});
```

### Pattern 3: Request/Response Transformation

```javascript
// Transform request before sending to backend
app.all('/api/v2/*', async (req, res) => {
  // Add timestamp to all requests
  const modifiedBody = {
    ...req.body,
    requestedAt: new Date().toISOString(),
  };

  const response = await axios({
    method: req.method,
    url: backendUrl,
    data: modifiedBody,
  });

  // Transform response
  const transformedResponse = {
    data: response.data,
    metadata: {
      version: 'v2',
      timestamp: new Date().toISOString(),
    },
  };

  res.json(transformedResponse);
});
```

---

## Bonus: Alternative Mock Tools

### 1. JSON Server (Quickest Option)

Super simple mock API from JSON file:

```bash
# Install
npm install -g json-server

# Create db.json
cat > db.json << 'EOF'
{
  "servers": [
    {"id": 1, "name": "web-01", "status": "running"},
    {"id": 2, "name": "db-01", "status": "running"}
  ],
  "users": [
    {"id": 1, "name": "admin", "role": "admin"}
  ]
}
EOF

# Run server
json-server --watch db.json --port 3000

# Auto-generates full REST API:
# GET    /servers
# GET    /servers/1
# POST   /servers
# PUT    /servers/1
# PATCH  /servers/1
# DELETE /servers/1
```

### 2. Mockoon (GUI + CLI)

Mockoon has both GUI and CLI:

```bash
# Install CLI
npm install -g @mockoon/cli

# Run mock from file
mockoon-cli start --data ./mockoon-data.json
```

### 3. Prism (OpenAPI Mock Server)

Mock API from OpenAPI specification:

```bash
# Install
npm install -g @stoplight/prism-cli

# Mock from OpenAPI file
prism mock openapi.yaml

# Example openapi.yaml
cat > openapi.yaml << 'EOF'
openapi: 3.0.0
info:
  title: Server API
  version: 1.0.0
paths:
  /servers:
    get:
      responses:
        '200':
          description: List of servers
          content:
            application/json:
              schema:
                type: array
                items:
                  type: object
                  properties:
                    id:
                      type: integer
                    name:
                      type: string
EOF

prism mock openapi.yaml
```

### 4. WireMock (Java-based, powerful)

```bash
# Download WireMock
wget https://repo1.maven.org/maven2/com/github/tomakehurst/wiremock-standalone/2.35.0/wiremock-standalone-2.35.0.jar

# Run
java -jar wiremock-standalone-2.35.0.jar --port 8080

# Create stub
curl -X POST http://localhost:8080/__admin/mappings \
  -d '{
    "request": {
      "method": "GET",
      "url": "/api/servers"
    },
    "response": {
      "status": 200,
      "body": "[{\"id\":1,\"name\":\"server-1\"}]",
      "headers": {
        "Content-Type": "application/json"
      }
    }
  }'

# Test
curl http://localhost:8080/api/servers
```

---

## Complete Lab Exercises

### Exercise 1: Build and Secure API

1. Create LoopBack API with Server model
2. Add JWT authentication
3. Test with curl
4. Document findings

### Exercise 2: Simulate APIM

1. Run APIM simulator with rate limiting
2. Test subscription key validation
3. Trigger rate limit
4. Add custom policies (headers, transformations)

### Exercise 3: OAuth2 Flow

1. Run mock OAuth2 server
2. Get access token using client credentials
3. Use token to access protected API
4. Combine with APIM simulator

### Exercise 4: End-to-End Scenario

Simulate this architecture:
```
Client
  ↓ (subscription key + OAuth token)
APIM Simulator (rate limiting, policies)
  ↓
LoopBack Backend (JWT validation)
  ↓
In-memory database
```

Test:
- Authentication failures
- Rate limiting
- CRUD operations
- Error handling

---

## Resources and References

### LoopBack
- [LoopBack 4 Documentation](https://loopback.io/doc/en/lb4/)
- [LoopBack CLI Reference](https://loopback.io/doc/en/lb4/Command-line-interface.html)
- [Authentication Tutorial](https://loopback.io/doc/en/lb4/Authentication-tutorial.html)

### OAuth 2.0
- [OAuth 2.0 Simplified](https://aaronparecki.com/oauth-2-simplified/)
- [OAuth 2.0 Playground](https://www.oauth.com/playground/)
- [node-oauth2-server](https://oauth2-server.readthedocs.io/)

### Mock Tools
- [JSON Server](https://github.com/typicode/json-server)
- [Mockoon](https://mockoon.com/)
- [Prism](https://stoplight.io/open-source/prism)
- [WireMock](http://wiremock.org/)

### Testing Tools
- [curl Documentation](https://curl.se/docs/)
- [Bruno](https://www.usebruno.com/)
- [HTTPie](https://httpie.io/)

---

## Next Steps

1. **Complete the lab exercises** - Hands-on practice
2. **Experiment with patterns** - Circuit breaker, caching, transformation
3. **Apply to APIM** - Deploy real APIM and compare behavior
4. **Build realistic mocks** - Create mocks for your actual use cases

## Related Research Projects

- [API Fundamentals for Infrastructure](../api-fundamentals-for-infrastructure/) - Command-line API basics
- [APIM Policy Security](../apim-policy-security/) - Real APIM security patterns
- [APIM Backend Integration](../apim-backend-integration/) - Connect APIM to backends

## Status

**Status**: 🟢 Ready for Use
**Last Updated**: 2025-11-07
**Difficulty**: Intermediate
**Estimated Time**: 3-4 hours
**Prerequisites**: Node.js, basic command-line skills
