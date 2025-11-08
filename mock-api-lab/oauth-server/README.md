# Mock OAuth 2.0 Server

A working OAuth 2.0 authorization server for testing and learning OAuth flows.

## Features

- OAuth 2.0 client credentials grant (machine-to-machine)
- OAuth 2.0 password grant (user authentication)
- Token generation and validation
- Protected resource endpoint

## Usage

```bash
# Install dependencies
npm install

# Start server
npm start
```

Server runs on `http://localhost:3001`

## Test Credentials

### Client
- **Client ID**: `application`
- **Client Secret**: `secret`

### Users
- `user1` / `password1`
- `admin` / `admin123`

## Endpoints

### Token Endpoint
```bash
# Client credentials flow
curl -X POST http://localhost:3001/oauth/token \
  -d 'grant_type=client_credentials' \
  -d 'client_id=application' \
  -d 'client_secret=secret'

# Password grant flow
curl -X POST http://localhost:3001/oauth/token \
  -d 'grant_type=password' \
  -d 'username=user1' \
  -d 'password=password1' \
  -d 'client_id=application' \
  -d 'client_secret=secret'
```

### Protected Resource
```bash
# Get a token first
TOKEN=$(curl -s -X POST http://localhost:3001/oauth/token \
  -d 'grant_type=client_credentials' \
  -d 'client_id=application' \
  -d 'client_secret=secret' | jq -r '.accessToken')

# Use token to access protected resource
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3001/api/protected
```

### Health Check
```bash
curl http://localhost:3001/health
```

## Implementation

Built with:
- Express.js for HTTP server
- oauth2-server for OAuth 2.0 implementation
- In-memory storage (for demo purposes)

**Note**: This is a learning/testing server. Do NOT use in production!

## See Also

- [Main Mock API Lab](../README.md)
- [APIM Simulator](../apim-simulator/README.md)
