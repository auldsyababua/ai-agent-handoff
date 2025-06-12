# Agent Guidelines

This document defines the workflow and practices that all AI agents must follow when working on the TaskMaster project.

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
- **What**: <What was changed>
- **Why**: <Why it was changed>
- **Issues**: <Any issues encountered>
- **Next**: <Next steps>
```

Example:
```markdown
### 2025-06-11 14:30 - Commit: a1b2c3d
- **What**: Added validation to team invitation flow
- **Why**: Prevent invalid email formats from causing errors
- **Issues**: Need to handle domain-specific validation rules
- **Next**: Implement team notification system
```

### 3. Branch Strategy

- **main**: Production-ready code
- **develop**: Integration branch for features
- **feature/xxx**: Feature branches
- **fix/xxx**: Bug fix branches

Always branch from develop for new features:
```bash
git checkout develop
git pull
git checkout -b feature/new-feature-name
```

### 4. Pull Requests

When a feature is complete:
1. Create a pull request to develop
2. Ensure all tests pass
3. Document key changes in the PR description

## Code Quality Standards

### 1. Testing

- **Unit Tests**: Required for all business logic
  ```bash
  npm run test:unit
  ```

- **Integration Tests**: Required for API endpoints
  ```bash
  npm run test:integration
  ```

- **End-to-End Tests**: Required for critical user flows
  ```bash
  npm run test:e2e
  ```

- **Test Coverage**: Maintain >80% coverage
  ```bash
  npm run test:coverage
  ```

### 2. Formatting & Linting

Run these before committing:
```bash
npm run lint
npm run format
```

### 3. TypeScript

- Use proper TypeScript types for all functions
- Avoid `any` type unless absolutely necessary
- Create interfaces for all data structures

Example:
```typescript
interface Task {
  id: string;
  title: string;
  description?: string;
  priority: number;
  dueDate?: Date;
  completed: boolean;
}

function updateTaskPriority(task: Task, priority: number): Task {
  return {
    ...task,
    priority,
  };
}
```

### 4. React Components

- Use functional components with hooks
- Separate business logic from presentation
- Use TypeScript props interfaces

Example:
```tsx
interface TaskItemProps {
  task: Task;
  onComplete: (id: string) => void;
  onPriorityChange: (id: string, priority: number) => void;
}

const TaskItem: React.FC<TaskItemProps> = ({ task, onComplete, onPriorityChange }) => {
  // Component logic
}
```

### 5. API Design

- RESTful endpoints for CRUD operations
- Use DTOs for request/response data
- Consistent error responses

Example:
```typescript
interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: any;
  }
}
```

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
   - **What**: Reverted to commit <hash>
   - **Why**: <reason for recovery>
   - **Issues**: <description of what went wrong>
   - **Next**: <plan to recover lost work or fix issue>
   ```

## Environment Setup

### Local Development

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Set up environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Start development server**:
   ```bash
   npm run dev
   ```

### Database

1. **Create local database**:
   ```bash
   createdb taskmaster_dev
   ```

2. **Run migrations**:
   ```bash
   npm run migrate
   ```

3. **Seed test data**:
   ```bash
   npm run seed
   ```

## Documentation Standards

### Code Documentation

- Add JSDoc comments for all functions
- Document complex logic inline
- Keep comments up to date with code changes

Example:
```typescript
/**
 * Calculates task priority based on due date, user preferences, and AI suggestions
 * 
 * @param task - The task to prioritize
 * @param userPreferences - User's prioritization preferences
 * @param aiSuggestion - Optional AI suggested priority
 * @returns Calculated priority score (1-100)
 */
function calculateTaskPriority(
  task: Task, 
  userPreferences: UserPreferences, 
  aiSuggestion?: number
): number {
  // Implementation
}
```

### Architecture Documentation

- Update CRITICAL_PATHS.md when architecture changes
- Document new dependencies
- Update diagrams when structure changes

## Performance Guidelines

### Frontend

- Use React.memo for expensive components
- Virtualize long lists
- Optimize bundle size
- Lazy load routes

### Backend

- Use appropriate database indices
- Cache expensive operations
- Use connection pooling
- Monitor query performance

## Security Guidelines

- Never store secrets in code
- Always validate user input
- Use parameterized queries
- Set appropriate CORS headers
- Implement rate limiting
- Use HTTPS everywhere

## Final Notes

- Be verbose in commit messages and dev log entries
- Better to over-document than under-document
- When in doubt about approach, create a checkpoint
- Leave TODOs for the next agent when stopping mid-task