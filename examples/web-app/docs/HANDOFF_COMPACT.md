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
- TaskMaster: Task mgmt web app w/ AI prioritization
- Stack: React, Node/Express, PostgreSQL, Redis
- CWD: `/projects/taskmaster`

## Critical Checks ⚠️
```bash
cat backend/.env         # Check config
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
- DB: PostgreSQL direct (5432) + pgvector extension
- Env: Check `backend/.env`
- API: OpenAI for AI prioritization
- Test: `cd backend && npm test` or `cd frontend && npm test`

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