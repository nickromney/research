# APIM Simulator

Simulates Azure API Management gateway functionality including subscription keys, rate limiting, and quota management.

## Features

- Subscription key validation (like Azure APIM's `Ocp-Apim-Subscription-Key`)
- Rate limiting per subscription
- Quota tracking
- Request proxying to backend services
- APIM-style error responses
- Statistics endpoint

## Usage

```bash
# Install dependencies
npm install

# Start server
npm start
```

Server runs on `http://localhost:8080`

## Subscription Keys

| Key | Name | Product | Rate Limit | Quota |
|-----|------|---------|------------|-------|
| `primary-key-12345` | Project 1 | project-1-apis | 100/min | 10,000/month |
| `secondary-key-67890` | Project 2 | project-2-apis | 10/min | 1,000/month |
| `admin-key-99999` | Admin | admin-apis | 1000/min | 100,000/month |

## Endpoints

### API Gateway
All requests to `/api/*` are proxied to httpbin.org (by default)

```bash
# Without subscription key (fails)
curl http://localhost:8080/api/get

# With valid subscription key
curl -H 'Ocp-Apim-Subscription-Key: primary-key-12345' \
  http://localhost:8080/api/get

# POST request
curl -X POST \
  -H 'Ocp-Apim-Subscription-Key: primary-key-12345' \
  -H 'Content-Type: application/json' \
  -d '{"test":"data"}' \
  http://localhost:8080/api/post
```

### Stats
```bash
curl http://localhost:8080/stats
```

### Reset Stats
```bash
curl -X POST http://localhost:8080/reset-stats
```

### Health Check
```bash
curl http://localhost:8080/health
```

## Response Headers

The simulator adds APIM-like headers:

- `X-RateLimit-Limit`: Rate limit for this subscription
- `X-RateLimit-Remaining`: Remaining requests in current window
- `X-RateLimit-Reset`: Time when rate limit resets
- `X-Quota-Limit`: Monthly quota limit
- `X-Quota-Remaining`: Remaining quota
- `X-APIM-Gateway`: Identifies as simulator
- `X-APIM-Product`: Product name

## Testing Rate Limiting

Use the secondary key (10 req/min limit) to test:

```bash
# Send 15 requests rapidly
for i in {1..15}; do
  curl -s -H 'Ocp-Apim-Subscription-Key: secondary-key-67890' \
    http://localhost:8080/api/get | jq -r '.url // .message'
  sleep 0.5
done
```

After 10 requests, you'll see rate limit errors (HTTP 429).

## Custom Backend

By default, requests proxy to httpbin.org. You can specify a different backend:

```bash
# Proxy to local backend
curl -H 'Ocp-Apim-Subscription-Key: primary-key-12345' \
  'http://localhost:8080/api/servers?backend=http://localhost:3000/servers'
```

## Implementation

Built with:
- Express.js for HTTP server
- Axios for proxying to backends
- In-memory rate limiting and quota tracking

**Note**: This is a learning/testing simulator. It mimics Azure APIM behavior but is not a complete implementation!

## Simulated APIM Features

✅ Subscription key validation
✅ Rate limiting per subscription
✅ Quota tracking
✅ Request proxying
✅ APIM-style error responses
✅ Statistics and monitoring

❌ Not implemented (would require more complexity):
- OAuth 2.0 validation (combine with oauth-server separately)
- Policy expressions
- Caching
- Backend load balancing
- Circuit breaker (basic example in main README)

## See Also

- [Main Mock API Lab](../README.md)
- [OAuth Server](../oauth-server/README.md)
- [Test Scripts](../scripts/)
