# Agent Handoff Document - START HERE

**This is the master handoff document for AI agents working on this project.**

## Required Reading Order

Before starting ANY work, read these documents in order:

1. **README.md** - Project overview and quick start
2. **PRD.md** - Product requirements and technical decisions
3. **AGENT_GUIDELINES.md** - Git checkpointing and development practices
4. **ENVIRONMENT.md** - System dependencies and configuration
5. **CRITICAL_PATHS.md** - Architecture and critical code paths
6. **dev_log.md** - Recent development history and current state
7. **SETUP_CHECKLIST.md** - Cloud services setup status

## Quick Context

- **Project**: [PROJECT_NAME] - [SHORT_DESCRIPTION]
- **Stack**: [PRIMARY_TECHNOLOGIES]
- **Current Working Directory**: [WORKING_DIRECTORY]

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

## Emergency Recovery

If things go wrong:
1. Check this handoff document
2. Review recent commits: `git log --oneline -20`
3. Find last stable commit in dev_log.md
4. Consider reverting: `git reset --hard <commit>`

## Remember

- **Commit every 15-20 minutes**
- **Update dev_log.md after each commit**
- **Use descriptive commit messages**
- **Check todos frequently**
- **When in doubt, create a checkpoint**

---

**Your first command should be to check the todo list or use the TodoRead tool to see current tasks.**