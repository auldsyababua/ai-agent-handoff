#!/bin/bash
# AI Agent Handoff System - Setup Script
# This script initializes the AI Agent Handoff system in a project

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Determine script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
HANDOFF_DIR="$SCRIPT_DIR"

# Print banner
echo -e "${BLUE}"
echo "┌─────────────────────────────────────────┐"
echo "│      AI Agent Handoff System Setup      │"
echo "└─────────────────────────────────────────┘"
echo -e "${NC}"

# Check if running in a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Not inside a git repository.${NC}"
    echo "Please run this script from within a git repository."
    exit 1
fi

# Create directories
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p docs
mkdir -p scripts

# Copy template files
echo -e "${BLUE}Copying template files...${NC}"
cp "$HANDOFF_DIR/templates/HANDOFF.md" docs/HANDOFF.md
cp "$HANDOFF_DIR/templates/AGENT_GUIDELINES.md" docs/AGENT_GUIDELINES.md
cp "$HANDOFF_DIR/templates/CRITICAL_PATHS.md" docs/CRITICAL_PATHS.md
cp "$HANDOFF_DIR/templates/PRD.md" docs/PRD.md
cp "$HANDOFF_DIR/templates/ENVIRONMENT.md" docs/ENVIRONMENT.md
cp "$HANDOFF_DIR/templates/SETUP_CHECKLIST.md" docs/SETUP_CHECKLIST.md

# Initialize dev_log.md if it doesn't exist
if [ ! -f docs/dev_log.md ]; then
    echo -e "${BLUE}Creating initial dev_log.md...${NC}"
    cp "$HANDOFF_DIR/templates/dev_log.md" docs/dev_log.md
    
    # Add initial entry with timestamp
    echo "### $(date "+%Y-%m-%d %H:%M") - Initial Setup" >> docs/dev_log.md
    echo "- Initialized AI Agent Handoff System" >> docs/dev_log.md
    echo "- Created documentation structure" >> docs/dev_log.md
    echo "- Next: Customize templates for project specifics" >> docs/dev_log.md
    echo "" >> docs/dev_log.md
fi

# Copy utility scripts
echo -e "${BLUE}Setting up utility scripts...${NC}"
cp "$HANDOFF_DIR/scripts/compress_docs.py" scripts/
cp "$HANDOFF_DIR/scripts/rotate_dev_log.py" scripts/
cp "$HANDOFF_DIR/scripts/validate_environment.sh" scripts/
chmod +x scripts/*.sh scripts/*.py

# Set up git hooks
echo -e "${BLUE}Setting up git hooks...${NC}"
if [ -d .git/hooks ]; then
    cp "$HANDOFF_DIR/hooks/post-commit" .git/hooks/
    cp "$HANDOFF_DIR/hooks/pre-push" .git/hooks/
    chmod +x .git/hooks/post-commit .git/hooks/pre-push
    echo -e "${GREEN}Git hooks installed.${NC}"
else
    echo -e "${YELLOW}Warning: .git/hooks directory not found. Git hooks not installed.${NC}"
fi

# Create compressed versions
echo -e "${BLUE}Creating compressed document versions...${NC}"
python3 "$HANDOFF_DIR/scripts/compress_docs.py" --input docs/HANDOFF.md --output docs/HANDOFF_COMPACT.md
echo -e "${GREEN}Compressed documents created.${NC}"

# Initial git commit
echo -e "${BLUE}Creating initial commit...${NC}"
git add docs/ scripts/
git commit -m "chore: initialize AI Agent Handoff System" || true

# Final instructions
echo -e "${GREEN}AI Agent Handoff System has been successfully initialized!${NC}"
echo -e "${YELLOW}"
echo "Next steps:"
echo "1. Customize docs/HANDOFF.md for your project"
echo "2. Update docs/CRITICAL_PATHS.md with your architecture details"
echo "3. Complete docs/ENVIRONMENT.md with setup instructions"
echo "4. Run scripts/compress_docs.py after any documentation changes"
echo -e "${NC}"
echo "To get started with a new agent, simply instruct them to:"
echo -e "${BLUE}Read docs/HANDOFF.md${NC}"

exit 0