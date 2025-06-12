#!/bin/sh
# check-everything.sh - Complete system state check
# Run this at the start of EVERY session
# Usage: ./scripts/check-everything.sh

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

echo "${BLUE}=== COMPLETE SYSTEM CHECK ===${NC}"
echo "Time: $(date)"
echo ""

# Git State
echo "${BLUE}📁 GIT STATE${NC}"
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'Not in git repo')"
echo "Status:"
git status --short 2>/dev/null || echo "Not a git repository"
echo "Last commit: $(git log -1 --oneline 2>/dev/null || echo 'No commits yet')"
echo ""

# Check for uncommitted changes
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    echo "   Consider: git stash or git commit before starting"
fi
echo ""

# Running Services
echo "${BLUE}🔌 RUNNING SERVICES${NC}"
if command -v lsof >/dev/null 2>&1; then
    lsof -i -P -n | grep LISTEN 2>/dev/null | grep -E 'node|python|ruby|java|npm' || echo "No development services detected"
else
    echo "lsof not available - cannot check services"
fi
echo ""

# Port Status
echo "${BLUE}🌐 COMMON PORTS${NC}"
for port in 3000 3001 4000 5000 5432 6379 8000 8080 9000; do
    if command -v lsof >/dev/null 2>&1; then
        if lsof -ti:$port >/dev/null 2>&1; then
            echo "${RED}❌ Port $port is IN USE${NC}"
        else
            echo "${GREEN}✅ Port $port is free${NC}"
        fi
    fi
done
echo ""

# Dependency Status
echo "${BLUE}📦 DEPENDENCIES${NC}"
if [ -f package.json ]; then
    if [ ! -d node_modules ]; then
        echo "${RED}❌ node_modules missing - run: npm install${NC}"
    elif [ package.json -nt node_modules ]; then
        echo "${YELLOW}⚠️  package.json newer than node_modules - run: npm install${NC}"
    else
        echo "${GREEN}✅ Node dependencies look good${NC}"
    fi
fi

if [ -f requirements.txt ] && command -v python3 >/dev/null 2>&1; then
    if [ ! -d venv ] && [ ! -d .venv ]; then
        echo "${YELLOW}⚠️  No virtual environment found${NC}"
    else
        echo "${GREEN}✅ Python virtual environment found${NC}"
    fi
fi

if [ -f Gemfile ]; then
    if [ ! -f Gemfile.lock ]; then
        echo "${RED}❌ Gemfile.lock missing - run: bundle install${NC}"
    else
        echo "${GREEN}✅ Ruby dependencies look good${NC}"
    fi
fi
echo ""

# Environment Variables
echo "${BLUE}🔐 ENVIRONMENT${NC}"
if [ -f .env ]; then
    echo "${GREEN}✅ .env file exists${NC}"
    # Count variables (without showing values)
    var_count=$(grep -c "=" .env 2>/dev/null || echo "0")
    echo "   Contains $var_count environment variables"
else
    echo "${YELLOW}⚠️  No .env file found${NC}"
fi

if [ -f .env.example ]; then
    echo "   .env.example exists for reference"
fi
echo ""

# Recent Errors
echo "${BLUE}🔍 RECENT ERRORS${NC}"
error_found=false
for log in *.log logs/*.log; do
    if [ -f "$log" ]; then
        recent_errors=$(grep -i "error\|exception\|failed" "$log" 2>/dev/null | tail -3)
        if [ -n "$recent_errors" ]; then
            error_found=true
            echo "From $log:"
            echo "$recent_errors"
            echo ""
        fi
    fi
done

if [ "$error_found" = false ]; then
    echo "${GREEN}✅ No recent errors in log files${NC}"
fi
echo ""

# Quick Actions
echo "${BLUE}🚀 SUGGESTED ACTIONS${NC}"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "1. You have uncommitted changes - consider: git commit -am 'checkpoint'"
fi

if [ -f package.json ] && [ ! -d node_modules ]; then
    echo "2. Missing dependencies - run: npm install"
fi

if command -v lsof >/dev/null 2>&1 && lsof -ti:3000 >/dev/null 2>&1; then
    echo "3. Port 3000 is blocked - run: ./scripts/when-port-blocked.sh 3000"
fi

if [ ! -f .env ] && [ -f .env.example ]; then
    echo "4. Missing .env - run: cp .env.example .env"
fi

echo ""
echo "${GREEN}Check complete. Review any warnings above before proceeding.${NC}"