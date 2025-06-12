#!/bin/bash
# AI Agent Handoff System - Project Initialization Script
# This script initializes a new project with the AI Agent Handoff system

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "┌─────────────────────────────────────────┐"
echo "│      AI Agent Handoff - Init Project    │"
echo "└─────────────────────────────────────────┘"
echo -e "${NC}"

# Parse arguments
PROJECT_DIR="."
PROJECT_NAME=""
PROJECT_DESC=""

function show_help {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --directory DIR   Project directory (default: current directory)"
    echo "  -n, --name NAME       Project name"
    echo "  -p, --description DESC Project description"
    echo "  -h, --help            Show this help message"
    echo ""
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--directory) PROJECT_DIR="$2"; shift ;;
        -n|--name) PROJECT_NAME="$2"; shift ;;
        -p|--description) PROJECT_DESC="$2"; shift ;;
        -h|--help) show_help ;;
        *) echo "Unknown parameter: $1"; show_help ;;
    esac
    shift
done

# Validate project directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Directory $PROJECT_DIR does not exist.${NC}"
    exit 1
fi

# Ensure we're in the project directory
cd "$PROJECT_DIR"

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Git repository not initialized. Initializing now...${NC}"
    git init
    echo -e "${GREEN}Git repository initialized.${NC}"
fi

# Get project name if not provided
if [ -z "$PROJECT_NAME" ]; then
    # Try to get from git remote
    if git remote -v &>/dev/null; then
        REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
        if [ ! -z "$REMOTE_URL" ]; then
            PROJECT_NAME=$(basename -s .git "$REMOTE_URL")
        fi
    fi
    
    # If still empty, use directory name
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(pwd)")
    fi
    
    echo -e "${BLUE}Using project name: ${GREEN}$PROJECT_NAME${NC}"
    echo -e "${BLUE}You can change this later in the documentation files.${NC}"
    echo ""
fi

# Create directories
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p docs
mkdir -p scripts
mkdir -p .github/workflows

# Copy template files
echo -e "${BLUE}Setting up documentation...${NC}"

# Function to replace placeholders in a file
function replace_placeholders {
    local file="$1"
    sed -i.bak "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" "$file"
    sed -i.bak "s|\[SHORT_DESCRIPTION\]|$PROJECT_DESC|g" "$file"
    sed -i.bak "s|\[WORKING_DIRECTORY\]|$(pwd)|g" "$file"
    rm -f "$file.bak"
}

# Create and customize HANDOFF.md
if [ -f "$AI_HANDOFF_DIR/templates/HANDOFF.md" ]; then
    cp "$AI_HANDOFF_DIR/templates/HANDOFF.md" docs/HANDOFF.md
    replace_placeholders docs/HANDOFF.md
else
    echo -e "${YELLOW}Warning: Could not find template HANDOFF.md${NC}"
    echo "# $PROJECT_NAME - Agent Handoff Document" > docs/HANDOFF.md
    echo "" >> docs/HANDOFF.md
    echo "This is the master handoff document for AI agents working on $PROJECT_NAME." >> docs/HANDOFF.md
    echo "" >> docs/HANDOFF.md
    echo "## Quick Context" >> docs/HANDOFF.md
    echo "" >> docs/HANDOFF.md
    echo "- **Project**: $PROJECT_NAME - $PROJECT_DESC" >> docs/HANDOFF.md
    echo "- **Working Directory**: $(pwd)" >> docs/HANDOFF.md
fi

# Create and customize other template files
if [ -f "$AI_HANDOFF_DIR/templates/PRD.md" ]; then
    cp "$AI_HANDOFF_DIR/templates/PRD.md" docs/PRD.md
fi

if [ -f "$AI_HANDOFF_DIR/templates/AGENT_GUIDELINES.md" ]; then
    cp "$AI_HANDOFF_DIR/templates/AGENT_GUIDELINES.md" docs/AGENT_GUIDELINES.md
fi

if [ -f "$AI_HANDOFF_DIR/templates/CRITICAL_PATHS.md" ]; then
    cp "$AI_HANDOFF_DIR/templates/CRITICAL_PATHS.md" docs/CRITICAL_PATHS.md
    replace_placeholders docs/CRITICAL_PATHS.md
fi

if [ -f "$AI_HANDOFF_DIR/templates/ENVIRONMENT.md" ]; then
    cp "$AI_HANDOFF_DIR/templates/ENVIRONMENT.md" docs/ENVIRONMENT.md
    replace_placeholders docs/ENVIRONMENT.md
fi

