# Docker/Podman Quick Start Guide

This guide shows how to run the Mock API Lab using containers instead of local Node.js installation.

## Security Warning

**This is a learning/testing environment with intentional security issues:**
- Hardcoded credentials and secrets
- Plaintext password storage
- SSRF vulnerabilities
- No input validation

**DO NOT use in production!** See main [README.md](README.md#-security-warning) for details.

## Prerequisites

You need either:
- **Podman** + **podman-compose** (recommended for Linux/macOS)
- **Docker** + **docker compose** (works on all platforms)

### Install Podman (macOS)

```bash
brew install podman podman-compose
podman machine init
podman machine start
```

### Install Docker (macOS)

```bash
brew install --cask docker
# Or download Docker Desktop from https://www.docker.com/products/docker-desktop
```

## Quick Start

### 1. Start Services

```bash
cd mock-api-lab

# Using Podman Compose (recommended)
podman-compose up

# OR using Docker Compose
docker compose up

# Run in background (detached mode)
podman-compose up -d
```

This will:
- Build container images for both services
- Start OAuth server on port 3001
- Start APIM simulator on port 8080
- Set up networking between services
- Run health checks

### 2. Verify Services

```bash
# Check OAuth server
curl http://localhost:3001/health

# Check APIM simulator
curl http://localhost:8080/health
```

### 3. Run Tests

Open a new terminal (keep services running):

```bash
cd mock-api-lab/scripts

# Run automated test suite
./test-api.sh

# Run load test
./load-test.sh

# Interactive demo
./demo.sh
```

### 4. Stop Services

```bash
# Stop and remove containers
podman-compose down

# OR with Docker
docker compose down
```

## Advanced Usage

### View Logs

```bash
# View all logs
podman-compose logs

# Follow logs in real-time
podman-compose logs -f

# View logs for specific service
podman-compose logs oauth-server
podman-compose logs apim-simulator
```

### Rebuild After Code Changes

```bash
# Rebuild and restart
podman-compose up --build

# Force rebuild
podman-compose build --no-cache
podman-compose up
```

### Run Individual Services

```bash
# Start only OAuth server
podman-compose up oauth-server

# Start only APIM simulator (also starts OAuth as dependency)
podman-compose up apim-simulator
```

### Access Container Shell

```bash
# OAuth server shell
podman exec -it mock-api-lab-oauth-server sh

# APIM simulator shell
podman exec -it mock-api-lab-apim-simulator sh
```

## Service Details

### OAuth Server (port 3001)

- **Image**: `mock-api-lab-oauth-server:latest`
- **Container**: `mock-api-lab-oauth-server`
- **Health Check**: `http://localhost:3001/health`
- **Endpoints**:
 - Token: `http://localhost:3001/oauth/token`
 - Protected: `http://localhost:3001/api/protected`

**Credentials**:
- Client: `application` / `secret`
- Users: `user1/password1`, `admin/admin123`

### APIM Simulator (port 8080)

- **Image**: `mock-api-lab-apim-simulator:latest`
- **Container**: `mock-api-lab-apim-simulator`
- **Health Check**: `http://localhost:8080/health`
- **Endpoints**:
 - Gateway: `http://localhost:8080/api/*`
 - Stats: `http://localhost:8080/stats`

**Subscription Keys**:
- Primary: `primary-key-12345` (100 req/min)
- Secondary: `secondary-key-67890` (10 req/min)

## Quick Tests

### Test OAuth Flow

```bash
# Get token
TOKEN=$(curl -s -X POST http://localhost:3001/oauth/token \
 -d 'grant_type=client_credentials' \
 -d 'client_id=application' \
 -d 'client_secret=secret' | jq -r '.accessToken')

echo "Token: $TOKEN"

# Access protected resource
curl -H "Authorization: Bearer $TOKEN" \
 http://localhost:3001/api/protected
```

### Test APIM Gateway

```bash
# Without subscription key (should fail)
curl http://localhost:8080/api/get

# With valid subscription key
curl -H 'Ocp-Apim-Subscription-Key: primary-key-12345' \
 http://localhost:8080/api/get

# Check rate limit headers
curl -i -H 'Ocp-Apim-Subscription-Key: primary-key-12345' \
 http://localhost:8080/api/get | grep "X-RateLimit"
```

### Test Rate Limiting

```bash
# Trigger rate limit with secondary key (10 req/min)
for i in {1..15}; do
 curl -s -H 'Ocp-Apim-Subscription-Key: secondary-key-67890' \
 http://localhost:8080/api/get | jq -r '.error // "OK"'
done
```

## Troubleshooting

### Port Already in Use

```bash
# Check what's using port 3001
lsof -i :3001

# Check what's using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>
```

### Services Not Starting

```bash
# View detailed logs
podman-compose logs -f

# Check service health
podman ps -a

# Remove containers and start fresh
podman-compose down -v
podman-compose up --build
```

### Network Issues

```bash
# Inspect network
podman network inspect mock-api-lab_mock-api-lab

# Recreate network
podman-compose down
podman network rm mock-api-lab_mock-api-lab
podman-compose up
```

### Permission Issues (Podman on macOS)

```bash
# Restart Podman machine
podman machine stop
podman machine start

# Check machine status
podman machine list
```

## Differences from Local Installation

### Advantages

- No local Node.js dependencies
- Consistent environment across machines
- Isolated from system
- Easy cleanup (just remove containers)
- Health checks and automatic restarts
- Network isolation

### Limitations

- Slightly slower startup (first build)
- Need to rebuild after code changes
- Can't use `npm run start:all` (use compose instead)

## Switching Between Methods

You can switch between containerized and local installation:

**Container → Local**:
```bash
podman-compose down
./install.sh
npm run start:all
```

**Local → Container**:
```bash
# Stop local services (Ctrl+C)
podman-compose up
```

## CI/CD Integration

The GitHub Actions workflow (`.github/workflows/mock-api-lab.yml`) uses the local installation method, not containers. This is because:
- Faster CI runs (no container build time)
- GitHub Actions already runs in containers
- Simpler dependency caching with npm

## Next Steps

1. Start services: `podman-compose up -d`
2. Run tests: `cd scripts && ./test-api.sh`
3. Explore APIs: Check the main [README.md](README.md)
4. Experiment with policies and rate limiting
5. Stop services: `podman-compose down`

For more details, see:
- [Main README](README.md)
- [compose.yml](compose.yml) - Service configuration
- [oauth-server/Dockerfile](oauth-server/Dockerfile) - OAuth container
- [apim-simulator/Dockerfile](apim-simulator/Dockerfile) - APIM container
