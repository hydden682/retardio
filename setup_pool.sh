#!/bin/bash
# Retardio Mining Pool Setup Script
# This script sets up NOMP (Node Open Mining Portal) for Retardio

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Retardio Mining Pool Setup${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run as root${NC}"
    exit 1
fi

# Step 1: Install dependencies
echo -e "${YELLOW}Step 1: Installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y nodejs npm redis-server git build-essential

# Start Redis
echo -e "${YELLOW}Starting Redis server...${NC}"
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify Redis is running
if ! systemctl is-active --quiet redis-server; then
    echo -e "${RED}Failed to start Redis server${NC}"
    exit 1
fi
echo -e "${GREEN}Redis is running${NC}"

# Step 2: Clone NOMP
echo -e "${YELLOW}Step 2: Cloning NOMP repository...${NC}"
if [ -d "node-open-mining-portal" ]; then
    echo -e "${YELLOW}NOMP directory already exists, skipping clone${NC}"
else
    git clone https://github.com/zone117x/node-open-mining-portal.git
fi

cd node-open-mining-portal

# Step 3: Install NOMP dependencies
echo -e "${YELLOW}Step 3: Installing NOMP dependencies...${NC}"
npm update
npm install

# Step 4: Configure NOMP for Retardio
echo -e "${YELLOW}Step 4: Configuring NOMP for Retardio...${NC}"

# Create coins directory if it doesn't exist
mkdir -p coins

# Copy Retardio coin config
echo -e "${YELLOW}Copying Retardio coin configuration...${NC}"
cp ../pool-configs/retardio-coin.json coins/retardio.json

# Create pool_configs directory if it doesn't exist
mkdir -p pool_configs

# Copy Retardio pool config
echo -e "${YELLOW}Copying Retardio pool configuration...${NC}"
cp ../pool-configs/retardio-pool.json pool_configs/retardio.json

# Step 5: Get pool configuration from user
echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Pool Configuration${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

read -p "Enter your pool payout address (must start with F): " POOL_ADDRESS
read -p "Enter your pool fee address (must start with F): " FEE_ADDRESS
read -p "Enter your Retardio RPC username [retardiouser]: " RPC_USER
RPC_USER=${RPC_USER:-retardiouser}
read -sp "Enter your Retardio RPC password: " RPC_PASS
echo ""

# Update pool config with user values
echo -e "${YELLOW}Updating pool configuration...${NC}"
sed -i "s/CHANGE_THIS_TO_YOUR_POOL_ADDRESS/$POOL_ADDRESS/g" pool_configs/retardio.json
sed -i "s/CHANGE_THIS_TO_FEE_ADDRESS/$FEE_ADDRESS/g" pool_configs/retardio.json
sed -i "s/retardiouser/$RPC_USER/g" pool_configs/retardio.json
sed -i "s/CHANGE_THIS_TO_YOUR_RPC_PASSWORD/$RPC_PASS/g" pool_configs/retardio.json

# Step 6: Create startup script
echo -e "${YELLOW}Creating pool startup script...${NC}"
cat > start_pool.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Starting Retardio Mining Pool..."
node init.js
EOF

chmod +x start_pool.sh

# Step 7: Instructions
echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. Make sure your Retardio node is running with these settings in retardio.conf:"
echo -e "   ${YELLOW}server=1${NC}"
echo -e "   ${YELLOW}rpcuser=$RPC_USER${NC}"
echo -e "   ${YELLOW}rpcpassword=<your_password>${NC}"
echo -e "   ${YELLOW}rpcport=18332${NC}"
echo -e "   ${YELLOW}txindex=1${NC}"
echo ""
echo -e "2. Start the pool:"
echo -e "   ${YELLOW}cd node-open-mining-portal${NC}"
echo -e "   ${YELLOW}./start_pool.sh${NC}"
echo ""
echo -e "3. Miners can connect to:"
echo -e "   ${YELLOW}stratum+tcp://<your_server_ip>:3032${NC} (All miners)"
echo ""
echo -e "4. Pool configuration files:"
echo -e "   ${YELLOW}pool_configs/retardio.json${NC} - Pool settings"
echo -e "   ${YELLOW}coins/retardio.json${NC} - Coin settings"
echo ""
echo -e "${GREEN}Happy mining!${NC}"
