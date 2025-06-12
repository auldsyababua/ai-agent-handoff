#!/bin/sh
# AI Agent Handoff System - Setup Script
# This script initializes the AI Agent Handoff system in a project

set -e

# Check for bash availability
if [ -n "$BASH_VERSION" ]; then
    # Use bash features if available
    IS_BASH=1
else
    IS_BASH=0
fi

# Colors for output (only if terminal supports it)
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2)
    BLUE=$(tput setaf 4)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    NC=$(tput sgr0)
else
    GREEN=''
    BLUE=''
    YELLOW=''
    RED=''
    NC=''
fi

# Determine script location (POSIX-compliant)
if [ "$IS_BASH" = "1" ]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
else
    # POSIX-compliant method
    SCRIPT_DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
fi
HANDOFF_DIR="$SCRIPT_DIR"

# Print banner
printf '%s\n' "${BLUE}"
echo "┌─────────────────────────────────────────┐"
echo "│      AI Agent Handoff System Setup      │"
echo "└─────────────────────────────────────────┘"
printf '%s\n' "${NC}"

# Check if running in a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf '%s\n' "${RED}Error: Not inside a git repository.${NC}"
    echo "Please run this script from within a git repository."
    exit 1
fi

# Create directories for compression architecture
printf '%s\n' "${BLUE}Creating directory structure...${NC}"
mkdir -p docs scripts .compressed .human/docs .scratch

# Copy template files to human-readable directory
printf '%s\n' "${BLUE}Copying template files...${NC}"
cp "$HANDOFF_DIR/templates/HANDOFF.md" .human/docs/HANDOFF.md
cp "$HANDOFF_DIR/templates/AGENT_GUIDELINES.md" .human/docs/AGENT_GUIDELINES.md
cp "$HANDOFF_DIR/templates/CRITICAL_PATHS.md" .human/docs/CRITICAL_PATHS.md
cp "$HANDOFF_DIR/templates/PRD.md" .human/docs/PRD.md
cp "$HANDOFF_DIR/templates/ENVIRONMENT.md" .human/docs/ENVIRONMENT.md
cp "$HANDOFF_DIR/templates/SETUP_CHECKLIST.md" .human/docs/SETUP_CHECKLIST.md
cp "$HANDOFF_DIR/templates/CLAUDE.md" .human/docs/CLAUDE.md

# Initialize dev_log.md if it doesn't exist
if [ ! -f .human/docs/dev_log.md ]; then
    printf '%s\n' "${BLUE}Creating initial dev_log.md...${NC}"
    cp "$HANDOFF_DIR/templates/dev_log.md" .human/docs/dev_log.md
    
    # Add initial entry with timestamp
    echo "### $(date "+%Y-%m-%d %H:%M") - Initial Setup" >> .human/docs/dev_log.md
    echo "- Initialized AI Agent Handoff System" >> .human/docs/dev_log.md
    echo "- Created documentation structure" >> .human/docs/dev_log.md
    echo "- Next: Customize templates for project specifics" >> .human/docs/dev_log.md
    echo "" >> .human/docs/dev_log.md
fi

# Copy utility scripts including compression tools
printf '%s\n' "${BLUE}Setting up utility scripts...${NC}"
cp "$HANDOFF_DIR/scripts/compress_docs.py" scripts/
cp "$HANDOFF_DIR/scripts/decompress.py" scripts/
cp "$HANDOFF_DIR/scripts/rotate_dev_log.py" scripts/
cp "$HANDOFF_DIR/scripts/validate_environment.sh" scripts/
cp "$HANDOFF_DIR/scripts/update_session_context.sh" scripts/
cp "$HANDOFF_DIR/scripts/init_project_context.py" scripts/
cp "$HANDOFF_DIR/scripts/enforce-compression.sh" scripts/

