#!/bin/sh
# pre-code-check.sh - Run this BEFORE starting to code
# Ensures environment is ready and prevents common issues
# Usage: ./scripts/pre-code-check.sh

set -e

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

echo "${BLUE}=== PRE-CODE SAFETY CHECK ===${NC}"
echo ""

# Flag to track if we're ready
READY=true

# 1. Check for uncommitted changes
echo "${BLUE}1. Checking git state...${NC}"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "${YELLOW}⚠️  Uncommitted changes detected${NC}"
    echo "   Options:"
    echo "   - git stash (to save for later)"
    echo "   - git commit -am 'checkpoint: before new work'"
    echo "   - Continue anyway if you're resuming work"
    read -p "   Continue with uncommitted changes? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        READY=false
    fi
else
    echo "${GREEN}✅ Working directory clean${NC}"
fi
echo ""

# 2. Install missing dependencies
echo "${BLUE}2. Checking dependencies...${NC}"
if [ -f package.json ]; then
    if [ ! -d node_modules ]; then
        echo "${YELLOW}📦 Installing missing node_modules...${NC}"
        npm install
    elif [ package.json -nt node_modules ]; then
        echo "${YELLOW}📦 package.json changed, updating dependencies...${NC}"
        npm install
    else
        echo "${GREEN}✅ Dependencies up to date${NC}"
    fi
fi

if [ -f requirements.txt ] && command -v python3 >/dev/null 2>&1; then
    if [ -d venv ]; then
        echo "${GREEN}✅ Python venv found${NC}"
    elif [ -d .venv ]; then
        echo "${GREEN}✅ Python .venv found${NC}"
    else
        echo "${YELLOW}⚠️  No Python virtual environment found${NC}"
        echo "   Consider: python3 -m venv venv && source venv/bin/activate"
    fi
fi
echo ""

# 3. Kill conflicting processes
echo "${BLUE}3. Checking for port conflicts...${NC}"
PORTS_TO_CHECK="3000 3001 4000 5000 8000 8080"
CONFLICTS=false

for port in $PORTS_TO_CHECK; do
    if command -v lsof >/dev/null 2>&1 && lsof -ti:$port >/dev/null 2>&1; then
        echo "${YELLOW}⚠️  Port $port is in use${NC}"
        CONFLICTS=true
        
        # Get process info
        process_info=$(lsof -ti:$port | xargs ps -p 2>/dev/null | tail -1)
        echo "   Process: $process_info"
        
        read -p "   Kill process on port $port? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            lsof -ti:$port | xargs kill -9 2>/dev/null || true
            echo "   ${GREEN}Killed process on port $port${NC}"
        fi
    fi
done

if [ "$CONFLICTS" = false ]; then
    echo "${GREEN}✅ No port conflicts${NC}"
fi
echo ""

# 4. Environment check
echo "${BLUE}4. Checking environment...${NC}"
if [ -f .env.example ] && [ ! -f .env ]; then
    echo "${YELLOW}⚠️  Missing .env file${NC}"
    read -p "   Copy .env.example to .env? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cp .env.example .env
        echo "   ${GREEN}Created .env from template${NC}"
        echo "   ${YELLOW}Remember to update with real values!${NC}"
    else
        READY=false
    fi
elif [ -f .env ]; then
    echo "${GREEN}✅ .env exists${NC}"
else
    echo "${YELLOW}⚠️  No .env or .env.example found${NC}"
fi
echo ""

# 5. Database/Service checks
echo "${BLUE}5. Checking required services...${NC}"
# PostgreSQL
if command -v psql >/dev/null 2>&1; then
    if pg_isready >/dev/null 2>&1; then
        echo "${GREEN}✅ PostgreSQL is running${NC}"
    else
        echo "${YELLOW}⚠️  PostgreSQL is not running${NC}"
        echo "   Start with: brew services start postgresql (macOS)"
        echo "   or: sudo systemctl start postgresql (Linux)"
    fi
fi

# Redis
if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli ping >/dev/null 2>&1; then
        echo "${GREEN}✅ Redis is running${NC}"
    else
        echo "${YELLOW}⚠️  Redis is not running${NC}"
        echo "   Start with: brew services start redis (macOS)"
        echo "   or: sudo systemctl start redis (Linux)"
    fi
fi

# MongoDB
if command -v mongod >/dev/null 2>&1; then
    if pgrep mongod >/dev/null 2>&1; then
        echo "${GREEN}✅ MongoDB is running${NC}"
    else
        echo "${YELLOW}⚠️  MongoDB is not running${NC}"
    fi
fi
echo ""

# 6. Create required directories
echo "${BLUE}6. Ensuring required directories...${NC}"
mkdir -p logs tmp uploads 2>/dev/null || true
echo "${GREEN}✅ Directory structure ready${NC}"
echo ""

# Final summary
if [ "$READY" = true ]; then
    echo "${GREEN}=== READY TO CODE ===${NC}"
    echo "All checks passed! Environment is prepared."
    
    # Suggest next commands based on project type
    if [ -f package.json ]; then
        echo ""
        echo "Suggested next commands:"
        echo "  npm run dev"
        echo "  npm test -- --watch"
    fi
else
    echo "${RED}=== NOT READY ===${NC}"
    echo "Please address the issues above before coding."
    exit 1
fi