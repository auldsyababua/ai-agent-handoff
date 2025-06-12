#!/bin/sh
# when-port-blocked.sh - Fix port already in use errors
# Usage: ./scripts/when-port-blocked.sh [port]
# Default: port 3000

set -e

# Get port from argument or default to 3000
PORT=${1:-3000}

# Colors (if terminal supports it)
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    NC=$(tput sgr0)
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    NC=''
fi

echo "${BLUE}=== PORT $PORT CONFLICT RESOLVER ===${NC}"
echo ""

# Check if lsof is available
if ! command -v lsof >/dev/null 2>&1; then
    echo "${RED}Error: lsof command not found${NC}"
    echo "Install lsof to use this script"
    exit 1
fi

# Find process using the port
echo "${BLUE}Checking port $PORT...${NC}"
PROCESS_INFO=$(lsof -ti:$PORT 2>/dev/null || true)

if [ -z "$PROCESS_INFO" ]; then
    echo "${GREEN}✅ Port $PORT is free!${NC}"
    exit 0
fi

# Get detailed process information
echo "${YELLOW}⚠️  Port $PORT is in use by:${NC}"
for PID in $PROCESS_INFO; do
    ps -p "$PID" -o pid,user,comm,args 2>/dev/null || echo "PID $PID (process info unavailable)"
done
echo ""

# Ask user what to do
echo "${BLUE}What would you like to do?${NC}"
echo "1) Kill the process(es) using port $PORT"
echo "2) Use a different port"
echo "3) Cancel"
echo ""
read -p "Choice (1-3): " -n 1 -r
echo ""

case $REPLY in
    1)
        echo "${YELLOW}Killing process(es) on port $PORT...${NC}"
        for PID in $PROCESS_INFO; do
            kill -9 "$PID" 2>/dev/null && echo "${GREEN}✅ Killed PID $PID${NC}" || echo "${RED}Failed to kill PID $PID${NC}"
        done
        
        # Verify port is free
        sleep 1
        if lsof -ti:$PORT >/dev/null 2>&1; then
            echo "${RED}❌ Port $PORT is still in use${NC}"
            echo "Try running with sudo: sudo ./scripts/when-port-blocked.sh $PORT"
        else
            echo "${GREEN}✅ Port $PORT is now free!${NC}"
        fi
        ;;
    2)
        echo "${BLUE}Suggested alternative ports:${NC}"
        for ALT_PORT in 3001 3002 4000 5000 8000 8080 9000; do
            if ! lsof -ti:$ALT_PORT >/dev/null 2>&1; then
                echo "${GREEN}✅ Port $ALT_PORT is available${NC}"
            fi
        done
        echo ""
        echo "Update your configuration to use a different port:"
        echo "- In package.json scripts: \"dev\": \"PORT=3001 npm start\""
        echo "- In .env file: PORT=3001"
        echo "- In your app code: process.env.PORT || 3001"
        ;;
    *)
        echo "Operation cancelled"
        exit 0
        ;;
esac

# Additional help
echo ""
echo "${BLUE}Additional commands:${NC}"
echo "- List all listening ports: lsof -i -P -n | grep LISTEN"
echo "- Kill all node processes: pkill -f node"
echo "- Kill specific port: lsof -ti:$PORT | xargs kill -9"