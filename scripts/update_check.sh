#!/bin/bash
# Retardio Update Checker
# Checks for updates and prompts user before updating

set -e

CURRENT_VERSION="1.1.0"
VERSION_URL="https://raw.githubusercontent.com/hydden682/retardio/29.x-knots/version.json"
REPO_DIR="${RETARDIO_DIR:-$HOME/retardio-coin}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  RETARDIO UPDATE CHECKER${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Current version: ${GREEN}v$CURRENT_VERSION${NC}"
echo ""

# Check for curl or wget
if command -v curl &> /dev/null; then
    FETCH="curl -sL"
elif command -v wget &> /dev/null; then
    FETCH="wget -qO-"
else
    echo -e "${RED}Error: curl or wget required${NC}"
    exit 1
fi

# Fetch latest version info
echo "Checking for updates..."
VERSION_JSON=$($FETCH "$VERSION_URL" 2>/dev/null) || {
    echo -e "${RED}Failed to check for updates. Network error?${NC}"
    exit 1
}

# Parse JSON (simple grep-based parsing for portability)
LATEST_VERSION=$(echo "$VERSION_JSON" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
RELEASE_DATE=$(echo "$VERSION_JSON" | grep -o '"release_date"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
MESSAGE=$(echo "$VERSION_JSON" | grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
CRITICAL=$(echo "$VERSION_JSON" | grep -o '"critical"[[:space:]]*:[[:space:]]*[^,}]*' | awk -F: '{print $2}' | tr -d ' ')
RELEASE_URL=$(echo "$VERSION_JSON" | grep -o '"release_url"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Failed to parse version info${NC}"
    exit 1
fi

echo -e "Latest version:  ${GREEN}v$LATEST_VERSION${NC} (released $RELEASE_DATE)"
echo ""

# Compare versions
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${GREEN}You are running the latest version!${NC}"
    exit 0
fi

# Version comparison (simple string compare works for semver)
if [[ "$CURRENT_VERSION" > "$LATEST_VERSION" ]]; then
    echo -e "${YELLOW}You are running a newer version than the latest release.${NC}"
    echo "This is fine if you're running from git."
    exit 0
fi

# Update available
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  UPDATE AVAILABLE!${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "New version: ${GREEN}v$LATEST_VERSION${NC}"
echo -e "Changes: $MESSAGE"
echo ""

if [ "$CRITICAL" = "true" ]; then
    echo -e "${RED}*** THIS IS A CRITICAL SECURITY UPDATE ***${NC}"
    echo -e "${RED}*** UPDATING IS STRONGLY RECOMMENDED ***${NC}"
    echo ""
fi

echo -e "Release notes: $RELEASE_URL"
echo ""

# Ask user
read -p "Do you want to update now? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Update cancelled. You can update manually with:"
    echo "  cd $REPO_DIR && git pull origin 29.x-knots"
    exit 0
fi

echo ""
echo "Updating..."

# Stop services
echo "Stopping Retardio services..."
sudo systemctl stop retardio-pool.service 2>/dev/null || true
sudo systemctl stop retardio-pool-ui.service 2>/dev/null || true
sudo systemctl stop retardio-node.service 2>/dev/null || true

# Pull updates
cd "$REPO_DIR"
echo "Pulling latest changes..."
git fetch origin
git checkout 29.x-knots
git pull origin 29.x-knots

# Update version in this script
sed -i "s/CURRENT_VERSION=\"$CURRENT_VERSION\"/CURRENT_VERSION=\"$LATEST_VERSION\"/" "$0"

# Restart services
echo "Restarting Retardio services..."
sudo systemctl start retardio-node.service 2>/dev/null || true
sleep 5
sudo systemctl start retardio-pool.service 2>/dev/null || true
sudo systemctl start retardio-pool-ui.service 2>/dev/null || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  UPDATE COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Now running: ${GREEN}v$LATEST_VERSION${NC}"
echo ""
echo "Check service status with:"
echo "  sudo systemctl status retardio-node"
echo "  sudo systemctl status retardio-pool"
echo "  sudo systemctl status retardio-pool-ui"
echo ""
