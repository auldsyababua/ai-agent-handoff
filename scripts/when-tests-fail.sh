#!/bin/sh
# when-tests-fail.sh - Debug and fix test failures
# Usage: ./scripts/when-tests-fail.sh [test-name]
set -e

# Colors (if terminal supports it)
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
else
    GREEN=""
    RED=""
    YELLOW=""
    BLUE=""
    RESET=""
fi

printf '%s\n' "${BLUE}=== TEST FAILURE DEBUGGER ===${RESET}"
printf '%s\n' "Analyzing test environment..."
echo ""

# Check if we have a test runner
TEST_RUNNER=""
if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
    TEST_RUNNER="npm"
elif [ -f "Makefile" ] && grep -q '^test:' Makefile 2>/dev/null; then
    TEST_RUNNER="make"
elif [ -f "pytest.ini" ] || [ -f "setup.cfg" ] || [ -f "pyproject.toml" ]; then
    TEST_RUNNER="pytest"
elif [ -f "go.mod" ]; then
    TEST_RUNNER="go"
fi

# Common test issues and fixes
fix_test_issues() {
    printf '%s\n' "${YELLOW}Checking common test issues...${RESET}"
    
    # 1. Check for missing test dependencies
    if [ "$TEST_RUNNER" = "npm" ]; then
        if [ -f "package.json" ]; then
            # Check for common test dependencies
            if ! grep -q '"jest"' package.json && ! grep -q '"mocha"' package.json && ! grep -q '"vitest"' package.json; then
                printf '%s\n' "${RED}⚠️  No test framework found in package.json${RESET}"
                printf '%s\n' "Consider installing: npm install --save-dev jest"
            fi
        fi
    fi
    
    # 2. Check environment variables
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        printf '%s\n' "${YELLOW}📋 Missing .env file - copying from .env.example${RESET}"
        cp .env.example .env
        printf '%s\n' "${GREEN}✅ Created .env file${RESET}"
    fi
    
    # 3. Check test database
    if [ -f ".env" ]; then
        if grep -q "DATABASE_URL.*test" .env || grep -q "TEST_DATABASE" .env; then
            printf '%s\n' "${BLUE}🗄️  Test database configuration found${RESET}"
        fi
    fi
    
    # 4. Clear test caches
    printf '%s\n' "${YELLOW}🧹 Clearing test caches...${RESET}"
    
    # Jest cache
    if [ -d "node_modules/.cache/jest" ]; then
        rm -rf node_modules/.cache/jest
        printf '%s\n' "  Cleared Jest cache"
    fi
    
    # Pytest cache
    if [ -d ".pytest_cache" ]; then
        rm -rf .pytest_cache
        printf '%s\n' "  Cleared pytest cache"
    fi
    
    # Coverage data
    if [ -d "coverage" ] || [ -f ".coverage" ]; then
        rm -rf coverage .coverage
        printf '%s\n' "  Cleared coverage data"
    fi
}

# Run specific test with debugging
debug_single_test() {
    local test_name="$1"
    
    printf '%s\n' "${BLUE}Running single test with debugging...${RESET}"
    
    case "$TEST_RUNNER" in
        npm)
            # Try different test runners
            if grep -q '"jest"' package.json 2>/dev/null; then
                printf '%s\n' "Using Jest..."
                npm test -- --runInBand --verbose "$test_name" || true
            elif grep -q '"mocha"' package.json 2>/dev/null; then
                printf '%s\n' "Using Mocha..."
                npm test -- --grep "$test_name" || true
            elif grep -q '"vitest"' package.json 2>/dev/null; then
                printf '%s\n' "Using Vitest..."
                npm test -- --run "$test_name" || true
            fi
            ;;
        pytest)
            printf '%s\n' "Using pytest..."
            pytest -xvs -k "$test_name" || true
            ;;
        go)
            printf '%s\n' "Using go test..."
            go test -v -run "$test_name" ./... || true
            ;;
    esac
}

# Check for flaky tests
check_flaky_tests() {
    printf '%s\n' "${YELLOW}Checking for flaky tests...${RESET}"
    
    # Run tests multiple times to detect flakiness
    local failures=0
    local runs=3
    
    for i in $(seq 1 $runs); do
        printf '%s\n' "Test run $i/$runs..."
        
        case "$TEST_RUNNER" in
            npm)
                if ! npm test --silent 2>/dev/null; then
                    failures=$((failures + 1))
                fi
                ;;
            pytest)
                if ! pytest -q 2>/dev/null; then
                    failures=$((failures + 1))
                fi
                ;;
        esac
    done
    
    if [ $failures -gt 0 ] && [ $failures -lt $runs ]; then
        printf '%s\n' "${RED}⚠️  FLAKY TESTS DETECTED${RESET}"
        printf '%s\n' "Tests failed $failures out of $runs times"
        printf '%s\n' "This indicates timing or state issues"
    fi
}

# Main execution
if [ -n "$1" ]; then
    # Specific test requested
    printf '%s\n' "${BLUE}Debugging specific test: $1${RESET}"
    debug_single_test "$1"
else
    # General test debugging
    fix_test_issues
    
    printf '%s\n' ""
    printf '%s\n' "${BLUE}Running all tests with verbose output...${RESET}"
    
    case "$TEST_RUNNER" in
        npm)
            npm test -- --verbose || true
            ;;
        pytest)
            pytest -v || true
            ;;
        go)
            go test -v ./... || true
            ;;
        make)
            make test || true
            ;;
        *)
            printf '%s\n' "${RED}No test runner detected${RESET}"
            printf '%s\n' "Please run tests manually"
            ;;
    esac
fi

# Suggestions
printf '%s\n' ""
printf '%s\n' "${YELLOW}=== TROUBLESHOOTING TIPS ===${RESET}"
printf '%s\n' "1. Check error messages above for specific issues"
printf '%s\n' "2. Ensure all dependencies are installed"
printf '%s\n' "3. Verify .env file has all required variables"
printf '%s\n' "4. Try running a single test first"
printf '%s\n' "5. Check if tests require specific services (DB, Redis, etc.)"
printf '%s\n' ""
printf '%s\n' "${BLUE}Common fixes:${RESET}"
printf '%s\n' "  - Clear node_modules: rm -rf node_modules && npm install"
printf '%s\n' "  - Reset test DB: npm run db:test:reset (if available)"
printf '%s\n' "  - Check disk space: df -h"
printf '%s\n' "  - Increase Node memory: export NODE_OPTIONS='--max-old-space-size=4096'"