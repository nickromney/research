# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a research repository for LLM-assisted code development, inspired by simonw/research. It contains multiple independent projects focused on Azure API Management (APIM), API learning resources, and GitHub Actions development.

## Project Structure

The repository is organized into independent subprojects, each with its own README.md:

- **github-release-action/** - TypeScript GitHub Action for checking release versions
- **mock-api-lab/** - Multi-component Node.js lab for learning API concepts
- **api-fundamentals-for-infrastructure/** - Documentation/tutorial project
- **apim-*** - Five separate Azure APIM research/documentation projects

## Development Commands

### github-release-action

A TypeScript GitHub Action built with @vercel/ncc for bundling.

```bash
cd github-release-action

# Install dependencies
npm install

# Build TypeScript
npm run build

# Bundle for distribution (compiles to dist/index.js)
npm run bundle

# Complete build and bundle
npm run all
```

**Architecture**: Action entry point is `src/main.ts` which uses `@actions/core` and `@actions/github`. The main logic is split between:
- `src/checker.ts` - GitHub release fetching via Octokit
- `src/policy.ts` - Days-based and version-based policy evaluation using semver
- `src/main.ts` - Action orchestration, input handling, and GitHub Actions outputs

**Important**: The bundled `dist/index.js` must be committed to the repository for the action to work.

### mock-api-lab

A multi-component Node.js learning environment with three services that can run concurrently.

**RECOMMENDED: Use Podman/Docker Compose**

```bash
cd mock-api-lab

# Start all services with Podman Compose (recommended)
podman-compose up

# Or with Docker Compose
docker compose up

# Start in detached mode
podman-compose up -d

# Stop services
podman-compose down

# Rebuild containers after code changes
podman-compose up --build

# Run tests (services must be running)
cd scripts && ./test-api.sh
cd scripts && ./load-test.sh
cd scripts && ./demo.sh
```

**Alternative: Run without containers (legacy)**

```bash
cd mock-api-lab

# Install all dependencies across all subprojects
npm run install-all
# OR use the install script
./install.sh

# Start individual services
npm run start:oauth    # OAuth server on port 3001
npm run start:apim     # APIM simulator on port 8080

# Start all services concurrently
npm run start:all

# Run test suite
npm run test
# OR
cd scripts && ./test-api.sh

# Run load tests
npm run load-test
# OR
cd scripts && ./load-test.sh

# Interactive demo
cd scripts && ./demo.sh
```

**Important**: The OAuth 2.0 server now uses `@node-oauth/oauth2-server` version 5.2.1 (the actively maintained fork). If you encounter dependency errors, ensure `oauth-server/package.json` specifies `"@node-oauth/oauth2-server": "^5.2.1"`.

**Architecture**: The lab consists of three independent components:

1. **oauth-server/** - Express-based OAuth 2.0 server (port 3001)
   - Single file: `oauth-server.js`
   - Implements client_credentials and password grant flows
   - In-memory token storage

2. **apim-simulator/** - Express-based APIM gateway simulator (port 8080)
   - Single file: `apim-simulator.js`
   - Features: subscription key validation, rate limiting, request proxying
   - Proxies requests to backends (e.g., httpbin.org or local services)

3. **scripts/** - Bash test scripts
   - `test-api.sh` - Automated test suite
   - `load-test.sh` - Rate limit testing
   - `demo.sh` - Interactive demonstration

**Test Credentials**:
- OAuth client: `application` / `secret`
- OAuth users: `user1/password1`, `admin/admin123`
- Subscription keys: `primary-key-12345`, `secondary-key-67890`

**Important**: This is a learning/testing environment with hardcoded credentials and intentional security vulnerabilities (SSRF, plaintext passwords). Never use in production.

## Common Patterns

### Running Tests

Each TypeScript project should eventually have proper tests. Currently:
- `github-release-action/` - Tests planned but not implemented
- `mock-api-lab/` - Bash-based integration tests in `scripts/`

### Building TypeScript Projects

TypeScript projects follow this pattern:
```bash
npm install        # Install dependencies
npm run build      # Compile TypeScript (tsc)
npm run bundle     # Bundle for distribution (if using @vercel/ncc)
```

### Git Workflow

This repository follows a standard feature branch workflow:
- Main branch: `main`
- Feature branches follow pattern from commits (e.g., `claude/feature-name`)
- Commit messages are concise and descriptive

## Key Architecture Decisions

### github-release-action

**Policy Evaluation**: The action supports two distinct policy types:
1. **Days-based**: Time-bound expiry (e.g., runners must update within 30 days)
2. **Version-based**: Semantic versioning windows (e.g., Kubernetes N-3 support)

The policy evaluation logic in `src/policy.ts` is independent of the GitHub API interaction in `src/checker.ts`, allowing for clean separation of concerns.

**Bundling**: Uses @vercel/ncc to create a single bundled file in `dist/index.js` with all dependencies included. This is required because GitHub Actions cannot run `npm install` on the runner.

### mock-api-lab

**Multi-Service Architecture**: The lab uses a microservices-like pattern where:
- OAuth server is completely independent (can run standalone)
- APIM simulator can proxy to any backend (not just local services)
- Test scripts orchestrate both services

**Service Communication**:
- OAuth server validates tokens via the `/api/protected` endpoint
- APIM simulator forwards validated requests to backends
- Rate limiting is per-subscription-key per-minute using in-memory tracking

**Concurrency**: Uses the `concurrently` npm package to run multiple services from the root `package.json`, making it easy to start the entire lab environment with one command.

**Containerization**: The lab includes Docker/Podman support with:
- Individual Dockerfiles for each service (oauth-server, apim-simulator)
- `compose.yml` for orchestrating both services with health checks
- Network isolation using a dedicated bridge network
- Automatic service dependency management (APIM waits for OAuth to be healthy)

## APIM Research Projects

The five APIM research projects are primarily documentation/research:
- `apim-internal-mode-network-security/` - VNet integration and network security
- `apim-policy-security/` - Policy-level security patterns and XML policy examples
- `apim-multitenant-access/` - Products, Subscriptions, Groups, and access segmentation
- `apim-developer-tier-patterns/` - Cost-effective learning strategies
- `apim-backend-integration/` - Backend service integration patterns

These are research documentation projects, not code projects. Treat them as reference material.

## Important Notes

### Security Warnings

**mock-api-lab** intentionally contains security vulnerabilities for learning purposes:
- Hardcoded credentials in source code
- Plaintext password storage
- No input validation
- SSRF vulnerability via backend query parameter
- In-memory storage (data lost on restart)

When working on this code, preserve these characteristics as they're intentional for teaching purposes.

### TypeScript Configuration

TypeScript projects use ES2020 target with:
- Strict mode enabled
- CommonJS module system
- Source maps for debugging

### GitHub Actions Development

When modifying `github-release-action`, remember:
1. Changes to `src/**/*.ts` require `npm run bundle` to update `dist/index.js`
2. The `dist/` directory must be committed (unusual for most projects)
3. Action inputs/outputs are defined in `action.yml`
4. Test locally by running the bundled action with environment variables set

## Testing Locally

### Testing github-release-action

```bash
# Set required environment variables
export INPUT_REPOSITORY="actions/runner"
export INPUT_CURRENT-VERSION="2.320.0"
export INPUT_POLICY-TYPE="days"
export GITHUB_TOKEN="your-github-token"

