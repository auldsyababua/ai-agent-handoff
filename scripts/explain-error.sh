#!/bin/sh
# explain-error.sh - Paste an error message and get a solution
# Usage: ./scripts/explain-error.sh "error message"
# Or: ./scripts/explain-error.sh (will prompt for error)

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

# Get error message
if [ $# -eq 0 ]; then
    echo "${BLUE}Paste your error message (Ctrl+D when done):${NC}"
    ERROR_MSG=$(cat)
else
    ERROR_MSG="$*"
fi

# Convert to lowercase for matching
ERROR_LOWER=$(echo "$ERROR_MSG" | tr '[:upper:]' '[:lower:]')

echo ""
echo "${BLUE}=== ERROR ANALYSIS ===${NC}"
echo ""

# Flag to track if we found a match
FOUND_MATCH=false

# Function to print solution
print_solution() {
    FOUND_MATCH=true
    echo "${GREEN}✅ LIKELY CAUSE:${NC} $1"
    echo ""
    echo "${CYAN}🔧 SOLUTION:${NC}"
    echo "$2"
    echo ""
    if [ -n "$3" ]; then
        echo "${YELLOW}📝 PREVENTION:${NC}"
        echo "$3"
        echo ""
    fi
}

# Port already in use
if echo "$ERROR_LOWER" | grep -q "eaddrinuse\|port.*in use\|address already in use\|:.*already in use"; then
    PORT=$(echo "$ERROR_MSG" | grep -oE ':[0-9]{4,5}' | head -1 | tr -d ':')
    print_solution \
        "Port ${PORT:-3000} is already in use by another process" \
        "Run: ./scripts/when-port-blocked.sh ${PORT:-3000}
Or manually:
  lsof -ti:${PORT:-3000} | xargs kill -9" \
        "Always check running processes before starting: ./scripts/check-everything.sh"
fi

# Module not found
if echo "$ERROR_LOWER" | grep -q "cannot find module\|module not found\|cannot resolve"; then
    MODULE=$(echo "$ERROR_MSG" | grep -oE "'[^']+'" | head -1 | tr -d "'")
    print_solution \
        "Missing dependency: ${MODULE}" \
        "1. Run: npm install ${MODULE}
2. If that fails: rm -rf node_modules && npm install
3. Check if it's a devDependency: npm install --save-dev ${MODULE}" \
        "Always run 'npm install' after pulling new code"
fi

# Permission denied
if echo "$ERROR_LOWER" | grep -q "permission denied\|eacces\|eperm"; then
    print_solution \
        "File system permission error" \
        "1. Check file ownership: ls -la
2. Fix npm permissions: sudo chown -R $(whoami) ~/.npm
3. Fix project permissions: sudo chown -R $(whoami) .
4. If npm global: npm config set prefix ~/.npm-global" \
        "Avoid using sudo with npm install"
fi

# Database connection
if echo "$ERROR_LOWER" | grep -q "econnrefused.*5432\|postgres.*connection\|psql:.*could not connect"; then
    print_solution \
        "PostgreSQL is not running or cannot connect" \
        "macOS: brew services start postgresql
Linux: sudo systemctl start postgresql
Docker: docker-compose up -d postgres

Check connection: pg_isready" \
        "Add database startup to your session init scripts"
fi

# Redis connection
if echo "$ERROR_LOWER" | grep -q "econnrefused.*6379\|redis.*connection"; then
    print_solution \
        "Redis is not running or cannot connect" \
        "macOS: brew services start redis
Linux: sudo systemctl start redis
Docker: docker-compose up -d redis

Check connection: redis-cli ping" \
        "Add Redis startup to your session init scripts"
fi

# TypeScript errors
if echo "$ERROR_LOWER" | grep -q "ts[0-9]\{4\}\|typescript\|type.*not assignable\|property.*does not exist"; then
    print_solution \
        "TypeScript compilation error" \
        "1. Clear TS cache: rm -rf tsconfig.tsbuildinfo
2. Restart TS server (in VSCode: Cmd+Shift+P → 'Restart TS Server')
3. Check types: npm run type-check
4. Update types: npm install @types/node @types/react --save-dev" \
        "Keep TypeScript and @types packages in sync"
fi

# Memory errors
if echo "$ERROR_LOWER" | grep -q "heap out of memory\|javascript heap\|allocation failed"; then
    print_solution \
        "JavaScript heap out of memory" \
        "1. Increase memory: export NODE_OPTIONS='--max-old-space-size=4096'
2. Add to package.json script: node --max-old-space-size=4096
3. Check for memory leaks in your code
4. Clear caches: rm -rf .cache dist build" \
        "Monitor memory usage during development"
fi

# Git errors
if echo "$ERROR_LOWER" | grep -q "git.*lock\|unable to create.*lock"; then
    print_solution \
        "Git lock file exists" \
        "rm -f .git/index.lock
rm -f .git/refs/heads/*.lock
rm -f .git/FETCH_HEAD.lock" \
        "Don't interrupt git operations"
fi

# CORS errors
if echo "$ERROR_LOWER" | grep -q "cors\|cross-origin\|access-control-allow"; then
    print_solution \
        "Cross-Origin Resource Sharing (CORS) error" \
        "1. Backend fix: Add CORS headers
2. Dev proxy in package.json:
   \"proxy\": \"http://localhost:8000\"
3. Use CORS package: npm install cors
4. Browser extension for dev only" \
        "Configure CORS properly in production"
fi

# ENV errors
if echo "$ERROR_LOWER" | grep -q "undefined.*env\|environment variable\|env.*not defined"; then
    print_solution \
        "Missing environment variable" \
        "1. Check .env file exists
2. Copy from template: cp .env.example .env
3. Source the file: source .env
4. Restart your development server
5. Check variable names match exactly" \
        "Never commit .env files, use .env.example as template"
fi

# Dependency conflicts
if echo "$ERROR_LOWER" | grep -q "peer dep\|peer dependency\|version mismatch\|cannot resolve dependency"; then
    print_solution \
        "Package dependency conflict" \
        "1. Clear everything: rm -rf node_modules package-lock.json
2. Install fresh: npm install
3. Use --force if needed: npm install --force
4. Check for duplicate packages: npm ls
5. Use resolutions in package.json for yarn" \
        "Keep dependencies up to date regularly"
fi

# Build errors
if echo "$ERROR_LOWER" | grep -q "build failed\|compilation failed\|webpack.*error"; then
    print_solution \
        "Build process failed" \
        "1. Clear build cache: rm -rf .cache dist build
2. Clear node_modules: rm -rf node_modules && npm install
3. Check for syntax errors in recent changes
4. Run linter: npm run lint
5. Check webpack/build config" \
        "Run builds locally before committing"
fi

# Test failures
if echo "$ERROR_LOWER" | grep -q "test.*fail\|jest.*fail\|expected.*received\|assertion.*fail"; then
    print_solution \
        "Test failure" \
        "1. Run single test: npm test -- path/to/test
2. Update snapshots: npm test -- -u
3. Check test environment: NODE_ENV=test
4. Clear test cache: jest --clearCache
5. Run in watch mode: npm test -- --watch" \
        "Run tests before committing code"
fi

# If no specific match found
if [ "$FOUND_MATCH" = false ]; then
    echo "${YELLOW}🤔 No specific solution found for this error.${NC}"
    echo ""
    echo "${BLUE}Try these general fixes:${NC}"
    echo "1. Run: ./scripts/fix-common.sh"
    echo "2. Clear and reinstall: rm -rf node_modules && npm install"
    echo "3. Check recent changes: git diff"
    echo "4. Look for typos in file names or imports"
    echo "5. Restart your development server"
    echo ""
    echo "${CYAN}Search for error online:${NC}"
    # URL encode the error for Google search
    SEARCH_QUERY=$(echo "$ERROR_MSG" | head -1 | sed 's/ /+/g')
    echo "https://www.google.com/search?q=$SEARCH_QUERY"
fi

# Log this error for pattern learning
echo "$ERROR_MSG" >> .claude/error_history.log 2>/dev/null || true