# Copy defensive scripts
for script in "$HANDOFF_DIR"/scripts/*.sh; do
    if [ -f "$script" ]; then
        cp "$script" scripts/
    fi
done

chmod +x scripts/*.sh scripts/*.py

# Set up git hooks
printf '%s\n' "${BLUE}Setting up git hooks...${NC}"
if [ -d .git/hooks ]; then
    cp "$HANDOFF_DIR/hooks/post-commit" .git/hooks/
    cp "$HANDOFF_DIR/hooks/pre-push" .git/hooks/
    chmod +x .git/hooks/post-commit .git/hooks/pre-push
    printf '%s\n' "${GREEN}Git hooks installed.${NC}"
else
    printf '%s\n' "${YELLOW}Warning: .git/hooks directory not found. Git hooks not installed.${NC}"
fi

# Check for Python 3
if ! command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "${RED}Error: Python 3 is required but not found.${NC}"
    echo "Please install Python 3 to continue."
    exit 1
fi

# Create .scratch workspace
printf '%s\n' "${BLUE}Setting up temporary workspace...${NC}"
cat > .scratch/README.md << 'EOF'
# Temporary Scripts Directory

This directory is for ALL temporary/debugging scripts.
- Put all one-off scripts here
- This directory is gitignored
- Clean periodically with: rm .scratch/*

DO NOT create temporary scripts in the project root!
EOF

# Set up .gitignore for compression architecture
printf '%s\n' "${BLUE}Updating .gitignore...${NC}"
if ! grep -q "# Compression enforcement" .gitignore 2>/dev/null; then
    cat >> .gitignore << 'EOF'

# Compression enforcement
.human/
.compressed/
.scratch/
debug-*
test-*
temp-*
*_COMPACT.md
EOF
fi

# Run initial compression
printf '%s\n' "${BLUE}Creating compressed document versions...${NC}"
if python3 scripts/compress_docs.py; then
    printf '%s\n' "${GREEN}Compressed documents created.${NC}"
else
    printf '%s\n' "${YELLOW}Warning: Initial compression failed. Run manually: python3 scripts/compress_docs.py${NC}"
fi

# Initial git commit
printf '%s\n' "${BLUE}Creating initial commit...${NC}"
git add -A
git commit -m "chore: initialize AI Agent Handoff System with compression" || true

# Run initial session context update
printf '%s\n' "${BLUE}Creating initial session context...${NC}"
if sh scripts/update_session_context.sh; then
    printf '%s\n' "${GREEN}Session context created.${NC}"
fi

# Create initial START_HERE_COMPACT.md
printf '%s\n' "${BLUE}Creating agent entry point...${NC}"
cat > START_HERE_COMPACT.md << 'EOF'
# 🤖 START HERE

## Critical Rules
- ONLY read files ending in _COMPACT.md
- NEVER read files in .human/ directory  
- ALL temporary scripts go in .scratch/
- NEVER create files in project root

## Available Docs
Check docs/ directory - all files are symlinks to compressed versions.

## Defensive Scripts
- ./scripts/check-everything.sh - Run this FIRST
- ./scripts/fix-common.sh - Fixes 90% of issues
- ./scripts/explain-error.sh "error" - Get specific fixes

See docs/HANDOFF.md for full script reference.
EOF

# Final instructions
printf '%s\n' "${GREEN}AI Agent Handoff System initialized with compression architecture!${NC}"
printf '%s\n' "${YELLOW}"
echo "IMPORTANT: This project now uses compressed documentation."
echo ""
echo "For Humans:"
echo "1. Edit docs in: .human/docs/"
echo "2. Run: python3 scripts/init_project_context.py"
echo "3. Customize .human/docs/HANDOFF.md for your project"
echo ""
echo "For AI Agents:"
echo "- Tell them to read: START_HERE_COMPACT.md"
echo "- They'll automatically get compressed versions"
echo ""
echo "Helpful aliases:"
echo "alias claude-start='echo \"Read START_HERE_COMPACT.md\" | pbcopy'"
echo "alias compress-docs='python3 scripts/compress_docs.py'"
echo "alias update-context='sh scripts/update_session_context.sh'"
printf '%s\n' "${NC}"
echo "To enforce compression rules, run:"
printf '%s\n' "${BLUE}sh scripts/enforce-compression.sh${NC}"

exit 0