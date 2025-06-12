# Agent Handoff - START HERE

## Read These in Order 📚
1. README.md → Project overview
2. PRD.md → Requirements, tech decisions
3. AGENT_GUIDELINES.md → Git practices
4. ENVIRONMENT.md → Dependencies, config
5. CRITICAL_PATHS.md → Architecture
6. dev_log.md → Recent history
7. SETUP_CHECKLIST.md → Cloud status

## Project 📋
- [PROJECT_NAME]: [SHORT_DESCRIPTION]
- Stack: [PRIMARY_TECHNOLOGIES]
- CWD: [WORKING_DIRECTORY]

## Critical Checks ⚠️
```bash
cat .env         # Check config
# Use TodoRead tool now! # MANDATORY
git log --oneline -10    # Recent changes
```

## Before Coding 🚦
1. TodoRead tool → check tasks
2. `git status` → changes
3. `git log --oneline -10` → history
4. dev_log.md → last session

## Workflow 🔄
1. Initial checkpoint:
   ```
   git add . && git commit -m "checkpoint: starting - <task>"
   ```
2. After EACH commit → update dev_log.md:
   - Time + commit hash
   - What+why+issues
3. TodoWrite → track progress

## Common Issues 🛠️
- DB: [DATABASE_CONNECTION_DETAILS]
- Env: Check `.env`
- [SERVICE_CREDENTIALS_NOTES]
- Test: `[TEST_COMMAND]`

## Recovery 🔴
1. Review this doc
2. `git log --oneline -20`
3. Find stable commit in dev_log.md
4. Consider: `git reset --hard <commit>`

## Rules ⭐
- Commit q15-20min
- Update dev_log after EACH commit
- Check todos frequently
- When uncertain → checkpoint

---
FIRST ACTION: TodoRead tool → check current tasks