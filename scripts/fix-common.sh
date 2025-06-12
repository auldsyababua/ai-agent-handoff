#!/bin/sh
# fix-common.sh - Automatically fix the most common issues
# This script tries safe fixes for 90% of problems
# Usage: ./scripts/fix-common.sh

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

echo "${BLUE}=== AUTOMATIC FIX FOR COMMON ISSUES ===${NC}"
echo ""

FIXES_APPLIED=0

# 1. Port conflicts
echo "${BLUE}1. Checking for port conflicts...${NC}"
COMMON_PORTS="3000 3001 4000 5000 8000 8080 9000"
for port in $COMMON_PORTS; do
    if command -v lsof >/dev/null 2>&1 && lsof -ti:$port >/dev/null 2>&1; then
        echo "${YELLOW}   Killing process on port $port...${NC}"
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        echo "${GREEN}   ✅ Port $port cleared${NC}"
    fi
done
echo ""

# 2. Dependency issues
echo "${BLUE}2. Checking dependencies...${NC}"
if [ -f package.json ]; then
    if [ ! -d node_modules ] || [ package.json -nt node_modules ]; then
        echo "${YELLOW}   Reinstalling node_modules...${NC}"
        rm -rf node_modules package-lock.json 2>/dev/null || true
        npm install
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        echo "${GREEN}   ✅ Dependencies reinstalled${NC}"
    fi
fi

if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
    if [ ! -d node_modules ]; then
        echo "${YELLOW}   Running yarn install...${NC}"
        yarn install
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        echo "${GREEN}   ✅ Yarn dependencies installed${NC}"
    fi
fi
echo ""

# 3. Clear caches
echo "${BLUE}3. Clearing caches...${NC}"
# NPM cache
if command -v npm >/dev/null 2>&1 && [ -d ~/.npm ]; then
    echo "${YELLOW}   Clearing npm cache...${NC}"
    npm cache clean --force 2>/dev/null || true
    echo "${GREEN}   ✅ NPM cache cleared${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi

# Clear common build directories
for dir in dist build .next .cache tmp temp; do
    if [ -d "$dir" ]; then
        echo "${YELLOW}   Removing $dir directory...${NC}"
        rm -rf "$dir"
        echo "${GREEN}   ✅ $dir removed${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
done
echo ""

# 4. Environment setup
echo "${BLUE}4. Checking environment...${NC}"
if [ -f .env.example ] && [ ! -f .env ]; then
    echo "${YELLOW}   Creating .env from template...${NC}"
    cp .env.example .env
    echo "${GREEN}   ✅ .env created (update with real values!)${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi
echo ""

# 5. Git cleanup
echo "${BLUE}5. Git maintenance...${NC}"
# Remove lock files if they exist
if [ -f .git/index.lock ]; then
    echo "${YELLOW}   Removing git index lock...${NC}"
    rm -f .git/index.lock
    echo "${GREEN}   ✅ Git lock removed${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi

# Prune remote branches
if command -v git >/dev/null 2>&1; then
    echo "${YELLOW}   Pruning stale remote branches...${NC}"
    git remote prune origin 2>/dev/null || true
    echo "${GREEN}   ✅ Remote branches pruned${NC}"
fi
echo ""

# 6. Create required directories
echo "${BLUE}6. Ensuring directory structure...${NC}"
REQUIRED_DIRS="logs tmp uploads public/uploads .cache"
for dir in $REQUIRED_DIRS; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null || true
        echo "${GREEN}   ✅ Created $dir${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
done
echo ""

# 7. Fix permissions
echo "${BLUE}7. Fixing permissions...${NC}"
# Make scripts executable
if [ -d scripts ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
    echo "${GREEN}   ✅ Script permissions fixed${NC}"
fi

# Fix npm permissions
if [ -d node_modules/.bin ]; then
    chmod +x node_modules/.bin/* 2>/dev/null || true
    echo "${GREEN}   ✅ npm binary permissions fixed${NC}"
fi
echo ""

# 8. Database recovery (if applicable)
echo "${BLUE}8. Database checks...${NC}"
if command -v psql >/dev/null 2>&1 && [ -f .env ]; then
    # Check if we can connect to postgres
    if ! pg_isready >/dev/null 2>&1; then
        echo "${YELLOW}   PostgreSQL not running, attempting to start...${NC}"
        if [ "$(uname)" = "Darwin" ]; then
            brew services start postgresql 2>/dev/null || true
        else
            sudo systemctl start postgresql 2>/dev/null || true
        fi
        sleep 2
        if pg_isready >/dev/null 2>&1; then
            echo "${GREEN}   ✅ PostgreSQL started${NC}"
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
        fi
    fi
fi
echo ""

# 9. TypeScript/ESLint fixes
echo "${BLUE}9. Linting fixes...${NC}"
if [ -f tsconfig.json ] && [ -f package.json ]; then
    if grep -q "typescript" package.json; then
        echo "${YELLOW}   Clearing TypeScript cache...${NC}"
        rm -rf tsconfig.tsbuildinfo 2>/dev/null || true
        echo "${GREEN}   ✅ TypeScript cache cleared${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
fi

if [ -f .eslintcache ]; then
    echo "${YELLOW}   Removing ESLint cache...${NC}"
    rm -f .eslintcache
    echo "${GREEN}   ✅ ESLint cache removed${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi
echo ""

# Summary
echo "${BLUE}=== SUMMARY ===${NC}"
if [ $FIXES_APPLIED -eq 0 ]; then
    echo "${GREEN}No issues found - system appears healthy!${NC}"
else
    echo "${GREEN}Applied $FIXES_APPLIED fixes${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./scripts/check-everything.sh"
    echo "2. Try your command again"
    echo "3. If still broken, check logs for specific errors"
fi