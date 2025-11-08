# Test Scripts

Bash scripts for testing and demonstrating the Mock API Lab.

## Scripts

### test-api.sh

Automated test suite that validates both OAuth server and APIM simulator.

```bash
./test-api.sh
```

Tests:
- OAuth server health
- OAuth client credentials flow
- OAuth password grant flow
- Protected resource access
- APIM subscription key validation
- APIM request proxying
- Rate limiting headers
- APIM statistics

**Exit codes**:
- `0`: All tests passed
- `1`: One or more tests failed

### load-test.sh

Load testing script to test rate limiting.

```bash
# Default: 200 requests with primary key
./load-test.sh

# Custom: 100 requests with secondary key (lower rate limit)
./load-test.sh secondary-key-67890 100
```

Output shows:
- Success count (HTTP 200)
- Rate limited count (HTTP 429)
- Error count (other failures)

### demo.sh

Interactive demonstration of the mock API lab features.

```bash
./demo.sh
```

Demonstrates:
1. OAuth 2.0 authentication flows
2. APIM gateway with subscription keys
3. Rate limiting in action

**Note**: Requires jq for JSON parsing.

## Prerequisites

All scripts require:
- `curl` - HTTP client
- `jq` - JSON processor
- Bash shell

Install on Debian/Ubuntu:
```bash
sudo apt install curl jq
```

## Usage

Make sure both servers are running:

```bash
# Terminal 1: OAuth server
cd ../oauth-server && npm start

# Terminal 2: APIM simulator
cd ../apim-simulator && npm start

# Terminal 3: Run tests
cd scripts
./test-api.sh
```

Or use concurrently:
```bash
# From mock-api-lab root
npm run start:all

# Then in another terminal
cd scripts && ./test-api.sh
```

## Example Output

### test-api.sh
```
=========================================
Mock API Lab - Test Suite
=========================================

OAuth Server Tests:
-------------------
Test 1: OAuth server health check ... PASS
Test 2: OAuth client credentials flow ... PASS
Test 3: OAuth password grant flow ... PASS
Test 4: Access protected resource with OAuth token ... PASS

APIM Simulator Tests:
---------------------
Test 5: APIM health check ... PASS
Test 6: Reject missing subscription key ... PASS
Test 7: Reject invalid subscription key ... PASS
Test 8: Accept valid subscription key ... PASS
...

=========================================
Results: 12/12 tests passed
All tests passed!
=========================================
```

### load-test.sh
```
=========================================
Load Test for APIM Simulator
=========================================
Target: http://localhost:8080/api/get
Subscription Key: secondary-key-67890
Requests: 50
=========================================

Running test (. = success, R = rate limited, E = error)

..........RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR (50/50)

=========================================
Load Test Results
=========================================
Total Requests:    50
Success (200):     10
Rate Limited (429): 40
Errors:            0
=========================================
Success Rate: 20%

✓ Rate limiting is working!
  Requests started getting rate limited after ~10 requests/minute
=========================================
```

## CI/CD

These scripts are also used in the GitHub Actions workflow for automated testing on every push.

See: `.github/workflows/mock-api-lab.yml`

## Troubleshooting

### "Connection refused"
- Make sure both servers are running
- Check ports 3001 and 8080 are not in use

### "command not found: jq"
- Install jq: `sudo apt install jq`

### Tests fail
- Check server logs for errors
- Verify server health: `curl localhost:3001/health`
- Ensure Node.js dependencies are installed

## See Also

- [Main Mock API Lab](../README.md)
- [OAuth Server](../oauth-server/README.md)
- [APIM Simulator](../apim-simulator/README.md)
