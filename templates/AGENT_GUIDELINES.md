# Agent Guidelines

This document defines the workflow and practices that all AI agents must follow when working on this project.

## Git Workflow

### 1. Checkpointing

Create checkpoints frequently to maintain a recoverable state:

- **Start of session**: Always create a checkpoint
  ```bash
  git add .
  git commit -m "checkpoint: starting session - <task description>"
  ```

- **Every 15-20 minutes**: Create intermediate checkpoints
  ```bash
  git add .
  git commit -m "checkpoint: <brief description of current state>"
  ```

- **Logical units of work**: Create semantic commits
  ```bash
  git add .
  git commit -m "<type>: <description>"
  ```
  Types: feat, fix, docs, style, refactor, test, chore

### 2. Dev Log Updates

**MANDATORY**: After EVERY commit, update dev_log.md with:

```markdown
### YYYY-MM-DD HH:MM - Commit: <first 7 chars of hash>
- <What was changed>
- <Why it was changed>
- <Any issues encountered>
- <Next steps>
```

Example:
```markdown
### 2025-06-11 14:30 - Commit: a1b2c3d
- Added user authentication endpoint
- Fixed CORS configuration
- User profile fetch still returning 500 error
- Next: Debug profile error, then implement profile update
```

### 3. Todo Management

Maintain todos in a structured format:

- Check todos at the start of each session
- Mark completed items with timestamp
- Add new items as they arise
- Prioritize items (P0, P1, P2)

Example:
```markdown
- [x] 2025-06-10 Setup database schema
- [ ] P0 Implement user authentication
- [ ] P1 Create admin dashboard
```

## Code Quality Standards

### 1. Automated Tests

- Write tests for all new functionality
- Run tests before committing
- Fix failing tests immediately

### 2. Documentation

- Document all functions, classes, and modules
- Update README.md with new features
- Comment complex logic

### 3. Error Handling

- Never ignore exceptions
- Log errors with context
- Provide helpful error messages

## Recovery Procedures

### When Things Go Wrong

1. **Don't panic**: Find the last stable commit
   ```bash
   git log --oneline -20
   ```

2. **Check dev_log.md**: Find the last entry with no reported issues

3. **Create a save point**:
   ```bash
   git add .
   git commit -m "checkpoint: before recovery attempt"
   ```

4. **Revert to stable point**:
   ```bash
   git reset --hard <commit-hash>
   ```

5. **Document the recovery**:
   ```markdown
   ### YYYY-MM-DD HH:MM - Recovery
   - Reverted to commit <hash> due to <reason>
   - Issues encountered: <description>
   - Lost work: <description>
   - Plan to recover: <steps>
   ```

## Documentation Refresh Protocol

Every 10 commits, verify and refresh documentation:

1. Check all file paths referenced in docs still exist
2. Update architecture diagrams if needed
3. Verify environment setup instructions
4. Ensure critical paths are still accurate

## Final Notes

- Be verbose in commit messages and dev log entries
- Better to over-document than under-document
- When in doubt about approach, create a checkpoint
- Leave TODOs for the next agent when stopping mid-task