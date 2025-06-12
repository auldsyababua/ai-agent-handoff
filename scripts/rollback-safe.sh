#!/bin/sh
# rollback-safe.sh - Safely rollback to last known good state
# This helps recover when development goes off track
# Usage: ./scripts/rollback-safe.sh [commit-hash]

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

echo "${BLUE}=== SAFE ROLLBACK TOOL ===${NC}"
echo ""

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Get current status
CURRENT_BRANCH=$(git branch --show-current)
UNCOMMITTED_CHANGES=$(git status --porcelain | wc -l | tr -d ' ')

echo "${BLUE}Current Status:${NC}"
echo "Branch: $CURRENT_BRANCH"
echo "Uncommitted changes: $UNCOMMITTED_CHANGES files"
echo ""

# Save current work
if [ "$UNCOMMITTED_CHANGES" -gt 0 ]; then
    echo "${YELLOW}⚠️  You have uncommitted changes${NC}"
    echo ""
    read -p "How do you want to handle them?
1) Stash (save for later)
2) Commit (create checkpoint)
3) Discard (lose changes)
4) Abort rollback

Choice (1-4): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            echo "${BLUE}Stashing changes...${NC}"
            STASH_MSG="Rollback stash $(date '+%Y-%m-%d %H:%M:%S')"
            git stash push -m "$STASH_MSG"
            echo "${GREEN}✅ Changes stashed: $STASH_MSG${NC}"
            echo "   Restore later with: git stash pop"
            ;;
        2)
            echo "${BLUE}Creating checkpoint commit...${NC}"
            git add -A
            git commit -m "checkpoint: before rollback $(date '+%Y-%m-%d %H:%M:%S')"
            echo "${GREEN}✅ Checkpoint created${NC}"
            ;;
        3)
            echo "${RED}⚠️  Are you sure you want to discard all changes? (y/N)${NC}"
            read -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git reset --hard
                git clean -fd
                echo "${GREEN}✅ Changes discarded${NC}"
            else
                echo "Rollback aborted"
                exit 0
            fi
            ;;
        *)
            echo "Rollback aborted"
            exit 0
            ;;
    esac
    echo ""
fi

# Determine target commit
if [ $# -eq 1 ]; then
    TARGET_COMMIT=$1
else
    # Find last known good commit from dev_log.md
    echo "${BLUE}Looking for last stable commit...${NC}"
    
    if [ -f docs/dev_log.md ]; then
        # Look for "Last Stable Commit" in dev_log
        STABLE_COMMIT=$(grep -i "stable.*commit" docs/dev_log.md | grep -oE '[a-f0-9]{7,}' | head -1)
        
        if [ -n "$STABLE_COMMIT" ]; then
            echo "Found in dev_log: $STABLE_COMMIT"
        fi
    fi
    
    # Show recent commits
    echo ""
    echo "${BLUE}Recent commits:${NC}"
    git log --oneline -10
    echo ""
    
    if [ -n "$STABLE_COMMIT" ]; then
        echo "Suggested stable commit: ${GREEN}$STABLE_COMMIT${NC}"
        read -p "Use this commit? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            TARGET_COMMIT=$STABLE_COMMIT
        else
            read -p "Enter commit hash (or 'HEAD~n' for n commits back): " TARGET_COMMIT
        fi
    else
        read -p "Enter commit hash (or 'HEAD~n' for n commits back): " TARGET_COMMIT
    fi
fi

# Validate target commit
if ! git rev-parse "$TARGET_COMMIT" >/dev/null 2>&1; then
    echo "${RED}Error: Invalid commit reference: $TARGET_COMMIT${NC}"
    exit 1
fi

# Show what will change
echo ""
echo "${BLUE}Changes that will be rolled back:${NC}"
git log --oneline "$TARGET_COMMIT"..HEAD
echo ""
echo "${YELLOW}Files that will be affected:${NC}"
git diff --name-only "$TARGET_COMMIT"..HEAD | head -20
TOTAL_FILES=$(git diff --name-only "$TARGET_COMMIT"..HEAD | wc -l | tr -d ' ')
if [ "$TOTAL_FILES" -gt 20 ]; then
    echo "... and $((TOTAL_FILES - 20)) more files"
fi
echo ""

# Confirm rollback
echo "${RED}⚠️  This will move HEAD to: $(git log -1 --oneline "$TARGET_COMMIT")${NC}"
read -p "Proceed with rollback? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled"
    exit 0
fi

# Perform rollback
echo ""
echo "${BLUE}Performing rollback...${NC}"

# Create a backup branch just in case
BACKUP_BRANCH="backup/$(date +%Y%m%d-%H%M%S)"
git branch "$BACKUP_BRANCH"
echo "${GREEN}✅ Backup branch created: $BACKUP_BRANCH${NC}"

# Reset to target commit
git reset --hard "$TARGET_COMMIT"
echo "${GREEN}✅ Rolled back to: $(git log -1 --oneline)${NC}"

# Clean up
echo ""
echo "${BLUE}Cleaning up...${NC}"
# Remove untracked files
git clean -fd
# Clear caches
rm -rf .cache dist build node_modules/.cache 2>/dev/null || true
echo "${GREEN}✅ Cleanup complete${NC}"

# Post-rollback actions
echo ""
echo "${BLUE}Post-rollback actions:${NC}"
echo "1. ${YELLOW}Reinstalling dependencies...${NC}"
if [ -f package.json ]; then
    npm install
fi

echo ""
echo "${GREEN}=== ROLLBACK COMPLETE ===${NC}"
echo ""
echo "Next steps:"
echo "1. Run: ./scripts/check-everything.sh"
echo "2. Your old work is saved in branch: $BACKUP_BRANCH"
if [ -n "$STASH_MSG" ]; then
    echo "3. Your uncommitted changes are stashed: $STASH_MSG"
    echo "   Restore with: git stash pop"
fi
echo ""
echo "To undo this rollback: git reset --hard $BACKUP_BRANCH"