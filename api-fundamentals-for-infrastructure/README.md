# API Fundamentals for Infrastructure Engineers

A comprehensive guide for infrastructure engineers transitioning into the API-driven world. This guide focuses on command-line tools, practical examples, and concepts relevant to managing API infrastructure.

## Overview

APIs (Application Programming Interfaces) have become the foundation of modern infrastructure. As an infrastructure engineer, you need to understand APIs to:
- Manage cloud resources (Azure CLI, AWS CLI, kubectl)
- Monitor and debug applications
- Integrate services and automate workflows
- Secure API gateways and endpoints
- Troubleshoot API-driven architectures

This guide bridges traditional infrastructure knowledge with modern API concepts, using tools you're already comfortable with.

## What This Guide Covers

- [ ] REST API fundamentals from an infrastructure perspective
- [ ] Command-line API testing tools (curl, xh, httpie, bruno-cli)
- [ ] HTTP methods, status codes, and headers
- [ ] Authentication methods (API keys, Basic Auth, Bearer tokens, JWT, OAuth2)
- [ ] API request/response formats (JSON, XML)
- [ ] Debugging APIs with command-line tools
- [ ] Scripting API interactions with bash
- [ ] Common API patterns in infrastructure (pagination, rate limiting, webhooks)
- [ ] API security from an infrastructure viewpoint

## Prerequisites

Basic Linux/Unix command-line knowledge. That's it!

## Table of Contents

