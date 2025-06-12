#!/bin/sh
# enforce-compression.sh - Set up compression enforcement for AI agents
# This ensures agents only read/write compressed files
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

printf '%s\n' "${BLUE}🔒 Setting up compression enforcement...${RESET}"
echo ""

# 1. Create directory structure
printf '%s\n' "${YELLOW}Creating directory structure...${RESET}"
mkdir -p .compressed docs .human/docs .scratch

# 2. Move any existing uncompressed docs to .human
printf '%s\n' "${YELLOW}Moving existing docs to .human/...${RESET}"
for file in docs/*.md; do
    if [ -f "$file" ]; then
        case "$file" in
            *_COMPACT.md)
                # Move compressed files to .compressed
                printf '%s\n' "  Moving compressed: $file -> .compressed/"
                mv "$file" .compressed/
                ;;
            *)
                # Move uncompressed files to .human
                printf '%s\n' "  Moving human doc: $file -> .human/docs/"
                mv "$file" .human/docs/
                ;;
        esac
    fi
done

# 3. Create symlinks for agent access (compressed files appear as normal names)
printf '%s\n' "${YELLOW}Creating symlinks for agent access...${RESET}"
cd docs
for file in ../.compressed/*_COMPACT.md; do
    if [ -f "$file" ]; then
        base=$(basename "$file" _COMPACT.md)
        # Create symlink without _COMPACT suffix
        ln -sf "$file" "${base}.md"
        printf '%s\n' "  Created symlink: ${base}.md -> $file"
    fi
done
cd ..

# 4. Create .scratch directory with instructions
printf '%s\n' "${YELLOW}Setting up .scratch workspace...${RESET}"
cat > .scratch/README.md << 'EOF'
# Temporary Scripts Directory

This directory is for all temporary/debugging scripts.
- Put ALL one-off scripts here
- This directory is gitignored
- Clean periodically with: rm .scratch/*

Examples:
- debug-auth.js
- test-connection.sh
- check-env.py

DO NOT create temporary scripts in the project root!
EOF

# 5. Update .gitignore
printf '%s\n' "${YELLOW}Updating .gitignore...${RESET}"
# Check if rules already exist to avoid duplicates
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
    printf '%s\n' "${GREEN}✅ Updated .gitignore${RESET}"
else
    printf '%s\n' "${BLUE}ℹ️  .gitignore already configured${RESET}"
fi

# 6. Install git hooks
printf '%s\n' "${YELLOW}Installing git hooks...${RESET}"

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Enforce compression rules and clean workspace

# Check for debug files in root
DEBUG_FILES=$(find . -maxdepth 1 -name "debug-*" -o -name "test-*" -o -name "temp-*" 2>/dev/null | grep -v node_modules || true)

if [ ! -z "$DEBUG_FILES" ]; then
    echo "❌ ERROR: Temporary files found in project root:"
    echo "$DEBUG_FILES"
    echo ""
    echo "Move these to .scratch/ or delete them:"
    echo "  mv debug-* .scratch/"
    echo "  rm temp-*"
    exit 1
fi

# Block uncompressed docs in docs/ (except symlinks)
UNCOMPRESSED=$(find docs -maxdepth 1 -name "*.md" -type f 2>/dev/null | grep -v "_COMPACT\.md" || true)
if [ ! -z "$UNCOMPRESSED" ]; then
    echo "❌ ERROR: Uncompressed files found in docs/:"
    echo "$UNCOMPRESSED"
    echo ""
    echo "Only _COMPACT.md files should be actual files in docs/"
    echo "Run: python3 scripts/compress_docs.py"
    exit 1
fi

# Block .human/ modifications by agents
if git diff --cached --name-only | grep "^\.human/"; then
    echo "❌ ERROR: Agents should never modify .human/ directory"
    echo "These are auto-generated from _COMPACT.md files"
    exit 1
fi

# Auto-run compression/decompression
if [ -f "scripts/compress_docs.py" ]; then
    python3 scripts/compress_docs.py --silent || true
fi

if [ -f "scripts/decompress.py" ]; then
    python3 scripts/decompress.py --silent || true
fi
EOF

chmod +x .git/hooks/pre-commit
printf '%s\n' "${GREEN}✅ Installed pre-commit hook${RESET}"

# Update post-commit hook
if [ -f ".git/hooks/post-commit" ]; then
    # Backup existing
    cp .git/hooks/post-commit .git/hooks/post-commit.backup
fi

cat > .git/hooks/post-commit << 'EOF'
#!/bin/sh
# Auto-update compressed docs and session context

# Update dev log
if [ -f "scripts/rotate_dev_log.py" ]; then
    python3 scripts/rotate_dev_log.py || true
fi

# Compress all docs
if [ -f "scripts/compress_docs.py" ]; then
    python3 scripts/compress_docs.py --silent || true
fi

# Decompress for humans
if [ -f "scripts/decompress.py" ]; then
    python3 scripts/decompress.py --silent || true
fi

# Update session context
if [ -f "scripts/update_session_context.sh" ]; then
    sh scripts/update_session_context.sh || true
fi

# If any compressed files changed, amend the commit
if git diff --name-only | grep -q "_COMPACT.md\|\.human/"; then
    git add -A .compressed/*_COMPACT.md .human/ 2>/dev/null || true
    git commit --amend --no-edit --no-verify 2>/dev/null || true
fi
EOF

chmod +x .git/hooks/post-commit
printf '%s\n' "${GREEN}✅ Updated post-commit hook${RESET}"

# 7. Create initial compressed structure
printf '%s\n' "${YELLOW}Creating initial compressed files...${RESET}"

# Ensure templates exist
if [ ! -d "templates" ]; then
    printf '%s\n' "${RED}⚠️  No templates directory found${RESET}"
else
    # Copy templates to .human if they don't exist
    for template in templates/*.md; do
        if [ -f "$template" ]; then
            base=$(basename "$template")
            if [ ! -f ".human/docs/$base" ]; then
                cp "$template" ".human/docs/$base"
                printf '%s\n' "  Copied template: $base"
            fi
        fi
    done
fi

# 8. Run initial compression
if [ -f "scripts/compress_docs.py" ]; then
    printf '%s\n' "${YELLOW}Running initial compression...${RESET}"
    python3 scripts/compress_docs.py
else
    printf '%s\n' "${RED}⚠️  compress_docs.py not found - skipping initial compression${RESET}"
fi

# 9. Create enforcement notice
cat > docs/COMPRESSION_NOTICE.md << 'EOF'
# ⚠️ COMPRESSION ENFORCEMENT ACTIVE

This directory contains ONLY symlinks to compressed files.

## For AI Agents:
- Read files normally - they're automatically compressed
- Write only _COMPACT.md files to .compressed/
- Use .scratch/ for temporary scripts

## For Humans:
- Edit files in .human/docs/
- They'll be auto-compressed for agents
- Original formatting preserved in .human/

## Directory Structure:
```
docs/           # Symlinks (what agents see)
.compressed/    # Actual compressed files
.human/         # Human-readable versions
.scratch/       # Temporary workspace
```
EOF

printf '%s\n' ""
printf '%s\n' "${GREEN}✅ Compression enforcement active!${RESET}"
printf '%s\n' ""
printf '%s\n' "${BLUE}Rules now enforced:${RESET}"
printf '%s\n' "- Agents read compressed files via symlinks in docs/"
printf '%s\n' "- Human docs auto-generated in .human/"
printf '%s\n' "- Temporary scripts must go in .scratch/"
printf '%s\n' "- Git hooks prevent rule violations"
printf '%s\n' ""
printf '%s\n' "${YELLOW}Next steps:${RESET}"
printf '%s\n' "1. Run: python3 scripts/compress_docs.py"
printf '%s\n' "2. Agents should read: START_HERE_COMPACT.md"
printf '%s\n' "3. Humans can edit: .human/docs/*.md"