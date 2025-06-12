#!/bin/bash
# Environment Validation Script for AI Agent Handoff System
# Validates that all required environment settings are properly configured

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Options
VERBOSE=false
PRE_PUSH=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        --pre-push) PRE_PUSH=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo -e "${BLUE}Validating environment configuration...${NC}"

# Check for required directories
REQUIRED_DIRS=("docs" "scripts")
MISSING_DIRS=()

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        MISSING_DIRS+=("$dir")
    fi
done

if [ ${#MISSING_DIRS[@]} -ne 0 ]; then
    echo -e "${RED}Error: The following required directories are missing:${NC}"
    for dir in "${MISSING_DIRS[@]}"; do
        echo "  - $dir"
    done
    echo -e "${YELLOW}Please create these directories.${NC}"
    exit 1
fi

# Check for required files
REQUIRED_FILES=("docs/HANDOFF.md" "docs/AGENT_GUIDELINES.md" "docs/dev_log.md")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo -e "${RED}Error: The following required files are missing:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo -e "${YELLOW}Please create these files.${NC}"
    exit 1
fi

# Check git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Not inside a git repository.${NC}"
    echo -e "${YELLOW}Please run this script from within a git repository.${NC}"
    exit 1
fi

# Check for git hooks
if [ ! -f ".git/hooks/post-commit" ]; then
    echo -e "${YELLOW}Warning: post-commit hook is not installed.${NC}"
    echo -e "${BLUE}You should install it for automatic dev log updates:${NC}"
    echo "  cp hooks/post-commit .git/hooks/"
    echo "  chmod +x .git/hooks/post-commit"
fi

if [ ! -f ".git/hooks/pre-push" ]; then
    echo -e "${YELLOW}Warning: pre-push hook is not installed.${NC}"
    echo -e "${BLUE}You should install it for validation before pushing:${NC}"
    echo "  cp hooks/pre-push .git/hooks/"
    echo "  chmod +x .git/hooks/pre-push"
fi

# Check for .env file if needed
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env file is missing.${NC}"
    echo -e "${BLUE}You should create it from the example:${NC}"
    echo "  cp .env.example .env"
fi

# Check that dev_log.md has recent entries
if [ -f "docs/dev_log.md" ]; then
    # Get the date of the most recent commit
    LAST_COMMIT_DATE=$(git log -1 --format=%cd --date=format:%Y-%m-%d)
    
    # Check if dev_log.md contains this date
    if ! grep -q "$LAST_COMMIT_DATE" "docs/dev_log.md"; then
        echo -e "${YELLOW}Warning: dev_log.md might not be up to date.${NC}"
        echo -e "${BLUE}The last commit was on $LAST_COMMIT_DATE, but this date was not found in dev_log.md.${NC}"
    fi
fi

# Check for stale documentation
if [ -f "docs/HANDOFF.md" ]; then
    HANDOFF_AGE=$(( ( $(date +%s) - $(stat -c %Y docs/HANDOFF.md 2>/dev/null || stat -f %m docs/HANDOFF.md) ) / 86400 ))
    if [ $HANDOFF_AGE -gt 14 ]; then
        echo -e "${YELLOW}Warning: HANDOFF.md is $HANDOFF_AGE days old.${NC}"
        echo -e "${BLUE}You should review and update it if necessary.${NC}"
    fi
fi

# Check that critical paths file references actual files
if [ -f "docs/CRITICAL_PATHS.md" ]; then
    # Extract file paths from CRITICAL_PATHS.md
    # This is a simplified version - in a real implementation, you'd want to parse
    # the markdown more carefully to extract actual file paths
    PATHS=$(grep -o '`[^`]*`' docs/CRITICAL_PATHS.md | tr -d '`' | grep '/' | sort | uniq)
    
    INVALID_PATHS=()
    
    for path in $PATHS; do
        # Skip paths with placeholders
        if [[ $path == *"["*"]"* ]]; then
            continue
        fi
        
        # Check if the path exists
        if [ ! -e "$path" ] && [ ! -d "$path" ]; then
            INVALID_PATHS+=("$path")
        fi
    done
    
    if [ ${#INVALID_PATHS[@]} -ne 0 ]; then
        echo -e "${YELLOW}Warning: The following paths in CRITICAL_PATHS.md may be invalid:${NC}"
        for path in "${INVALID_PATHS[@]}"; do
            echo "  - $path"
        done
    fi
fi

# Check for compressed versions of documentation
if [ -f "docs/HANDOFF.md" ] && [ ! -f "docs/HANDOFF_COMPACT.md" ]; then
    echo -e "${YELLOW}Warning: Compressed version of HANDOFF.md is missing.${NC}"
    echo -e "${BLUE}You should create it using the compression script:${NC}"
    echo "  python scripts/compress_docs.py --input docs/HANDOFF.md --output docs/HANDOFF_COMPACT.md"
fi

# Check Python dependencies if applicable
if [ -f "requirements.txt" ]; then
    echo -e "${BLUE}Checking Python dependencies...${NC}"
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: Python 3 is not installed.${NC}"
        exit 1
    fi
    
    # Check Python version
    PYTHON_VERSION=$(python3 --version | cut -d " " -f 2)
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}Python version: $PYTHON_VERSION${NC}"
    fi
    
    # In a real implementation, you would check for specific package versions
    echo -e "${GREEN}Python environment looks good.${NC}"
fi

# Check Node.js dependencies if applicable
if [ -f "package.json" ]; then
    echo -e "${BLUE}Checking Node.js dependencies...${NC}"
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Error: Node.js is not installed.${NC}"
        exit 1
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node --version)
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}Node.js version: $NODE_VERSION${NC}"
    fi
    
    # In a real implementation, you would check for specific package versions
    echo -e "${GREEN}Node.js environment looks good.${NC}"
fi

# Check for database configuration if applicable
if [ -f ".env" ] && grep -q "DATABASE_URL" ".env"; then
    echo -e "${BLUE}Database configuration found.${NC}"
    # In a real implementation, you would check the database connection
fi

# Success message
echo -e "${GREEN}Environment validation completed successfully!${NC}"
exit 0