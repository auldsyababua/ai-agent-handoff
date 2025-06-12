#!/usr/bin/env python3
"""
Dev Log Rotation Script for AI Agent Handoff System

This script:
1. Archives older entries from dev_log.md to prevent context overflow
2. Keeps the most recent N sessions in the main log
3. Creates a summary of archived sessions
4. Updates the current state summary

Usage:
  ./rotate_dev_log.py [--sessions N] [--archive-dir path]

Options:
  --sessions N        Number of recent sessions to keep (default: 10)
  --archive-dir path  Directory for archived logs (default: docs/archive)
"""

import os
import re
import sys
import argparse
import datetime
from pathlib import Path
from collections import defaultdict


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Rotate development log to prevent context overflow.')
    parser.add_argument('--sessions', type=int, default=10,
                        help='Number of recent sessions to keep (default: 10)')
    parser.add_argument('--archive-dir', type=str, default='docs/archive',
                        help='Directory for archived logs (default: docs/archive)')
    parser.add_argument('--dev-log', type=str, default='docs/dev_log.md',
                        help='Path to dev_log.md (default: docs/dev_log.md)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Enable verbose output')
    
    return parser.parse_args()


def read_dev_log(path):
    """Read dev_log.md and parse its structure."""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        return content
    except FileNotFoundError:
        print(f"Error: {path} not found.")
        sys.exit(1)


def extract_sessions(content):
    """Extract individual sessions from dev_log.md."""
    # Find the "Development History" section
    history_match = re.search(r'## Development History\s*\n', content)
    if not history_match:
        print("Error: Could not find 'Development History' section in dev_log.md.")
        sys.exit(1)
    
    # Extract the content after "Development History"
    history_start = history_match.end()
    
    # Find the next section if it exists
    next_section = re.search(r'\n## ', content[history_start:])
    if next_section:
        history_content = content[history_start:history_start + next_section.start()]
    else:
        history_content = content[history_start:]
    
    # Extract individual sessions
    sessions = re.findall(r'### .*?(?=### |\Z)', history_content, re.DOTALL)
    
    return sessions


def extract_current_state(content):
    """Extract the current state summary from dev_log.md."""
    state_match = re.search(r'## Current State Summary\s*\n(.*?)(?=\n## )', content, re.DOTALL)
    if state_match:
        return state_match.group(1).strip()
    return ""


