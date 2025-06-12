# Claude-Specific Instructions

This document contains specific instructions for Claude AI when working on this project.

## File Modification Rules

1. **Always read before editing** - Use the Read tool before any Edit/Write operations
2. **Use MultiEdit for multiple changes** to the same file
3. **Run linters/tests after changes**:
   - Check if these commands exist first
   - Common commands: `npm run lint`, `npm run typecheck`, `pylint`, `cargo check`
4. **Verify file paths exist** before operations

## Context Priorities

When starting a new session:
1. Check SESSION_CONTEXT.md for current state
2. Review last 3 entries in dev_log.md for recent changes  
3. Read HANDOFF.md for project overview
4. Consult CRITICAL_PATHS.md before major architectural changes
5. Use TodoRead tool to check current tasks

## Working with Todo Lists

- Use TodoWrite tool proactively for complex tasks
- Mark todos as in_progress when starting
- Mark as completed immediately when done
- Only one todo should be in_progress at a time

## Git Workflow

1. **Checkpoint frequently** - After each logical unit of work
2. **Commit message format**: 
   ```
   type: brief description
   
   - Detail 1
   - Detail 2
   ```
3. **After commits**: dev_log.md will prompt for details

## Common Patterns

### Before Making Changes
```bash
# Check current state
git status
git diff

# Verify you're on the right branch
git branch --show-current
```

### After Making Changes
```bash
# Run project-specific tests
[TEST_COMMAND]

# Run linters if available
[LINT_COMMAND]

# Create checkpoint
git add .
git commit -m "type: description"
```

## Error Handling

- If a command fails, investigate why before retrying
- Check file permissions if writes fail
- Verify paths are absolute when required
- Always provide error context in responses

## Performance Optimizations

1. **Batch file reads** - Use concurrent tool invocations
2. **Use Glob/Grep** instead of Agent for specific searches
3. **Read specific line ranges** for large files
4. **Avoid reading binary files** unless necessary

## Project-Specific Tools

If this project has specific tools or scripts:
- Check scripts/ directory for utilities
- Run `ls scripts/` to see available tools
- Read script headers for usage

## Session Management

- The session context auto-updates after commits
- Check SESSION_CONTEXT.md when resuming work
- Update todos frequently to track progress
- Leave clear notes in dev_log.md for the next session

## Remember

- You have no awareness of time passing
- Commit on logical boundaries, not time intervals  
- Be explicit about what you're doing and why
- Ask for clarification if requirements are ambiguous
- Preserve existing code style and conventions