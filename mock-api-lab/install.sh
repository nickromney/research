#!/bin/bash
# install.sh - Setup script for mock-api-lab

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "========================================="
echo "Mock API Lab - Installation"
echo "========================================="
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js is not installed${NC}"
    echo "  Please install Node.js (v14 or higher) from https://nodejs.org/"
    exit 1
else
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓ Node.js found: $NODE_VERSION${NC}"
fi

# Check npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ npm is not installed${NC}"
    exit 1
else
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓ npm found: $NPM_VERSION${NC}"
fi

# Check curl
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}⚠ curl is not installed (optional, but recommended)${NC}"
else
    echo -e "${GREEN}✓ curl found${NC}"
fi

# Check jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠ jq is not installed (optional, but recommended for JSON parsing)${NC}"
    echo "  Install: sudo apt install jq (Debian/Ubuntu) or brew install jq (macOS)"
else
    echo -e "${GREEN}✓ jq found${NC}"
fi

echo ""
echo -e "${BLUE}Installing dependencies...${NC}"
echo ""

# Install root dependencies
echo "Installing root dependencies..."
npm install

# Install OAuth server dependencies
echo "Installing OAuth server dependencies..."
cd oauth-server
npm install
cd ..

# Install APIM simulator dependencies
echo "Installing APIM simulator dependencies..."
cd apim-simulator
npm install
cd ..

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""

# Optional: Install LoopBack CLI
echo -e "${YELLOW}Optional: Install LoopBack CLI globally?${NC}"
echo "This allows you to create your own LoopBack APIs."
echo -n "Install @loopback/cli globally? (y/N): "
read -r INSTALL_LB

if [[ "$INSTALL_LB" =~ ^[Yy]$ ]]; then
    echo "Installing @loopback/cli..."
    npm install -g @loopback/cli
    echo -e "${GREEN}✓ LoopBack CLI installed${NC}"
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Start the servers:"
echo "   Terminal 1: cd oauth-server && npm start"
echo "   Terminal 2: cd apim-simulator && npm start"
echo ""
echo "   Or use concurrently (installed):"
echo "   npm run start:all"
echo ""
echo "2. Run the tests:"
echo "   cd scripts && ./test-api.sh"
echo ""
echo "3. Try the interactive demo:"
echo "   cd scripts && ./demo.sh"
echo ""
echo "4. Run load test:"
echo "   cd scripts && ./load-test.sh"
echo ""
echo "Quick test:"
echo "  OAuth:  curl http://localhost:3001/health"
echo "  APIM:   curl http://localhost:8080/health"
echo ""
echo "========================================="
