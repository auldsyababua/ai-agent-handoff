# Agent Handoff Document - START HERE

**This is the master handoff document for AI agents working on this project.**

## Quick Start for Claude
1. Read this file first
2. Check `git status` 
3. Review last 3 entries in dev_log.md
4. Run `./scripts/validate_environment.sh` if available
5. Check SESSION_CONTEXT.md for current state

## Required Reading Order

Before starting ANY work, read these documents in order:

1. **SESSION_CONTEXT.md** - Current session state (auto-generated)
2. **README.md** - Project overview and quick start
3. **PRD.md** - Product requirements and technical decisions
4. **AGENT_GUIDELINES.md** - Git checkpointing and development practices
5. **ENVIRONMENT.md** - System dependencies and configuration
6. **CRITICAL_PATHS.md** - Architecture and critical code paths
7. **dev_log.md** - Recent development history and current state
8. **SETUP_CHECKLIST.md** - Cloud services setup status
9. **CLAUDE.md** - Claude-specific instructions (if exists)

## Quick Context

- **Project**: [PROJECT_NAME] - [SHORT_DESCRIPTION]
- **Stack**: [PRIMARY_TECHNOLOGIES]
- **Current Working Directory**: [WORKING_DIRECTORY]

## Important Terminology

- **MCP**: Model Context Protocol (NOT Minecraft server) - Allows Claude to use external tools
- **URLs**: Never compress or shorten URLs in documentation - they must remain functional
- **Compressed Docs**: Files ending in _COMPACT.md are auto-compressed for token efficiency

## Project-Specific Context
<!-- IF THIS SECTION IS EMPTY: Run python3 scripts/init_project_context.py -->

### First-Time Setup Required
If the above section is empty, ask the user to run:
```bash
python3 scripts/init_project_context.py
```

Or gather this information:
1. What external services/APIs does this project use?
2. Are there any fragile areas I should be careful with?
3. What are the main testing commands?
4. Any project-specific conventions?
5. What breaks most often?

## Critical Files to Check

```bash
# Check environment configuration
cat .env

# Check todo list immediately
# Use TodoRead tool - DO NOT skip this step

# Check recent git history
git log --oneline -10
```

## Before You Start Coding

1. **Read the todo list** using the TodoRead tool or check TODO.md
2. **Check git status**: `git status`
3. **Review recent commits**: `git log --oneline -10`
4. **Identify where we left off** from dev_log.md

## 🛠️ Defensive Toolkit - Run These, Don't Debug

**START EVERY SESSION**: `./scripts/check-everything.sh`

### When Something Goes Wrong, Run the Right Script:

| Problem | Solution Script | What It Does |
|---------|-----------------|--------------|
| **Starting a session** | `./scripts/check-everything.sh` | Full system diagnostic |
| **Before coding** | `./scripts/pre-code-check.sh` | Ensures environment ready |
| **Any error occurs** | `./scripts/fix-common.sh` | Fixes 90% of issues automatically |
| **Specific error message** | `./scripts/explain-error.sh "error"` | Paste error, get solution |
| **Need to undo changes** | `./scripts/rollback-safe.sh` | Safe revert to good state |
| **Port already in use** | `./scripts/when-port-blocked.sh [port]` | Kills blocking process |
| **Module not found** | `./scripts/when-deps-broken.sh` | Reinstalls dependencies |
| **Tests failing** | `./scripts/when-tests-fail.sh` | Debugs test environment |
| **Missing env vars** | `./scripts/when-env-missing.sh` | Creates/fixes .env file |

### Quick Commands for Common Issues:

```bash
# Session management
./scripts/check-everything.sh          # Run this FIRST, always
./scripts/pre-code-check.sh           # Run before starting work

# When things break
./scripts/fix-common.sh               # Try this first for any error
./scripts/explain-error.sh            # When fix-common doesn't work
./scripts/rollback-safe.sh            # When you need to start over

# Specific issues
./scripts/when-port-blocked.sh 3000   # For "port in use" errors
./scripts/when-deps-broken.sh         # For missing modules
./scripts/when-tests-fail.sh          # For test failures
./scripts/when-env-missing.sh         # For environment issues
```

**Important**: You don't need to understand these scripts. Just run them when you hit the matching problem.

## Development Workflow

1. **Start with a git checkpoint**:
   ```bash
   git add .
   git commit -m "checkpoint: starting session - <your task>"
   ```

2. **After EVERY commit**, update dev_log.md with:
   - Timestamp
   - Commit hash
   - What was done
   - Why it was done
   - Any issues encountered

3. **Use the TodoWrite tool or update TODO.md** to track your progress

## Common Issues & Solutions

### Database Connection
- [DATABASE_CONNECTION_DETAILS]
- Check `.env` for credentials

### Service Credentials
- All in `.env`
- [SERVICE_CREDENTIALS_NOTES]

### Testing
```bash
# Run tests
[TEST_COMMAND]
```

## Recovery Procedures

### Common Fixes
- If build fails: `rm -rf node_modules && npm install`
- If DB corrupted: `npm run db:reset` (or project-specific command)
- If port in use: `lsof -i :3000 | grep LISTEN`
- If tests failing: Check environment variables

### Emergency Recovery
If things go wrong:
1. Check this handoff document
2. Review recent commits: `git log --oneline -20`
3. Find last stable commit in dev_log.md
4. Consider reverting: `git reset --hard <commit>`

## Error Patterns to Avoid
- Never use `rm -rf` without confirmation
- Always quote file paths with spaces
- Check if services are running before starting new ones
- Validate environment variables before running commands

## Commit Guidelines
Commit after completing:
- ✅ A working feature (even if small)
- ✅ A bug fix that passes tests
- ✅ A refactoring that maintains functionality
- ✅ Before switching to a different area of code
- ✅ When you've made progress you don't want to lose

NOT based on time, but on logical completion points.

## Remember

- **Update dev_log.md after each commit**
- **Use descriptive commit messages**
- **Check todos frequently**
- **When in doubt, create a checkpoint**
- **Run linters/tests after changes**

---

**Your first command should be to check the todo list or use the TodoRead tool to see current tasks.**