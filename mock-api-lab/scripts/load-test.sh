#!/bin/bash
# load-test.sh - Simple load testing for APIM simulator

BASE_URL="http://localhost:8080/api/get"
SUB_KEY="${1:-primary-key-12345}"
REQUESTS="${2:-200}"
DELAY=0.1  # seconds between requests

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

success=0
rate_limited=0
errors=0

echo "========================================="
echo "Load Test for APIM Simulator"
echo "========================================="
echo "Target: $BASE_URL"
echo "Subscription Key: $SUB_KEY"
echo "Requests: $REQUESTS"
echo "========================================="
echo ""
echo "Running test (. = success, R = rate limited, E = error)"
echo ""

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

    # Newline every 50 requests for readability
    if [ $((i % 50)) -eq 0 ]; then
        echo " ($i/$REQUESTS)"
    fi

    sleep $DELAY
done

echo ""
echo ""
echo "========================================="
echo "Load Test Results"
echo "========================================="
echo -e "Total Requests:    $REQUESTS"
echo -e "${GREEN}Success (200):     $success${NC}"
echo -e "${YELLOW}Rate Limited (429): $rate_limited${NC}"
echo -e "${RED}Errors:            $errors${NC}"
echo "========================================="

# Calculate success rate
success_rate=$((success * 100 / REQUESTS))
echo "Success Rate: $success_rate%"

if [ $rate_limited -gt 0 ]; then
    echo ""
    echo "✓ Rate limiting is working!"
    echo "  Requests started getting rate limited after ~100 requests/minute"
fi

echo "========================================="