1. [API Basics: What Infrastructure Engineers Need to Know](#api-basics)
2. [Command-Line Tools for API Testing](#command-line-tools)
3. [HTTP Methods and Status Codes](#http-methods-and-status-codes)
4. [Working with JSON](#working-with-json)
5. [API Authentication Methods](#api-authentication)
6. [Practical Examples with Public APIs](#practical-examples)
7. [Bash Scripting for API Automation](#bash-scripting)
8. [Debugging and Troubleshooting APIs](#debugging)
9. [API Infrastructure Patterns](#infrastructure-patterns)

---

## API Basics

### What is an API?

In infrastructure terms, an API is like SSH or RDP, but for applications to talk to each other over HTTP/HTTPS.

Traditional infrastructure:
```bash
# Direct server access
ssh user@server.com
mysql -h database.server.com -u user -p
```

Modern API-driven infrastructure:
```bash
# API access
curl https://api.server.com/users
az vm list --output json
kubectl get pods --output=json
```

### REST API Fundamentals

**REST** = Representational State Transfer (don't worry about the name, focus on the pattern)

Key concepts:
- **Resources**: Things you want to work with (users, servers, databases)
- **Endpoints**: URLs that represent resources
- **Methods**: Actions you take (GET, POST, PUT, DELETE)
- **Representations**: Data format (usually JSON)

Think of it like file system operations:
```bash
# File system
ls /var/www/html                    # List files
cat /var/www/html/index.html        # Read file
echo "content" > /var/www/new.html  # Create file
rm /var/www/old.html                # Delete file

# REST API (conceptually similar)
GET    /api/files                   # List resources
GET    /api/files/index.html        # Read resource
POST   /api/files                   # Create resource
DELETE /api/files/old.html          # Delete resource
```

### API Endpoints and Resources

Example REST API structure:
```
https://api.example.com/v1/servers          # Collection of servers
https://api.example.com/v1/servers/123      # Specific server (ID: 123)
https://api.example.com/v1/servers/123/logs # Server's logs (nested resource)
```

This is like a file path: `/v1/servers/123/logs`

---

## Command-Line Tools

### curl (The Standard)

**curl** is the Swiss Army knife of HTTP requests. It's installed on virtually every Linux system.

Basic syntax:
```bash
curl [options] <URL>
```

Common options for API work:
```bash
-X, --request METHOD     # HTTP method (GET, POST, PUT, DELETE)
-H, --header "Header"    # Add custom header
-d, --data "data"        # Send data (POST/PUT body)
-i, --include            # Include response headers
-v, --verbose            # Verbose output (debugging)
-s, --silent             # Silent mode (no progress)
-o, --output file        # Save to file
```

### xh (Modern Alternative to curl)

**xh** is a modern, user-friendly HTTP client written in Rust. Better syntax than curl.

Install:
```bash
# Debian/Ubuntu
sudo apt install xh

# Or using cargo
cargo install xh
```

Why infrastructure engineers like xh:
- Syntax highlighting (easier to read)
- Automatic JSON formatting
- Simpler syntax than curl
- Still scriptable

### httpie (Python-based Alternative)

**HTTPie** is another user-friendly HTTP client.

Install:
```bash
pip install httpie
```

### bruno-cli (API Testing Tool)

**Bruno** is an offline API testing tool with a CLI.

Install:
```bash
npm install -g @usebruno/cli
```

Good for:
- Saving API collections
- Team collaboration (Git-friendly)
- Scripting tests

### Tool Comparison

| Feature | curl | xh | httpie | bruno-cli |
|---------|------|-----|--------|-----------|
| Installed by default | ✅ | ❌ | ❌ | ❌ |
| Syntax simplicity | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| JSON formatting | ❌ | ✅ | ✅ | ✅ |
| Scripting | ✅ | ✅ | ✅ | ✅ |
| Speed | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Collections | ❌ | ❌ | ❌ | ✅ |

**Recommendation**: Learn curl first (it's everywhere), then try xh for daily use.

---

## HTTP Methods and Status Codes

### HTTP Methods (Verbs)

Think of these like Linux commands:

| HTTP Method | Linux Equivalent | Purpose | Safe? | Idempotent? |
|-------------|------------------|---------|-------|-------------|
| GET | `cat`, `ls` | Read/retrieve data | ✅ | ✅ |
| POST | `echo >> file` | Create new resource | ❌ | ❌ |
| PUT | `echo > file` | Update/replace resource | ❌ | ✅ |
| PATCH | `sed -i` | Partial update | ❌ | ❌ |
| DELETE | `rm` | Delete resource | ❌ | ✅ |
| HEAD | `ls -l` | Get metadata only | ✅ | ✅ |
| OPTIONS | `man` | Get available methods | ✅ | ✅ |

**Safe**: Doesn't modify data (read-only)
**Idempotent**: Same request multiple times = same result

### HTTP Status Codes

Like exit codes (`$?`), but for HTTP:

**2xx - Success** (like exit code 0)
- 200 OK - Request succeeded
- 201 Created - Resource created successfully
- 204 No Content - Success, but no data to return

**3xx - Redirection**
- 301 Moved Permanently - Resource moved
- 302 Found - Temporary redirect
- 304 Not Modified - Cached version is still valid

**4xx - Client Error** (like "command not found")
- 400 Bad Request - Invalid request syntax
- 401 Unauthorized - Authentication required
- 403 Forbidden - Authenticated but not authorized
- 404 Not Found - Resource doesn't exist
- 429 Too Many Requests - Rate limit exceeded

**5xx - Server Error** (like "segmentation fault")
- 500 Internal Server Error - Server crashed
- 502 Bad Gateway - Upstream server error
- 503 Service Unavailable - Server overloaded/down
- 504 Gateway Timeout - Upstream server timeout

**Infrastructure analogy**:
```bash
# Command line
$ ls /nonexistent
ls: cannot access '/nonexistent': No such file or directory  # Like 404

$ cat /root/secret.txt
cat: /root/secret.txt: Permission denied  # Like 403

# API
$ curl https://api.example.com/nonexistent
HTTP/1.1 404 Not Found

$ curl https://api.example.com/admin/users
HTTP/1.1 403 Forbidden
```

---

## Working with JSON

### JSON Basics

JSON is like a structured text file. As an infrastructure engineer, think of it as:
- Similar to configuration files (like YAML, but different syntax)
- Structured data format for APIs
- Easy to parse with command-line tools

JSON structure:
```json
{
  "server": {
    "id": 123,
    "name": "web-server-01",
    "ip": "10.0.1.5",
    "status": "running",
    "tags": ["production", "web"],
    "ports": [80, 443]
  }
}
```

Compare to traditional config files:
```ini
# INI format (old style)
[server]
id=123
name=web-server-01
ip=10.0.1.5
```

### Command-Line JSON Tools

#### jq (JSON processor)

**jq** is like `grep`, `sed`, and `awk` for JSON.

Install:
```bash
sudo apt install jq  # Debian/Ubuntu
sudo yum install jq  # RHEL/CentOS
```

Basic usage:
```bash
# Pretty-print JSON
curl -s https://api.github.com/users/torvalds | jq

# Extract specific field
curl -s https://api.github.com/users/torvalds | jq '.name'
# Output: "Linus Torvalds"

# Extract from array
curl -s https://api.github.com/users/torvalds/repos | jq '.[0].name'

# Filter array
curl -s https://api.github.com/users/torvalds/repos | jq '.[] | select(.fork == false) | .name'

# Multiple fields
curl -s https://api.github.com/users/torvalds | jq '{name: .name, location: .location}'
```

**Common jq patterns for infrastructure**:
```bash
# List all VM names from Azure
az vm list | jq '.[].name'

# Get running VMs only
az vm list | jq '.[] | select(.powerState == "VM running") | .name'

# Extract IP addresses
kubectl get pods -o json | jq '.items[].status.podIP'

# Count resources
az vm list | jq '. | length'
```

#### jq Cheat Sheet for Infrastructure

```bash
# Get all values of a field
jq '.[].fieldName'

# Filter by condition
jq '.[] | select(.status == "running")'

# Get nested field
jq '.server.network.ip'

# Array of specific fields
jq '[.[] | {name: .name, ip: .ip}]'

# Count items
jq '. | length'

# Get first item
jq '.[0]'

# Get keys
jq 'keys'
```

---

## API Authentication

### 1. No Authentication (Public APIs)

Some APIs are completely public:
```bash
# No authentication needed
curl https://api.github.com/repos/torvalds/linux
```

### 2. API Key (Simplest)

Like a password in the URL or header:

**Query parameter** (less secure):
```bash
curl "https://api.example.com/data?api_key=YOUR_API_KEY"
```

**Header** (better):
```bash
curl -H "X-API-Key: YOUR_API_KEY" https://api.example.com/data
```

**Infrastructure example** (Azure APIM):
```bash
curl -H "Ocp-Apim-Subscription-Key: YOUR_KEY" \
  https://apim-dev.azure-api.net/api/data
```

### 3. Basic Authentication

Username + password encoded in Base64 (like HTTP basic auth):

```bash
# Method 1: curl handles encoding
curl -u username:password https://api.example.com/data

# Method 2: Manual base64 encoding
echo -n "username:password" | base64
# Output: dXNlcm5hbWU6cGFzc3dvcmQ=

curl -H "Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=" \
  https://api.example.com/data
```

**⚠️ Warning**: Basic auth sends credentials with every request. Use HTTPS!

### 4. Bearer Token

A token (like an API key) sent in the Authorization header:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  https://api.example.com/data
```

This is very common in modern APIs.

### 5. JWT (JSON Web Token)

A self-contained token with encoded data (like a secure cookie).

JWT structure: `header.payload.signature`

Example JWT:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

Decode JWT (for debugging):
```bash
# Extract payload (middle part)
echo "eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ" | base64 -d
# Output: {"sub":"1234567890","name":"John Doe","iat":1516239022}
```

Using JWT:
```bash
TOKEN="eyJhbGciOiJIUzI1..."
curl -H "Authorization: Bearer $TOKEN" https://api.example.com/data
```

**Infrastructure perspective**: JWT is like a signed certificate - it contains claims about the user and can't be tampered with.

### 6. OAuth 2.0 (Complex but Common)

OAuth 2.0 is like SSH key authentication, but for APIs.

**OAuth 2.0 flow** (simplified):
1. Get authorization code (user logs in)
2. Exchange code for access token
3. Use access token to call APIs

**Common OAuth 2.0 Grant Types**:

#### Client Credentials Flow (Machine-to-Machine)

This is most relevant for infrastructure automation:

```bash
# Step 1: Get token
curl -X POST https://login.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "scope=api.read"

# Response:
# {
#   "access_token": "eyJhbGci...",
#   "token_type": "Bearer",
#   "expires_in": 3600
# }

# Step 2: Use token
ACCESS_TOKEN="eyJhbGci..."
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  https://api.example.com/data
```

**Bash script for OAuth 2.0**:
```bash
#!/bin/bash

CLIENT_ID="your_client_id"
CLIENT_SECRET="your_client_secret"
TOKEN_URL="https://login.example.com/oauth/token"
API_URL="https://api.example.com/data"

# Get access token
TOKEN_RESPONSE=$(curl -s -X POST "$TOKEN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

# Use token to call API
curl -H "Authorization: Bearer $ACCESS_TOKEN" "$API_URL"
```

### Authentication Comparison Table

| Method | Security | Complexity | Infrastructure Use Case |
|--------|----------|------------|------------------------|
| None | ❌ Low | ⭐ Simple | Public data |
| API Key | ⚠️ Medium | ⭐⭐ Simple | Internal tools, dev/test |
| Basic Auth | ⚠️ Medium | ⭐⭐ Simple | Simple APIs, legacy systems |
| Bearer Token | ✅ High | ⭐⭐⭐ Medium | Modern APIs |
| JWT | ✅ High | ⭐⭐⭐⭐ Medium | Stateless auth, microservices |
| OAuth 2.0 | ✅ High | ⭐⭐⭐⭐⭐ Complex | Enterprise APIs, Azure/AWS |

---

## Practical Examples with Public APIs

Let's practice with real APIs that don't require authentication.

### Example 1: GitHub API (No Auth)

```bash
# Get user info
curl -s https://api.github.com/users/torvalds | jq

# Pretty output
curl -s https://api.github.com/users/torvalds | jq '{
  name: .name,
  company: .company,
  location: .location,
  repos: .public_repos
}'

# List repositories
curl -s https://api.github.com/users/torvalds/repos | jq '.[].name'

# Get repository details
curl -s https://api.github.com/repos/torvalds/linux | jq '{
  name: .name,
  stars: .stargazers_count,
  forks: .forks_count,
  language: .language
}'
```

### Example 2: httpbin.org (API Testing Service)

httpbin.org is like `/dev/null` but for APIs - perfect for testing.

```bash
# GET request
curl https://httpbin.org/get

# POST request with JSON
curl -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d '{"server":"web-01","status":"running"}'

# Headers inspection
curl https://httpbin.org/headers

# Simulate authentication
curl -u user:pass https://httpbin.org/basic-auth/user/pass

# Test different status codes
curl https://httpbin.org/status/404
curl https://httpbin.org/status/500

# Delay response (timeout testing)
curl https://httpbin.org/delay/3

# IP address
curl https://httpbin.org/ip
```

### Example 3: JSONPlaceholder (Fake REST API)

```bash
# List all users
curl -s https://jsonplaceholder.typicode.com/users | jq

# Get specific user
curl -s https://jsonplaceholder.typicode.com/users/1 | jq

# Create new post (simulated)
curl -X POST https://jsonplaceholder.typicode.com/posts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Post",
    "body": "This is the content",
    "userId": 1
  }' | jq

# Update post (PUT)
curl -X PUT https://jsonplaceholder.typicode.com/posts/1 \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "title": "Updated Title",
    "body": "Updated content",
    "userId": 1
  }' | jq

# Delete post
curl -X DELETE https://jsonplaceholder.typicode.com/posts/1
```

---

## Bash Scripting for API Automation

### Script 1: Health Check Monitor

```bash
#!/bin/bash
# api-health-check.sh - Monitor API health

API_URL="https://api.example.com/health"
TIMEOUT=5
LOG_FILE="/var/log/api-health.log"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Make request and capture status code
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                     --max-time $TIMEOUT "$API_URL")

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "[$TIMESTAMP] OK - API is healthy (HTTP $HTTP_CODE)" | tee -a "$LOG_FILE"
    else
        echo "[$TIMESTAMP] FAIL - API returned HTTP $HTTP_CODE" | tee -a "$LOG_FILE"
        # Send alert (example: email, Slack, PagerDuty)
        # send-alert.sh "API Health Check Failed: HTTP $HTTP_CODE"
    fi

    sleep 60
done
```

### Script 2: Batch API Calls

```bash
#!/bin/bash
# batch-api-call.sh - Process multiple items via API

API_URL="https://api.example.com/servers"
API_KEY="your-api-key"

# Read server IDs from file
while IFS= read -r server_id; do
    echo "Processing server: $server_id"

    # Get server status
    RESPONSE=$(curl -s -H "X-API-Key: $API_KEY" \
                    "$API_URL/$server_id")

    STATUS=$(echo "$RESPONSE" | jq -r '.status')
    echo "  Status: $STATUS"

    # Take action based on status
    if [ "$STATUS" == "stopped" ]; then
        echo "  Starting server $server_id..."
        curl -X POST -H "X-API-Key: $API_KEY" \
             "$API_URL/$server_id/start"
    fi

    sleep 1  # Rate limiting
done < server-list.txt
```

### Script 3: OAuth Token Manager

```bash
#!/bin/bash
# oauth-token.sh - Manage OAuth 2.0 tokens with caching

TOKEN_CACHE="/tmp/oauth-token.cache"
TOKEN_URL="https://login.example.com/oauth/token"
CLIENT_ID="your_client_id"
CLIENT_SECRET="your_client_secret"

get_token() {
    # Check if cached token exists and is valid
    if [ -f "$TOKEN_CACHE" ]; then
        CACHED_TOKEN=$(cat "$TOKEN_CACHE")
        EXPIRES=$(echo "$CACHED_TOKEN" | jq -r '.expires_at')
        NOW=$(date +%s)

        if [ "$NOW" -lt "$EXPIRES" ]; then
            echo "$CACHED_TOKEN" | jq -r '.access_token'
            return
        fi
    fi

    # Get new token
    RESPONSE=$(curl -s -X POST "$TOKEN_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=client_credentials" \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET")

    ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
    EXPIRES_IN=$(echo "$RESPONSE" | jq -r '.expires_in')
    EXPIRES_AT=$(($(date +%s) + $EXPIRES_IN - 60))  # 60s buffer

    # Cache token
    echo "{\"access_token\":\"$ACCESS_TOKEN\",\"expires_at\":$EXPIRES_AT}" > "$TOKEN_CACHE"

    echo "$ACCESS_TOKEN"
}

# Usage
TOKEN=$(get_token)
curl -H "Authorization: Bearer $TOKEN" https://api.example.com/data
```

### Script 4: API Pagination Handler

```bash
#!/bin/bash
# api-paginate.sh - Handle paginated API responses

API_URL="https://api.example.com/servers"
API_KEY="your-api-key"
PAGE=1
PER_PAGE=100

ALL_RESULTS="[]"

while true; do
    echo "Fetching page $PAGE..."

    RESPONSE=$(curl -s -H "X-API-Key: $API_KEY" \
                    "$API_URL?page=$PAGE&per_page=$PER_PAGE")

    # Extract items from response
    ITEMS=$(echo "$RESPONSE" | jq '.items')
    COUNT=$(echo "$ITEMS" | jq '. | length')

    if [ "$COUNT" -eq 0 ]; then
        break
    fi

    # Merge results
    ALL_RESULTS=$(echo "$ALL_RESULTS" "$ITEMS" | jq -s 'add')

    PAGE=$((PAGE + 1))
    sleep 0.5  # Rate limiting
done

echo "$ALL_RESULTS" | jq
echo "Total items: $(echo "$ALL_RESULTS" | jq '. | length')"
```

---

## Debugging and Troubleshooting APIs

### Verbose curl Output

```bash
# See full request/response headers
curl -v https://api.example.com/data

# Even more verbose (includes SSL handshake)
curl -vv https://api.example.com/data

# Trace request (very detailed)
curl --trace - https://api.example.com/data

# Save trace to file
curl --trace-ascii trace.log https://api.example.com/data
```

### Checking Response Headers

```bash
# Include headers in output
curl -i https://api.example.com/data

# Headers only (no body)
curl -I https://api.example.com/data

# Specific header
curl -s -D - https://api.example.com/data | grep -i "content-type"
```

### Common Issues and Solutions

#### Issue 1: SSL Certificate Errors

```bash
# Error: SSL certificate problem
# Solution: Skip verification (DEV ONLY!)
curl -k https://api.example.com/data

# Better: Add CA certificate
curl --cacert /path/to/ca-cert.pem https://api.example.com/data
```

#### Issue 2: Timeout

```bash
# Set timeout
curl --max-time 10 https://api.example.com/data

# Connection timeout (separate from max-time)
curl --connect-timeout 5 --max-time 30 https://api.example.com/data
```

#### Issue 3: Following Redirects

```bash
# Follow redirects automatically
curl -L https://api.example.com/data
```

#### Issue 4: Authentication Failures

```bash
# Debug authentication
curl -v -H "Authorization: Bearer $TOKEN" https://api.example.com/data

# Check if token is valid (decode JWT)
echo "$TOKEN" | cut -d. -f2 | base64 -d | jq
```

### Testing with Different Tools

```bash
# curl
curl -X POST https://api.example.com/data -d '{"key":"value"}'

# xh (simpler syntax)
xh POST https://api.example.com/data key=value

# httpie (even simpler)
http POST https://api.example.com/data key=value

# wget (alternative to curl)
wget --method=POST --body-data='{"key":"value"}' https://api.example.com/data
```

---

## API Infrastructure Patterns

### Pattern 1: Rate Limiting

APIs often limit requests per time period:

```bash
# HTTP 429 Too Many Requests
# Response headers:
# X-RateLimit-Limit: 100
# X-RateLimit-Remaining: 0
# X-RateLimit-Reset: 1637000000

# Handle rate limiting in script
handle_rate_limit() {
    RESPONSE=$(curl -s -D - "$API_URL")
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP" | awk '{print $2}')

    if [ "$HTTP_CODE" -eq 429 ]; then
        RETRY_AFTER=$(echo "$RESPONSE" | grep -i "retry-after" | awk '{print $2}')
        echo "Rate limited. Waiting $RETRY_AFTER seconds..."
        sleep "$RETRY_AFTER"
        # Retry request
    fi
}
```

### Pattern 2: Pagination

Iterate through large result sets:

```bash
# Link header pagination (GitHub-style)
# Link: <https://api.example.com/data?page=2>; rel="next"

# Extract next page from Link header
NEXT_PAGE=$(curl -s -I "$API_URL" | grep -i "link" | grep -o 'page=[0-9]*' | cut -d= -f2)
```

### Pattern 3: Webhooks

Receive API callbacks (like reverse SSH):

```bash
# Simple webhook receiver
#!/bin/bash
# webhook-receiver.sh

# Listen on port 8080
while true; do
    echo -ne "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p 8080 -q 1 > webhook-data.txt

    # Process webhook data
    cat webhook-data.txt | grep -A 999 "^$" | jq
done
```

### Pattern 4: API Versioning

```bash
# Version in URL path
curl https://api.example.com/v1/servers
curl https://api.example.com/v2/servers

# Version in header
curl -H "Accept: application/vnd.example.v1+json" https://api.example.com/servers

# Version in query parameter
curl "https://api.example.com/servers?version=1"
```

### Pattern 5: Health Checks

```bash
# Standard health endpoint
curl https://api.example.com/health

# Kubernetes-style liveness/readiness
curl https://api.example.com/healthz
curl https://api.example.com/readyz

# Detailed health (infrastructure status)
curl https://api.example.com/health | jq '{
  status: .status,
  database: .checks.database.status,
  cache: .checks.redis.status,
  uptime: .uptime
}'
```

---

## Exercises for Infrastructure Engineers

### Exercise 1: Monitor GitHub API Rate Limit

```bash
# Check your current rate limit
curl -s https://api.github.com/rate_limit | jq '{
  limit: .rate.limit,
  remaining: .rate.remaining,
  reset: (.rate.reset | strftime("%Y-%m-%d %H:%M:%S"))
}'
```

### Exercise 2: Build a Server Status Dashboard

Create a script that:
1. Calls multiple APIs to get server status
2. Aggregates results
3. Outputs a summary dashboard

```bash
#!/bin/bash
# dashboard.sh

echo "=== Server Status Dashboard ==="
echo "Generated: $(date)"
echo ""

# Example: Check multiple services
for service in api database cache; do
    STATUS=$(curl -s "https://api.example.com/health/$service" | jq -r '.status')
    printf "%-10s: %s\n" "$service" "$STATUS"
done
```

### Exercise 3: Automate Cloud Resource Management

```bash
# List all VMs and their status (Azure example)
az vm list --output json | jq -r '.[] | "\(.name): \(.powerState)"'

# Start all stopped VMs
az vm list --output json | \
    jq -r '.[] | select(.powerState == "VM deallocated") | .name' | \
    while read vm; do
        echo "Starting $vm..."
        az vm start --name "$vm" --resource-group "your-rg"
    done
```

---

## Resources and References

### Documentation
- [curl Documentation](https://curl.se/docs/)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [HTTP Status Codes](https://httpstatuses.com/)
- [REST API Tutorial](https://restfulapi.net/)

### Public APIs for Practice
- [httpbin.org](https://httpbin.org) - HTTP testing service
- [JSONPlaceholder](https://jsonplaceholder.typicode.com) - Fake REST API
- [GitHub API](https://docs.github.com/en/rest) - No auth required for public data
- [ReqRes](https://reqres.in) - Hosted REST API for testing

### Tools
- [curl](https://curl.se/) - Command-line HTTP client
- [xh](https://github.com/ducaale/xh) - Modern HTTP client
- [HTTPie](https://httpie.io/) - User-friendly HTTP client
- [jq](https://stedolan.github.io/jq/) - JSON processor
- [Bruno](https://www.usebruno.com/) - API testing tool

### Infrastructure-Specific Guides
- [Azure REST API Reference](https://docs.microsoft.com/rest/api/azure/)
- [AWS API Reference](https://docs.aws.amazon.com/api-gateway/)
- [Kubernetes API](https://kubernetes.io/docs/reference/kubernetes-api/)

---

## Next Steps

1. **Practice with public APIs** - Use httpbin.org and GitHub API
2. **Install tools** - curl, jq, xh
3. **Write bash scripts** - Automate API interactions
4. **Move to Mock API Lab** - Build your own test APIs
5. **Apply to APIM** - Use knowledge for Azure API Management

## Related Research Projects

- [Mock API Lab](../mock-api-lab/) - Hands-on lab with LoopBack, OAuth2 mock, and APIM simulation
- [APIM Policy Security](../apim-policy-security/) - Apply API knowledge to APIM policies
- [APIM Backend Integration](../apim-backend-integration/) - Connect APIM to APIs you build

## Status

**Status**: 🟢 Ready for Use
**Last Updated**: 2025-11-07
**Difficulty**: Beginner to Intermediate
**Estimated Time**: 4-6 hours to work through
