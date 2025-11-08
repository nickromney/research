#!/bin/bash
# test-api.sh - API test suite for mock-api-lab

BASE_URL="http://localhost:8080/api"
SUB_KEY="primary-key-12345"
OAUTH_URL="http://localhost:3001"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0

run_test() {
    test_count=$((test_count + 1))
    echo -n "Test $test_count: $1 ... "

    if eval "$2" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        pass_count=$((pass_count + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

echo "========================================="
echo "Mock API Lab - Test Suite"
echo "========================================="
echo ""

# OAuth Server Tests
echo "OAuth Server Tests:"
echo "-------------------"

run_test "OAuth server health check" \
    "curl -sf $OAUTH_URL/health"

run_test "OAuth client credentials flow" \
    "curl -sf -X POST $OAUTH_URL/oauth/token \
     -d 'grant_type=client_credentials' \
     -d 'client_id=application' \
     -d 'client_secret=secret' | grep -q 'accessToken'"

run_test "OAuth password grant flow" \
    "curl -sf -X POST $OAUTH_URL/oauth/token \
     -d 'grant_type=password' \
     -d 'username=user1' \
     -d 'password=password1' \
     -d 'client_id=application' \
     -d 'client_secret=secret' | grep -q 'accessToken'"

# Get OAuth token for protected resource test
TOKEN=$(curl -sf -X POST $OAUTH_URL/oauth/token \
    -d 'grant_type=client_credentials' \
    -d 'client_id=application' \
    -d 'client_secret=secret' | jq -r '.accessToken' 2>/dev/null)

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    run_test "Access protected resource with OAuth token" \
        "curl -sf -H 'Authorization: Bearer $TOKEN' $OAUTH_URL/api/protected | grep -q 'Success'"
else
    echo -e "Test: Access protected resource with OAuth token ... ${YELLOW}SKIP${NC} (no token)"
fi

echo ""

# APIM Simulator Tests
echo "APIM Simulator Tests:"
echo "---------------------"

run_test "APIM health check" \
    "curl -sf http://localhost:8080/health"

run_test "Reject missing subscription key" \
    "! curl -sf http://localhost:8080/api/get"

run_test "Reject invalid subscription key" \
    "! curl -sf -H 'Ocp-Apim-Subscription-Key: invalid-key' http://localhost:8080/api/get"

run_test "Accept valid subscription key" \
    "curl -sf -H 'Ocp-Apim-Subscription-Key: $SUB_KEY' http://localhost:8080/api/get"

run_test "Proxy GET request to backend" \
    "curl -sf -H 'Ocp-Apim-Subscription-Key: $SUB_KEY' http://localhost:8080/api/get | grep -q 'httpbin'"

run_test "Proxy POST request to backend" \
    "curl -sf -X POST -H 'Ocp-Apim-Subscription-Key: $SUB_KEY' \
     -H 'Content-Type: application/json' \
     -d '{\"test\":\"data\"}' \
     http://localhost:8080/api/post | grep -q 'httpbin'"

run_test "Rate limit headers present" \
    "curl -sI -H 'Ocp-Apim-Subscription-Key: $SUB_KEY' http://localhost:8080/api/get | grep -q 'X-RateLimit-Limit'"

run_test "APIM stats endpoint" \
    "curl -sf http://localhost:8080/stats | grep -q 'primary-key-12345'"

echo ""
echo "========================================="
echo "Results: $pass_count/$test_count tests passed"

if [ $pass_count -eq $test_count ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    echo "========================================="
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    echo "========================================="
    exit 1
fi
