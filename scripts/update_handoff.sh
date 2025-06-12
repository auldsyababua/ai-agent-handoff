#!/bin/bash
# AI Agent Handoff System - Update Script
# This script updates the AI Agent Handoff system files in your project

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
echo "│     AI Agent Handoff - Update System    │"
echo "└─────────────────────────────────────────┘"
echo -e "${NC}"

# Default paths
AI_HANDOFF_REPO="https://github.com/yourusername/ai-agent-handoff.git"
AI_HANDOFF_DIR="/tmp/ai-agent-handoff-update"
BACKUP_DIR="./ai-handoff-backup-$(date +%Y%m%d%H%M%S)"

# Parse arguments
function show_help {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -r, --repo URL        AI Agent Handoff repository URL"
    echo "  -d, --dir PATH        Temporary directory for updates"
    echo "  -b, --backup PATH     Backup directory"
    echo "  -f, --force           Force update without confirmation"
    echo "  -h, --help            Show this help message"
    echo ""
    exit 1
}

FORCE=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--repo) AI_HANDOFF_REPO="$2"; shift ;;
        -d|--dir) AI_HANDOFF_DIR="$2"; shift ;;
        -b|--backup) BACKUP_DIR="$2"; shift ;;
        -f|--force) FORCE=true ;;
        -h|--help) show_help ;;
        *) echo "Unknown parameter: $1"; show_help ;;
    esac
    shift
done

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Not inside a git repository.${NC}"
    echo "Please run this script from within a git repository."
    exit 1
fi

# Confirm update unless forced
if [ "$FORCE" != "true" ]; then
    echo -e "${YELLOW}Warning: This will update the AI Agent Handoff system files in your project.${NC}"
    echo "A backup of your current files will be created in $BACKUP_DIR."
    echo ""
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Update cancelled.${NC}"
        exit 0
    fi
fi

# Create backup directory
echo -e "${BLUE}Creating backup in $BACKUP_DIR...${NC}"
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/docs"
mkdir -p "$BACKUP_DIR/scripts"
mkdir -p "$BACKUP_DIR/hooks"

# Backup current files
if [ -d "docs" ]; then
    cp -r docs/* "$BACKUP_DIR/docs/" 2>/dev/null || true
fi

if [ -d "scripts" ]; then
    cp -r scripts/* "$BACKUP_DIR/scripts/" 2>/dev/null || true
fi

if [ -d ".git/hooks" ]; then
    cp .git/hooks/post-commit "$BACKUP_DIR/hooks/" 2>/dev/null || true
    cp .git/hooks/pre-push "$BACKUP_DIR/hooks/" 2>/dev/null || true
fi

echo -e "${GREEN}Backup created.${NC}"

# Clone the latest version of the AI Agent Handoff repository
echo -e "${BLUE}Getting latest AI Agent Handoff system...${NC}"
rm -rf "$AI_HANDOFF_DIR"
git clone "$AI_HANDOFF_REPO" "$AI_HANDOFF_DIR"

# Update scripts
echo -e "${BLUE}Updating scripts...${NC}"
mkdir -p scripts
cp "$AI_HANDOFF_DIR/scripts/compress_docs.py" scripts/ 2>/dev/null || echo -e "${YELLOW}Warning: compress_docs.py not found in repo.${NC}"
cp "$AI_HANDOFF_DIR/scripts/rotate_dev_log.py" scripts/ 2>/dev/null || echo -e "${YELLOW}Warning: rotate_dev_log.py not found in repo.${NC}"
cp "$AI_HANDOFF_DIR/scripts/validate_environment.sh" scripts/ 2>/dev/null || echo -e "${YELLOW}Warning: validate_environment.sh not found in repo.${NC}"
cp "$AI_HANDOFF_DIR/scripts/summarize_project.py" scripts/ 2>/dev/null || echo -e "${YELLOW}Warning: summarize_project.py not found in repo.${NC}"
chmod +x scripts/*.sh scripts/*.py 2>/dev/null || true

# Update git hooks
echo -e "${BLUE}Updating git hooks...${NC}"
if [ -d ".git/hooks" ]; then
    cp "$AI_HANDOFF_DIR/hooks/post-commit" .git/hooks/ 2>/dev/null || echo -e "${YELLOW}Warning: post-commit hook not found in repo.${NC}"
    cp "$AI_HANDOFF_DIR/hooks/pre-push" .git/hooks/ 2>/dev/null || echo -e "${YELLOW}Warning: pre-push hook not found in repo.${NC}"
    chmod +x .git/hooks/post-commit .git/hooks/pre-push 2>/dev/null || true
else
    echo -e "${YELLOW}Warning: .git/hooks directory not found. Git hooks not updated.${NC}"
fi

# Update documentation
echo -e "${BLUE}Checking for documentation updates...${NC}"
mkdir -p docs

# Function to check if a file needs to be updated
function should_update_file {
    local src="$1"
    local dest="$2"
    
    # If destination doesn't exist, update it
    if [ ! -f "$dest" ]; then
        return 0
    fi
    
    # If source and destination are different, update it
    if ! diff -q "$src" "$dest" > /dev/null 2>&1; then
        # But only if the destination hasn't been customized
        # We'll consider a file customized if it contains the project name
        if grep -q "\[PROJECT_NAME\]" "$src" && ! grep -q "\[PROJECT_NAME\]" "$dest"; then
            # Source has placeholder but destination has been customized
            return 1
        fi
        return 0
    fi
    
    # Files are identical
    return 1
}

# Update documentation templates
for template in AGENT_GUIDELINES.md COMPRESSION.md ERROR_CODES.md METRICS.md TROUBLESHOOTING.md VOCABULARY.md; do
    if [ -f "$AI_HANDOFF_DIR/docs/$template" ]; then
        if should_update_file "$AI_HANDOFF_DIR/docs/$template" "docs/$template"; then
            echo -e "${BLUE}Updating docs/$template...${NC}"
            cp "$AI_HANDOFF_DIR/docs/$template" "docs/$template"
        else
            echo -e "${GREEN}docs/$template is already up to date or customized.${NC}"
        fi
    fi
done

# For template files, we check if they exist in the templates directory
for template in HANDOFF.md HANDOFF_COMPACT.md PRD.md CRITICAL_PATHS.md ENVIRONMENT.md SETUP_CHECKLIST.md; do
    if [ -f "$AI_HANDOFF_DIR/templates/$template" ]; then
        # Only update if it doesn't exist in the project
        if [ ! -f "docs/$template" ]; then
            echo -e "${BLUE}Adding docs/$template...${NC}"
            cp "$AI_HANDOFF_DIR/templates/$template" "docs/$template"
        else
            echo -e "${GREEN}docs/$template already exists (not updating).${NC}"
        fi
    fi
done

# Clean up
echo -e "${BLUE}Cleaning up...${NC}"
rm -rf "$AI_HANDOFF_DIR"

# Final instructions
echo -e "${GREEN}AI Agent Handoff System has been successfully updated!${NC}"
echo -e "${YELLOW}"
echo "Changes made:"
echo "1. Updated scripts in scripts/ directory"
echo "2. Updated git hooks"
echo "3. Updated documentation templates"
echo ""
echo "A backup of your previous files is in $BACKUP_DIR"
echo -e "${NC}"

exit 0