if [ -f "$AI_HANDOFF_DIR/templates/SETUP_CHECKLIST.md" ]; then
    cp "$AI_HANDOFF_DIR/templates/SETUP_CHECKLIST.md" docs/SETUP_CHECKLIST.md
fi

# Initialize dev_log.md
echo -e "${BLUE}Creating initial dev_log.md...${NC}"
cat > docs/dev_log.md << EOF
# Development Log

## Current State Summary

- **Last Stable Commit**: $(git rev-parse --short HEAD 2>/dev/null || echo "None")
- **Working Features**: None yet
- **In Progress**: Initial setup
- **Known Issues**: None yet
- **Next Tasks**: Complete project setup

## Development History

### $(date "+%Y-%m-%d %H:%M") - Initial Setup - Commit: $(git rev-parse --short HEAD 2>/dev/null || echo "None")
- Created project structure with AI Agent Handoff system
- Set up basic documentation framework
- Initialized git repository
- Next: Define project requirements and architecture

EOF

# Copy utility scripts
echo -e "${BLUE}Setting up utility scripts...${NC}"
if [ -f "$AI_HANDOFF_DIR/scripts/compress_docs.py" ]; then
    cp "$AI_HANDOFF_DIR/scripts/compress_docs.py" scripts/
fi

if [ -f "$AI_HANDOFF_DIR/scripts/rotate_dev_log.py" ]; then
    cp "$AI_HANDOFF_DIR/scripts/rotate_dev_log.py" scripts/
fi

if [ -f "$AI_HANDOFF_DIR/scripts/validate_environment.sh" ]; then
    cp "$AI_HANDOFF_DIR/scripts/validate_environment.sh" scripts/
    chmod +x scripts/validate_environment.sh
fi

if [ -f "$AI_HANDOFF_DIR/scripts/update_handoff.sh" ]; then
    cp "$AI_HANDOFF_DIR/scripts/update_handoff.sh" scripts/
    chmod +x scripts/update_handoff.sh
fi

if [ -f "$AI_HANDOFF_DIR/scripts/summarize_project.py" ]; then
    cp "$AI_HANDOFF_DIR/scripts/summarize_project.py" scripts/
fi

# Make scripts executable
chmod +x scripts/*.sh scripts/*.py 2>/dev/null || true

# Set up git hooks
echo -e "${BLUE}Setting up git hooks...${NC}"
if [ -d ".git/hooks" ]; then
    if [ -f "$AI_HANDOFF_DIR/hooks/post-commit" ]; then
        cp "$AI_HANDOFF_DIR/hooks/post-commit" .git/hooks/
        chmod +x .git/hooks/post-commit
    fi
    
    if [ -f "$AI_HANDOFF_DIR/hooks/pre-push" ]; then
        cp "$AI_HANDOFF_DIR/hooks/pre-push" .git/hooks/
        chmod +x .git/hooks/pre-push
    fi
    
    echo -e "${GREEN}Git hooks installed.${NC}"
else
    echo -e "${YELLOW}Warning: .git/hooks directory not found. Git hooks not installed.${NC}"
fi

# Create compressed versions
echo -e "${BLUE}Creating compressed document versions...${NC}"
if [ -f "scripts/compress_docs.py" ]; then
    python3 scripts/compress_docs.py --input docs/HANDOFF.md --output docs/HANDOFF_COMPACT.md
    echo -e "${GREEN}Compressed documents created.${NC}"
else
    echo -e "${YELLOW}Warning: compress_docs.py not found. Skipping compression.${NC}"
    
    # Create a basic compact version
    if [ -f "docs/HANDOFF.md" ]; then
        cp docs/HANDOFF.md docs/HANDOFF_COMPACT.md
    fi
fi

# Initial git commit
echo -e "${BLUE}Creating initial commit...${NC}"
git add docs/ scripts/ .github/ 2>/dev/null || git add docs/ scripts/
git commit -m "chore: initialize AI Agent Handoff System" || true

# Final instructions
echo -e "${GREEN}AI Agent Handoff System has been successfully initialized for $PROJECT_NAME!${NC}"
echo -e "${YELLOW}"
echo "Next steps:"
echo "1. Review and customize docs/HANDOFF.md for your project"
echo "2. Complete docs/CRITICAL_PATHS.md with your architecture details"
echo "3. Update docs/ENVIRONMENT.md with setup instructions"
echo "4. Run scripts/compress_docs.py after any documentation changes"
echo -e "${NC}"
echo "To get started with a new agent, simply instruct them to:"
echo -e "${BLUE}Read docs/HANDOFF.md${NC}"

exit 0