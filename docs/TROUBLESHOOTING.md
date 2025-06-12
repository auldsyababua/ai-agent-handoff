# AI Agent Handoff Troubleshooting Guide

This document provides solutions for common issues encountered when using the AI Agent Handoff system.

## Table of Contents

1. [Handoff Failures](#handoff-failures)
2. [Context Window Issues](#context-window-issues)
3. [Development Going "Off the Rails"](#development-going-off-the-rails)
4. [Git and Version Control Problems](#git-and-version-control-problems)
5. [Documentation Issues](#documentation-issues)
6. [Tool Integration Problems](#tool-integration-problems)
7. [Recovery Procedures](#recovery-procedures)

## Handoff Failures

### Symptom: New agent doesn't understand project structure

**Possible Causes:**
- Missing or incomplete HANDOFF.md
- Critical information not in the correct order
- Project-specific terminology not explained

**Solutions:**
1. Ensure HANDOFF.md is up-to-date and complete
2. Use the `summarize_project.py` script to generate a comprehensive overview
3. Verify reading order puts critical context first
4. Add a glossary section for project-specific terms

### Symptom: Agent makes incorrect assumptions about architecture

**Possible Causes:**
- Missing or outdated CRITICAL_PATHS.md
- Architecture diagrams not included
- Critical invariants not documented

**Solutions:**
1. Update CRITICAL_PATHS.md with current architecture
2. Add clear visual indicators for critical components (🔴)
3. Document architectural invariants explicitly
4. Include "why" explanations for critical design decisions

### Symptom: Agent doesn't follow project conventions

**Possible Causes:**
- Missing or incomplete AGENT_GUIDELINES.md
- Conventions not clearly marked as requirements
- Too many guidelines causing overload

**Solutions:**
1. Review and update AGENT_GUIDELINES.md
2. Prioritize guidelines with visual markers (✅ Must, ⚠️ Should, ℹ️ Optional)
3. Provide concrete examples of correct implementation
4. Reduce guideline count to focus on critical practices

## Context Window Issues

### Symptom: Agent runs out of context window during handoff

**Possible Causes:**
- Too much documentation loaded at once
- Inefficient compression
- Redundant information across documents

**Solutions:**
1. Use compressed versions of documents (HANDOFF_COMPACT.md)
2. Implement progressive disclosure (reveal details only when needed)
3. Run `compress_docs.py` with improved settings
4. Remove redundant information across documents
5. Use symbolic links in docs rather than repeating information

### Symptom: Agent forgets critical information during development

**Possible Causes:**
- Critical information buried in long documents
- Information not reinforced during development
- Too much context consumed by non-critical details

**Solutions:**
1. Move critical information to the beginning of documents
2. Use visual indicators for must-remember information
3. Create a "cheat sheet" with only the most critical details
4. Implement periodic reminder mechanism in git hooks

### Symptom: Verbose logs consuming too much context

**Possible Causes:**
- Dev log rotation not implemented
- Too detailed history in dev_log.md
- Inefficient log format

**Solutions:**
1. Run `rotate_dev_log.py` to archive older entries
2. Make log entries more concise with standardized format
3. Use symbols and abbreviations in logs
4. Keep only the most recent N entries in the main log

## Development Going "Off the Rails"

### Symptom: Agent is working on the wrong task

**Possible Causes:**
- Unclear task prioritization
- Missing or outdated todo list
- Ambiguous instructions

**Solutions:**
1. Implement clear todo management with explicit priorities
2. Update current state summary in dev_log.md
3. Create PROJECT_SUMMARY.md with `summarize_project.py`
4. Add explicit "Next Tasks" section to HANDOFF.md

### Symptom: Agent makes breaking changes to critical code

**Possible Causes:**
- Critical paths not clearly marked
- Missing test coverage
- Insufficient explanation of constraints

**Solutions:**
1. Update CRITICAL_PATHS.md with explicit warnings
2. Add more details about "why" for critical components
3. Implement pre-commit hooks that check for changes to critical files
4. Create specific tests for critical invariants

### Symptom: Multiple agents working at cross-purposes

**Possible Causes:**
- Lack of coordination mechanism
- Unclear ownership of components
- Missing centralized task tracking

**Solutions:**
1. Implement explicit handoff records between agents
2. Create OWNERSHIP.md to clarify component responsibilities
3. Use centralized task tracking with clear assignments
4. Add coordination protocol to AGENT_GUIDELINES.md

## Git and Version Control Problems

### Symptom: Missing or infrequent commits

**Possible Causes:**
- Git guidelines not emphasized
- Commit hooks not installed
- Agent unaware of commit expectations

**Solutions:**
1. Verify git hooks are installed correctly
2. Update AGENT_GUIDELINES.md to emphasize commit frequency
3. Add commit reminders to development environment
4. Implement automated commit suggestion after X minutes

### Symptom: Unhelpful commit messages

**Possible Causes:**
- No standardized format for commit messages
- Missing examples of good commit messages
- No validation for commit message format

**Solutions:**
1. Add commit message template to AGENT_GUIDELINES.md
2. Implement commit-msg hook for validation
3. Provide concrete examples of good and bad commit messages
4. Create a semantic commit message format guide

### Symptom: Dev log not updated after commits

**Possible Causes:**
- Post-commit hook not installed or failing
- Unclear dev log update instructions
- Agent unaware of requirement

**Solutions:**
1. Check post-commit hook installation
2. Verify post-commit hook has proper permissions
3. Add explicit dev log update reminder to AGENT_GUIDELINES.md
4. Fix any errors in the post-commit hook script

## Documentation Issues

### Symptom: Documentation becomes outdated quickly

**Possible Causes:**
- No regular documentation refresh process
- No ownership of documentation
- Lack of documentation validation

**Solutions:**
1. Implement documentation refresh protocol (every 10 commits)
2. Add documentation owners for each section
3. Create validation scripts to check documentation accuracy
4. Add documentation freshness timestamps

### Symptom: Critical details missing from documentation

**Possible Causes:**
- Incomplete initial documentation
- Changes not reflected in documentation
- No documentation review process

**Solutions:**
1. Implement comprehensive documentation checklist
2. Create documentation validation script
3. Add documentation update step to development workflow
4. Schedule regular documentation reviews

### Symptom: Documentation inconsistencies

**Possible Causes:**
- Multiple authors with different styles
- No standardized format
- Copy-paste errors

**Solutions:**
1. Create documentation style guide
2. Implement documentation linting
3. Use templates for common documentation types
4. Centralize shared information to avoid duplication

## Tool Integration Problems

### Symptom: Compression script not working

**Possible Causes:**
- Missing Python dependencies
- Script permissions issues
- Path configuration problems

**Solutions:**
1. Verify Python 3.x is installed
2. Check script executable permissions (`chmod +x scripts/*.py`)
3. Install required dependencies
4. Run script with verbose flag for debugging (`--verbose`)

### Symptom: Log rotation not working

**Possible Causes:**
- Configuration issues
- Script errors
- File permission problems

**Solutions:**
1. Check script logs for errors
2. Verify directory permissions
3. Run script manually with debugging flags
4. Update script configuration if needed

### Symptom: Git hooks not triggering

**Possible Causes:**
- Hooks not installed correctly
- Permission issues
- Path problems in hook scripts

**Solutions:**
1. Verify hooks are in `.git/hooks/` directory
2. Check executable permissions (`chmod +x .git/hooks/*`)
3. Test hooks manually
4. Check for errors in hook execution

## Recovery Procedures

### Major Development Derailment

If development has gone seriously off-track:

1. **Identify Last Good State**:
   ```bash
   git log --oneline -20
   cat docs/dev_log.md
   ```
   Look for the last commit marked as stable in dev_log.md

2. **Create Recovery Branch**:
   ```bash
   git checkout -b recovery-$(date +%Y%m%d)
   git add .
   git commit -m "checkpoint: before recovery"
   ```

3. **Reset to Stable Point**:
   ```bash
   git checkout main
   git reset --hard <last-stable-commit>
   ```

4. **Document Recovery**:
   Add to dev_log.md:
   ```markdown
   ### YYYY-MM-DD HH:MM - Recovery
   - Reverted to commit <hash> due to <reason>
   - Issues encountered: <description>
   - Recovery plan: <next steps>
   ```

5. **Analyze Root Cause**:
   - Review what led to the derailment
   - Update documentation to prevent recurrence
   - Add specific warnings or guidelines

### Corrupted Documentation

If documentation becomes corrupted or severely outdated:

1. **Check Backup**:
   Look in docs/archive for previous versions

2. **Restore from Git**:
   ```bash
   git checkout <previous-commit> -- docs/FILENAME.md
   ```

3. **Regenerate Documentation**:
   ```bash
   ./scripts/summarize_project.py
   ./scripts/compress_docs.py --compress-all
   ```

4. **Validate Recovery**:
   - Verify documentation accuracy
   - Check for missing critical information
   - Update as needed

### Context Overflow Emergency

If context window is completely consumed:

1. **Create Minimal HANDOFF.md**:
   Focus only on:
   - Project name and purpose
   - Critical paths
   - Current state
   - Next actions

2. **Run Emergency Log Rotation**:
   ```bash
   ./scripts/rotate_dev_log.py --sessions 3
   ```

3. **Generate Ultra-Compact Documentation**:
   ```bash
   ./scripts/compress_docs.py --input docs/HANDOFF.md --output docs/HANDOFF_EMERGENCY.md --max-compression
   ```

4. **Document the Issue**:
   Add to dev_log.md:
   ```markdown
   ### YYYY-MM-DD HH:MM - Context Emergency
   - Emergency context reduction performed
   - Reason: <description>
   - Actions: Created emergency documentation
   ```

## Contacting Support

If you encounter issues with the AI Agent Handoff system that aren't covered in this guide:

1. Check the [GitHub repository](https://github.com/yourusername/ai-agent-handoff) for updates
2. Review open and closed issues for similar problems
3. Submit a new issue with:
   - Detailed description of the problem
   - Steps to reproduce
   - Relevant logs and configuration
   - Environment information

## Prevention Best Practices

1. **Regular Maintenance**:
   - Run `validate_environment.sh` weekly
   - Refresh documentation every 10 commits
   - Rotate logs when they exceed 10 sessions

2. **Proactive Monitoring**:
   - Watch for warning signs in dev log
   - Track metrics defined in METRICS.md
   - Review handoff success rate

3. **Continuous Improvement**:
   - Update this troubleshooting guide with new solutions
   - Refine documentation based on failure patterns
   - Improve automation to prevent common issues