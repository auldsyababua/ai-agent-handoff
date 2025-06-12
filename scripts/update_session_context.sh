#!/bin/sh
# update_session_context.sh - Generate current session context for Claude
# This script creates a snapshot of the current development state

set -e

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

# Output file
OUTPUT_FILE="docs/SESSION_CONTEXT.md"

# Create docs directory if it doesn't exist
mkdir -p docs

# Start generating the context file
cat > "$OUTPUT_FILE" << EOF
# Current Session Context
Generated: $(date)

## Recent Activity (last 5 commits)
$(git log --oneline -5 2>/dev/null || echo "No commits yet")

## Modified Files (uncommitted)
$(git status --porcelain 2>/dev/null || echo "Not a git repository")

## Current Branch
$(git branch --show-current 2>/dev/null || echo "Not a git repository")

## Running Services
EOF

# Check for common development servers
if command -v lsof >/dev/null 2>&1; then
    echo "### Active Ports" >> "$OUTPUT_FILE"
    lsof -i -P -n | grep LISTEN | grep -E 'node|python|npm|ruby|java' | awk '{print "- Port " $9 " (" $1 ")"}' >> "$OUTPUT_FILE" 2>/dev/null || echo "No services detected" >> "$OUTPUT_FILE"
else
    echo "lsof not available - cannot detect running services" >> "$OUTPUT_FILE"
fi

# Add TODO status from markdown files
cat >> "$OUTPUT_FILE" << EOF

## Pending TODOs (from docs/)
EOF

# Find unchecked TODOs in markdown files
if [ -d docs ]; then
    grep -n -E '^\s*-\s*\[ \]' docs/*.md 2>/dev/null | head -10 >> "$OUTPUT_FILE" || echo "No pending todos found" >> "$OUTPUT_FILE"
else
    echo "No docs directory found" >> "$OUTPUT_FILE"
fi

# Add environment checks
cat >> "$OUTPUT_FILE" << EOF

## Environment Status
EOF

# Check for common runtime versions
for cmd in node python3 ruby java go rustc; do
    if command -v $cmd >/dev/null 2>&1; then
        version=$($cmd --version 2>&1 | head -1)
        echo "- $cmd: $version" >> "$OUTPUT_FILE"
    fi
done

# Add last error from common log locations
cat >> "$OUTPUT_FILE" << EOF

## Recent Errors
EOF

# Check for error logs
if [ -f npm-debug.log ]; then
    echo "### npm-debug.log (last 5 lines)" >> "$OUTPUT_FILE"
    tail -5 npm-debug.log >> "$OUTPUT_FILE" 2>/dev/null
fi

if [ -d logs ]; then
    echo "### Application logs" >> "$OUTPUT_FILE"
    find logs -name "*.log" -type f -exec sh -c 'echo "File: $1"; tail -5 "$1"' _ {} \; >> "$OUTPUT_FILE" 2>/dev/null || echo "No error logs found" >> "$OUTPUT_FILE"
else
    echo "No logs directory found" >> "$OUTPUT_FILE"
fi

# Add quick navigation section
cat >> "$OUTPUT_FILE" << EOF

## Quick Navigation
- Main documentation: [HANDOFF.md](HANDOFF.md)
- Development log: [dev_log.md](dev_log.md)
- Critical paths: [CRITICAL_PATHS.md](CRITICAL_PATHS.md)
- Agent guidelines: [AGENT_GUIDELINES.md](AGENT_GUIDELINES.md)

## Session Start Checklist
- [ ] Read this SESSION_CONTEXT.md
- [ ] Check git status
- [ ] Review last 3 entries in dev_log.md
- [ ] Run validate_environment.sh if available
- [ ] Check for any failing tests
EOF

printf '%s\n' "${GREEN}Session context updated in $OUTPUT_FILE${NC}"