# Run the action
node dist/index.js
```

### Testing mock-api-lab

Start services in separate terminals or use `npm run start:all`, then:

```bash
# Test OAuth server
curl http://localhost:3001/health

# Get OAuth token
TOKEN=$(curl -s -X POST http://localhost:3001/oauth/token \
  -d 'grant_type=client_credentials' \
  -d 'client_id=application' \
  -d 'client_secret=secret' | jq -r '.accessToken')

# Test APIM simulator
curl -H 'Ocp-Apim-Subscription-Key: primary-key-12345' \
  http://localhost:8080/api/get

# Run automated tests
cd scripts && ./test-api.sh
```

## Dependencies Management

### Production Dependencies

- **github-release-action**: Uses GitHub Actions SDK (`@actions/core`, `@actions/github`) and `semver` for version comparison
- **mock-api-lab/oauth-server**: Uses `express`, `oauth2-server`, `body-parser`
- **mock-api-lab/apim-simulator**: Uses `express`, `axios`

### Development Dependencies

All TypeScript projects use standard tooling:
- TypeScript 5.3+
- Node.js types (`@types/node`)
- @vercel/ncc for bundling (GitHub Actions only)

## Research Methodology

This repository follows the simonw/research pattern where each subdirectory is a self-contained research project. When adding new research:

1. Create a new directory with a descriptive name
2. Add a comprehensive README.md documenting the research
3. Include working code examples where applicable
4. Update the root README.md with project summary
5. Keep each project independent (separate package.json if needed)

## Port Allocation

When running mock-api-lab locally, these ports are used:
- 3001: OAuth 2.0 server
- 8080: APIM simulator
- 3000: Backend API (if using LoopBack or similar)

Avoid port conflicts when developing.
