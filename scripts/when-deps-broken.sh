#!/bin/sh
# when-deps-broken.sh - Fix dependency and module not found errors
# Usage: ./scripts/when-deps-broken.sh [package-name]

set -e

# Colors (if terminal supports it)
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    NC=$(tput sgr0)
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

echo "${BLUE}=== DEPENDENCY REPAIR TOOL ===${NC}"
echo ""

# Detect package manager
if [ -f yarn.lock ]; then
    PKG_MANAGER="yarn"
    INSTALL_CMD="yarn add"
    INSTALL_DEV_CMD="yarn add --dev"
    CLEAN_CMD="yarn cache clean"
elif [ -f pnpm-lock.yaml ]; then
    PKG_MANAGER="pnpm"
    INSTALL_CMD="pnpm add"
    INSTALL_DEV_CMD="pnpm add -D"
    CLEAN_CMD="pnpm store prune"
else
    PKG_MANAGER="npm"
    INSTALL_CMD="npm install"
    INSTALL_DEV_CMD="npm install --save-dev"
    CLEAN_CMD="npm cache clean --force"
fi

echo "${BLUE}Package manager: $PKG_MANAGER${NC}"
echo ""

# If specific package provided
if [ $# -eq 1 ]; then
    PACKAGE=$1
    echo "${BLUE}Attempting to fix: $PACKAGE${NC}"
    echo ""
    
    # Check if it's already in package.json
    if [ -f package.json ]; then
        if grep -q "\"$PACKAGE\"" package.json; then
            echo "${YELLOW}Package $PACKAGE is already in package.json${NC}"
            echo "Reinstalling all dependencies..."
        else
            echo "${YELLOW}Package $PACKAGE not found in package.json${NC}"
            echo ""
            echo "Install as:"
            echo "1) Production dependency"
            echo "2) Dev dependency"
            echo "3) Skip installation"
            read -p "Choice (1-3): " -n 1 -r
            echo ""
            
            case $REPLY in
                1)
                    echo "${BLUE}Installing $PACKAGE...${NC}"
                    $INSTALL_CMD "$PACKAGE"
                    ;;
                2)
                    echo "${BLUE}Installing $PACKAGE as dev dependency...${NC}"
                    $INSTALL_DEV_CMD "$PACKAGE"
                    ;;
                *)
                    echo "Skipping package installation"
                    ;;
            esac
        fi
    fi
else
    # Full dependency repair
    echo "${BLUE}Running full dependency repair...${NC}"
    echo ""
    
    # Step 1: Diagnosis
    echo "${CYAN}Step 1: Diagnosis${NC}"
    if [ ! -d node_modules ]; then
        echo "${RED}❌ node_modules directory missing${NC}"
    elif [ -f package.json ] && [ package.json -nt node_modules ]; then
        echo "${YELLOW}⚠️  package.json is newer than node_modules${NC}"
    else
        echo "${GREEN}✅ Dependencies appear to be installed${NC}"
    fi
    
    # Check for common issues
    if [ -f package-lock.json ] && [ -f yarn.lock ]; then
        echo "${RED}❌ Both package-lock.json and yarn.lock exist!${NC}"
        echo "   This causes conflicts. Remove one."
    fi
    echo ""
    
    # Step 2: Clean
    echo "${CYAN}Step 2: Clean${NC}"
    echo "Remove dependency artifacts? This will delete:"
    echo "- node_modules/"
    echo "- package-lock.json / yarn.lock / pnpm-lock.yaml"
    echo "- Various caches"
    read -p "Proceed? (y/N) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "${YELLOW}Cleaning...${NC}"
        rm -rf node_modules 2>/dev/null || true
        rm -f package-lock.json yarn.lock pnpm-lock.yaml 2>/dev/null || true
        rm -rf .yarn .pnpm-store 2>/dev/null || true
        $CLEAN_CMD 2>/dev/null || true
        echo "${GREEN}✅ Clean complete${NC}"
    fi
    echo ""
    
    # Step 3: Reinstall
    echo "${CYAN}Step 3: Reinstall${NC}"
    if [ -f package.json ]; then
        echo "${BLUE}Installing dependencies with $PKG_MANAGER...${NC}"
        $PKG_MANAGER install
        echo "${GREEN}✅ Dependencies installed${NC}"
    else
        echo "${RED}❌ No package.json found${NC}"
        exit 1
    fi
    echo ""
    
    # Step 4: Verify
    echo "${CYAN}Step 4: Verify${NC}"
    if [ -d node_modules ]; then
        MODULE_COUNT=$(find node_modules -maxdepth 1 -type d | wc -l)
        echo "${GREEN}✅ Installed $MODULE_COUNT modules${NC}"
        
        # Check for peer dependency warnings
        echo ""
        echo "${BLUE}Checking for issues...${NC}"
        if [ "$PKG_MANAGER" = "npm" ]; then
            npm ls >/dev/null 2>&1 || echo "${YELLOW}⚠️  Some peer dependencies may need attention${NC}"
        fi
    fi
fi

# Additional fixes
echo ""
echo "${BLUE}Additional fixes to try:${NC}"
echo ""

# Python
if [ -f requirements.txt ]; then
    echo "${CYAN}Python:${NC}"
    echo "- pip install -r requirements.txt"
    echo "- pip install --upgrade pip"
    echo ""
fi

# Ruby
if [ -f Gemfile ]; then
    echo "${CYAN}Ruby:${NC}"
    echo "- bundle install"
    echo "- gem install bundler"
    echo ""
fi

# Go
if [ -f go.mod ]; then
    echo "${CYAN}Go:${NC}"
    echo "- go mod download"
    echo "- go mod tidy"
    echo ""
fi

# General Node.js tips
if [ -f package.json ]; then
    echo "${CYAN}Node.js troubleshooting:${NC}"
    echo "- Check Node version: node --version"
    echo "- Clear ALL caches: npx clear-npx-cache"
    echo "- Rebuild native modules: npm rebuild"
    echo "- Check for conflicts: npm ls"
    echo "- Use --force flag: npm install --force"
    echo "- Use --legacy-peer-deps: npm install --legacy-peer-deps"
fi

echo ""
echo "${GREEN}Dependency repair complete!${NC}"
echo "If issues persist, try:"
echo "1. ./scripts/explain-error.sh \"your error message\""
echo "2. Check that you're using the correct Node version (check .nvmrc)"
echo "3. Look for typos in import statements"