def extract_sections(content):
    """Extract all major sections from dev_log.md."""
    sections = {}
    
    # Match all level 2 headings and their content
    matches = re.finditer(r'## (.*?)\s*\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
    
    for match in matches:
        section_name = match.group(1).strip()
        section_content = match.group(2).strip()
        
        if section_name != "Development History":
            sections[section_name] = section_content
    
    return sections


def create_archive(sessions, archive_dir, args):
    """Archive older sessions to separate files."""
    # Create archive directory if it doesn't exist
    os.makedirs(archive_dir, exist_ok=True)
    
    # Group sessions by date
    grouped_sessions = defaultdict(list)
    
    for session in sessions[args.sessions:]:
        # Extract date from session header
        date_match = re.search(r'### (\d{4}-\d{2}-\d{2})', session)
        if date_match:
            date = date_match.group(1)
            grouped_sessions[date].append(session)
        else:
            # If no date found, use "unknown-date"
            grouped_sessions["unknown-date"].append(session)
    
    # Create archive files
    for date, date_sessions in grouped_sessions.items():
        archive_file = os.path.join(archive_dir, f"dev_log_{date}.md")
        
        # Check if file exists and append to it
        if os.path.exists(archive_file):
            with open(archive_file, 'r', encoding='utf-8') as f:
                existing_content = f.read()
            
            # Check if any of these sessions are already in the file
            new_sessions = []
            for session in date_sessions:
                # Extract commit hash
                commit_match = re.search(r'Commit: ([a-f0-9]+)', session)
                if commit_match:
                    commit_hash = commit_match.group(1)
                    if commit_hash not in existing_content:
                        new_sessions.append(session)
                else:
                    # If no commit hash found, add anyway
                    new_sessions.append(session)
            
            if new_sessions:
                with open(archive_file, 'a', encoding='utf-8') as f:
                    for session in new_sessions:
                        f.write(session.strip() + "\n\n")
                        
                if args.verbose:
                    print(f"Appended {len(new_sessions)} sessions to {archive_file}")
        else:
            # Create a new archive file
            with open(archive_file, 'w', encoding='utf-8') as f:
                f.write(f"# Archived Development Log - {date}\n\n")
                for session in date_sessions:
                    f.write(session.strip() + "\n\n")
            
            if args.verbose:
                print(f"Created archive file {archive_file} with {len(date_sessions)} sessions")
    
    return list(grouped_sessions.keys())


def create_summary(archived_dates, archive_dir, args):
    """Create a summary of archived sessions."""
    if not archived_dates:
        return ""
    
    summary = "\n### Archived Sessions\n\n"
    
    for date in sorted(archived_dates):
        archive_file = os.path.join(archive_dir, f"dev_log_{date}.md")
        rel_path = os.path.relpath(archive_file, os.path.dirname(args.dev_log))
        
        # Count sessions in the archive file
        session_count = 0
        if os.path.exists(archive_file):
            with open(archive_file, 'r', encoding='utf-8') as f:
                content = f.read()
                session_count = len(re.findall(r'### \d{4}-\d{2}-\d{2}', content))
        
        summary += f"- [{date}]({rel_path}) - {session_count} sessions\n"
    
    return summary


def update_dev_log(content, recent_sessions, summary, args):
    """Update dev_log.md with recent sessions and summary."""
    # Extract all sections
    sections = extract_sections(content)
    
    # Find the "Development History" section
    history_match = re.search(r'## Development History\s*\n', content)
    if not history_match:
        print("Error: Could not find 'Development History' section in dev_log.md.")
        sys.exit(1)
    
    # Create the new content
    new_content = "# Development Log\n\n"
    
    # Add all sections except Development History
    for section_name, section_content in sections.items():
        new_content += f"## {section_name}\n\n{section_content}\n\n"
    
    # Add Development History with recent sessions
    new_content += "## Development History\n\n"
    for session in recent_sessions:
        new_content += session.strip() + "\n\n"
    
    # Add archive summary
    if summary:
        new_content += summary
    
    # Write the updated dev_log.md
    with open(args.dev_log, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    if args.verbose:
        print(f"Updated {args.dev_log} with {len(recent_sessions)} recent sessions")


def update_current_state(args):
    """Update the current state summary based on recent sessions."""
    with open(args.dev_log, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract recent sessions
    sessions = extract_sessions(content)
    
    if not sessions:
        return
    
    # Extract information from the most recent session
    latest_session = sessions[0]
    
    # Extract commit hash
    commit_match = re.search(r'Commit: ([a-f0-9]+)', latest_session)
    last_commit = commit_match.group(1) if commit_match else "Unknown"
    
    # Extract "Next" section from the most recent session
    next_match = re.search(r'Next:(.*?)($|\n\n)', latest_session, re.DOTALL)
    next_tasks = next_match.group(1).strip() if next_match else ""
    
    # Extract "Issues" section from recent sessions
    issues = []
    for session in sessions[:3]:  # Look at the 3 most recent sessions
        issues_match = re.search(r'Issues:(.*?)($|Next:|\n\n)', session, re.DOTALL)
        if issues_match:
            issue = issues_match.group(1).strip()
            if issue and issue.lower() not in ("none", "n/a"):
                issues.append(issue)
    
    # Create a new current state
    current_state = f"""
- **Last Stable Commit**: {last_commit}
- **Next Tasks**: {next_tasks}
"""
    
    if issues:
        current_state += "- **Known Issues**:\n"
        for issue in issues:
            current_state += f"  - {issue}\n"
    
    # Update the current state in the file
    state_pattern = r'(## Current State Summary\s*\n).*?(\n## )'
    updated_content = re.sub(state_pattern, f"\\1{current_state}\n\\2", content, flags=re.DOTALL)
    
    with open(args.dev_log, 'w', encoding='utf-8') as f:
        f.write(updated_content)
    
    if args.verbose:
        print(f"Updated current state summary in {args.dev_log}")


def main():
    """Main function."""
    args = parse_arguments()
    
    # Read dev_log.md
    content = read_dev_log(args.dev_log)
    
    # Extract sessions
    sessions = extract_sessions(content)
    
    if args.verbose:
        print(f"Found {len(sessions)} sessions in {args.dev_log}")
    
    # If there are more sessions than we want to keep, archive the older ones
    if len(sessions) > args.sessions:
        # Keep recent sessions
        recent_sessions = sessions[:args.sessions]
        
        # Archive older sessions
        archived_dates = create_archive(sessions, args.archive_dir, args)
        
        # Create summary
        summary = create_summary(archived_dates, args.archive_dir, args)
        
        # Update dev_log.md
        update_dev_log(content, recent_sessions, summary, args)
        
        print(f"Rotated dev_log.md: kept {len(recent_sessions)} recent sessions, archived {len(sessions) - len(recent_sessions)} older sessions")
    else:
        print(f"No rotation needed: {len(sessions)} sessions found, keeping up to {args.sessions}")
    
    # Update current state summary
    update_current_state(args)


if __name__ == "__main__":
    main()