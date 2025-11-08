#!/bin/bash
# demo.sh - Interactive demo of the mock API lab

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

OAUTH_URL="http://localhost:3001"
APIM_URL="http://localhost:8080"

echo "========================================="
echo "Mock API Lab - Interactive Demo"
echo "========================================="
echo ""

pause() {
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

demo_oauth() {
    echo -e "${BLUE}=== OAuth 2.0 Server Demo ===${NC}"
    echo ""

    echo "1. Getting OAuth token (client credentials flow):"
    echo ""
    echo -e "${GREEN}$ curl -X POST $OAUTH_URL/oauth/token \\${NC}"
    echo -e "${GREEN}  -d 'grant_type=client_credentials' \\${NC}"
    echo -e "${GREEN}  -d 'client_id=application' \\${NC}"
    echo -e "${GREEN}  -d 'client_secret=secret'${NC}"
    echo ""

    TOKEN_RESPONSE=$(curl -s -X POST $OAUTH_URL/oauth/token \
        -d 'grant_type=client_credentials' \
        -d 'client_id=application' \
        -d 'client_secret=secret')

    echo "Response:"
    echo "$TOKEN_RESPONSE" | jq
    pause

    TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.accessToken')

    echo ""
    echo "2. Using token to access protected resource:"
    echo ""
    echo -e "${GREEN}$ curl -H 'Authorization: Bearer \$TOKEN' $OAUTH_URL/api/protected${NC}"
    echo ""

    curl -s -H "Authorization: Bearer $TOKEN" $OAUTH_URL/api/protected | jq
    pause
}

demo_apim() {
    echo -e "${BLUE}=== APIM Simulator Demo ===${NC}"
    echo ""

    echo "1. Calling API without subscription key (should fail):"
    echo ""
    echo -e "${GREEN}$ curl $APIM_URL/api/get${NC}"
    echo ""

    curl -s $APIM_URL/api/get | jq
    pause

    echo ""
    echo "2. Calling API with valid subscription key:"
    echo ""
    echo -e "${GREEN}$ curl -H 'Ocp-Apim-Subscription-Key: primary-key-12345' $APIM_URL/api/get${NC}"
    echo ""

    curl -s -H 'Ocp-Apim-Subscription-Key: primary-key-12345' $APIM_URL/api/get | jq
    pause

    echo ""
    echo "3. Checking rate limit headers:"
    echo ""
    echo -e "${GREEN}$ curl -I -H 'Ocp-Apim-Subscription-Key: primary-key-12345' $APIM_URL/api/get${NC}"
    echo ""

    curl -sI -H 'Ocp-Apim-Subscription-Key: primary-key-12345' $APIM_URL/api/get | grep -E '(HTTP|X-RateLimit|X-Quota)'
    pause

    echo ""
    echo "4. Viewing APIM statistics:"
    echo ""
    echo -e "${GREEN}$ curl $APIM_URL/stats${NC}"
    echo ""

    curl -s $APIM_URL/stats | jq
    pause
}

demo_rate_limiting() {
    echo -e "${BLUE}=== Rate Limiting Demo ===${NC}"
    echo ""
    echo "Sending 15 requests rapidly (rate limit is 10/min for secondary key)..."
    echo ""

    for i in {1..15}; do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            -H 'Ocp-Apim-Subscription-Key: secondary-key-67890' \
            $APIM_URL/api/get)

        if [ "$HTTP_CODE" == "200" ]; then
            echo -e "${GREEN}Request $i: Success (200)${NC}"
        elif [ "$HTTP_CODE" == "429" ]; then
            echo -e "${YELLOW}Request $i: Rate Limited (429)${NC}"
        else
            echo -e "Request $i: HTTP $HTTP_CODE"
        fi

        sleep 0.2
    done

    pause
}

# Main demo flow
echo "This demo will show you:"
echo "  1. OAuth 2.0 authentication"
echo "  2. APIM gateway with subscription keys"
echo "  3. Rate limiting in action"
echo ""

pause

demo_oauth
demo_apim
demo_rate_limiting

echo ""
echo "========================================="
echo "Demo Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  - Try the test suite: ./test-api.sh"
echo "  - Run load test: ./load-test.sh"
echo "  - Explore the code in ../oauth-server and ../apim-simulator"
echo ""
