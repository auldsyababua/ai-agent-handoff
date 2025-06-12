#!/usr/bin/env python3
"""
Project Summary Generator for AI Agent Handoff System

This script:
1. Analyzes a project's structure, commits, and documentation
2. Generates a concise summary for quick agent onboarding
3. Creates a compact TLDR document with critical information

Usage:
  ./summarize_project.py [--output OUTPUT_FILE] [--dir PROJECT_DIR]

Options:
  --output OUTPUT_FILE   Output file (default: docs/PROJECT_SUMMARY.md)
  --dir PROJECT_DIR      Project directory (default: current directory)
  --compact              Generate a compact version for agent consumption
  --verbose              Show detailed output
"""

import os
import re
import sys
import argparse
import subprocess
from pathlib import Path
from datetime import datetime
from collections import defaultdict


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Generate a project summary for AI Agent Handoff')
    parser.add_argument('--output', type=str, default=None,
                        help='Output file (default: docs/PROJECT_SUMMARY.md)')
    parser.add_argument('--dir', type=str, default='.',
                        help='Project directory (default: current directory)')
    parser.add_argument('--compact', action='store_true',
                        help='Generate a compact version for agent consumption')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show detailed output')
    
    return parser.parse_args()


def run_command(command, cwd=None):
    """Run a shell command and return its output."""
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            capture_output=True,
            text=True,
            cwd=cwd
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        if e.stderr:
            print(f"Error: {e.stderr}")
        return ""


def get_git_info(project_dir):
    """Get Git repository information."""
    info = {}
    
    # Check if it's a git repository
    if not os.path.isdir(os.path.join(project_dir, '.git')):
        return {'is_git_repo': False}
    
    info['is_git_repo'] = True
    
    # Get remote URL
    remote_url = run_command('git remote get-url origin 2>/dev/null || echo ""', cwd=project_dir)
    info['remote_url'] = remote_url
    
    # Get current branch
    current_branch = run_command('git rev-parse --abbrev-ref HEAD', cwd=project_dir)
    info['current_branch'] = current_branch
    
    # Get latest commit
    latest_commit = run_command('git log -1 --pretty="%h - %s (%cr)"', cwd=project_dir)
    info['latest_commit'] = latest_commit
    
    # Get active branches
    branches = run_command('git branch --sort=-committerdate | head -5', cwd=project_dir)
    info['recent_branches'] = [b.strip('* ') for b in branches.split('\n') if b.strip()]
    
    # Get recent commits
    recent_commits = run_command('git log --pretty="%h - %s" -10', cwd=project_dir)
    info['recent_commits'] = recent_commits.split('\n') if recent_commits else []
    
    # Get project name from remote URL or directory name
    if remote_url:
        project_name = os.path.basename(remote_url)
        if project_name.endswith('.git'):
            project_name = project_name[:-4]
        info['project_name'] = project_name
    else:
        info['project_name'] = os.path.basename(os.path.abspath(project_dir))
    
    return info


def analyze_directory_structure(project_dir):
    """Analyze the directory structure of the project."""
    structure = {
        'dirs': [],
        'files': [],
        'file_types': defaultdict(int),
        'top_level_dirs': [],
        'doc_files': [],
        'code_stats': defaultdict(int)
    }
    
    # Get top-level directories
    for item in os.listdir(project_dir):
        if item.startswith('.'):
            continue
        
        full_path = os.path.join(project_dir, item)
        if os.path.isdir(full_path):
            structure['top_level_dirs'].append(item)
            
            # Count files by type in this directory
            for root, _, files in os.walk(full_path):
                for file in files:
                    if file.startswith('.'):
                        continue
                    
                    structure['files'].append(os.path.join(root, file))
                    
                    # Get file extension
                    _, ext = os.path.splitext(file)
                    if ext:
                        ext = ext.lower()[1:]  # Remove the dot and lowercase
                        structure['file_types'][ext] += 1
                        
                        # Count lines of code for code files
                        if ext in ['py', 'js', 'jsx', 'ts', 'tsx', 'java', 'c', 'cpp', 'h', 'hpp', 'go', 'rb', 'php']:
                            file_path = os.path.join(root, file)
                            try:
                                with open(file_path, 'r', encoding='utf-8') as f:
                                    line_count = sum(1 for _ in f)
                                    structure['code_stats'][ext] += line_count
                            except:
                                pass
        elif os.path.isfile(full_path):
            structure['files'].append(item)
            
            # Check if it's a documentation file
            if item.lower().endswith(('.md', '.txt', '.rst', '.adoc')):
                structure['doc_files'].append(item)
            
            # Get file extension
            _, ext = os.path.splitext(item)
            if ext:
                ext = ext.lower()[1:]  # Remove the dot and lowercase
                structure['file_types'][ext] += 1
    
    # Calculate total lines of code
    structure['total_loc'] = sum(structure['code_stats'].values())
    
    return structure


def analyze_docs_directory(project_dir):
    """Analyze the docs directory for AI Agent Handoff files."""
    docs_info = {
        'has_handoff': False,
        'has_critical_paths': False,
        'has_agent_guidelines': False,
        'has_dev_log': False,
        'handoff_date': None,
        'dev_log_entries': 0,
        'recent_dev_log': None
    }
    
    docs_dir = os.path.join(project_dir, 'docs')
    if not os.path.isdir(docs_dir):
        return docs_info
    
    # Check for key files
    handoff_path = os.path.join(docs_dir, 'HANDOFF.md')
    if os.path.isfile(handoff_path):
        docs_info['has_handoff'] = True
        docs_info['handoff_date'] = datetime.fromtimestamp(os.path.getmtime(handoff_path))
    
    critical_paths = os.path.join(docs_dir, 'CRITICAL_PATHS.md')
    if os.path.isfile(critical_paths):
        docs_info['has_critical_paths'] = True
    
    agent_guidelines = os.path.join(docs_dir, 'AGENT_GUIDELINES.md')
    if os.path.isfile(agent_guidelines):
        docs_info['has_agent_guidelines'] = True
    
    dev_log = os.path.join(docs_dir, 'dev_log.md')
    if os.path.isfile(dev_log):
        docs_info['has_dev_log'] = True
        
        # Count entries in dev_log.md
        try:
            with open(dev_log, 'r', encoding='utf-8') as f:
                content = f.read()
                entries = re.findall(r'### \d{4}-\d{2}-\d{2}', content)
                docs_info['dev_log_entries'] = len(entries)
                
                # Get the most recent entry
                if entries:
                    first_entry_pos = content.find(entries[0])
                    if first_entry_pos >= 0:
                        next_entry_pos = content.find('### ', first_entry_pos + 4)
                        if next_entry_pos >= 0:
                            docs_info['recent_dev_log'] = content[first_entry_pos:next_entry_pos].strip()
                        else:
                            docs_info['recent_dev_log'] = content[first_entry_pos:].strip()
        except:
            pass
    
    return docs_info


def extract_critical_paths(project_dir):
    """Extract critical paths from CRITICAL_PATHS.md."""
    critical_paths = []
    
    critical_paths_file = os.path.join(project_dir, 'docs', 'CRITICAL_PATHS.md')
    if not os.path.isfile(critical_paths_file):
        return critical_paths
    
    try:
        with open(critical_paths_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Find sections marked with 🔴 (critical)
            critical_matches = re.finditer(r'### 🔴 (.*?)\n\n\*\*Location\*\*: `([^`]*)`', content, re.DOTALL)
            for match in critical_matches:
                name = match.group(1).strip()
                location = match.group(2).strip()
                critical_paths.append({'name': name, 'location': location, 'level': 'critical'})
            
            # Find sections marked with 🟡 (important)
            important_matches = re.finditer(r'### 🟡 (.*?)\n\n\*\*Location\*\*: `([^`]*)`', content, re.DOTALL)
            for match in important_matches:
                name = match.group(1).strip()
                location = match.group(2).strip()
                critical_paths.append({'name': name, 'location': location, 'level': 'important'})
    except:
        pass
    
    return critical_paths


def extract_current_state(project_dir):
    """Extract current state summary from dev_log.md."""
    current_state = {
        'stable_commit': None,
        'working_features': [],
        'in_progress': [],
        'known_issues': [],
        'next_tasks': []
    }
    
    dev_log_file = os.path.join(project_dir, 'docs', 'dev_log.md')
    if not os.path.isfile(dev_log_file):
        return current_state
    
    try:
        with open(dev_log_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Extract current state section
            state_match = re.search(r'## Current State Summary\s*\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
            if not state_match:
                return current_state
            
            state_content = state_match.group(1).strip()
            
            # Extract stable commit
            commit_match = re.search(r'\*\*Last Stable Commit\*\*: ([a-f0-9]+)', state_content)
            if commit_match:
                current_state['stable_commit'] = commit_match.group(1).strip()
            
            # Extract working features
            features_match = re.search(r'\*\*Working Features\*\*: (.*?)(?=\n\*\*|\Z)', state_content, re.DOTALL)
            if features_match:
                features = features_match.group(1).strip()
                if features and features.lower() not in ('none', 'none yet'):
                    for feature in re.split(r'[\n,]', features):
                        feature = feature.strip()
                        if feature and not feature.startswith('**'):
                            current_state['working_features'].append(feature.lstrip('- '))
            
            # Extract in progress
            progress_match = re.search(r'\*\*In Progress\*\*: (.*?)(?=\n\*\*|\Z)', state_content, re.DOTALL)
            if progress_match:
                progress = progress_match.group(1).strip()
                if progress and progress.lower() not in ('none', 'none yet'):
                    for item in re.split(r'[\n,]', progress):
                        item = item.strip()
                        if item and not item.startswith('**'):
                            current_state['in_progress'].append(item.lstrip('- '))
            
            # Extract known issues
            issues_match = re.search(r'\*\*Known Issues\*\*: (.*?)(?=\n\*\*|\Z)', state_content, re.DOTALL)
            if issues_match:
                issues = issues_match.group(1).strip()
                if issues and issues.lower() not in ('none', 'none yet'):
                    for issue in re.split(r'[\n,]', issues):
                        issue = issue.strip()
                        if issue and not issue.startswith('**'):
                            current_state['known_issues'].append(issue.lstrip('- '))
            
            # Extract next tasks
            tasks_match = re.search(r'\*\*Next Tasks\*\*: (.*?)(?=\n\*\*|\Z)', state_content, re.DOTALL)
            if tasks_match:
                tasks = tasks_match.group(1).strip()
                if tasks and tasks.lower() not in ('none', 'none yet'):
                    for task in re.split(r'[\n,]', tasks):
                        task = task.strip()
                        if task and not task.startswith('**'):
                            current_state['next_tasks'].append(task.lstrip('- '))
    except:
        pass
    
    return current_state


def detect_tech_stack(project_dir, structure):
    """Detect the technology stack used in the project."""
    tech_stack = {
        'frontend': [],
        'backend': [],
        'database': [],
        'devops': [],
        'other': []
    }
    
    # Check for package.json (Node.js/JavaScript)
    if os.path.isfile(os.path.join(project_dir, 'package.json')):
        try:
            with open(os.path.join(project_dir, 'package.json'), 'r', encoding='utf-8') as f:
                import json
                package_data = json.load(f)
                
                # Frontend frameworks
                dependencies = {**package_data.get('dependencies', {}), **package_data.get('devDependencies', {})}
                
                if 'react' in dependencies:
                    tech_stack['frontend'].append('React')
                if 'vue' in dependencies:
                    tech_stack['frontend'].append('Vue.js')
                if 'angular' in dependencies or '@angular/core' in dependencies:
                    tech_stack['frontend'].append('Angular')
                if 'next' in dependencies:
                    tech_stack['frontend'].append('Next.js')
                if 'nuxt' in dependencies:
                    tech_stack['frontend'].append('Nuxt.js')
                
                # Backend frameworks
                if 'express' in dependencies:
                    tech_stack['backend'].append('Express.js')
                if 'koa' in dependencies:
                    tech_stack['backend'].append('Koa.js')
                if 'fastify' in dependencies:
                    tech_stack['backend'].append('Fastify')
                if 'nest' in dependencies or '@nestjs/core' in dependencies:
                    tech_stack['backend'].append('NestJS')
                
                # Database
                if 'mongoose' in dependencies or 'mongodb' in dependencies:
                    tech_stack['database'].append('MongoDB')
                if 'sequelize' in dependencies:
                    tech_stack['database'].append('SQL (Sequelize)')
                if 'typeorm' in dependencies:
                    tech_stack['database'].append('SQL (TypeORM)')
                if 'prisma' in dependencies:
                    tech_stack['database'].append('Prisma')
                
                # DevOps
                if 'docker' in dependencies or 'dockerfile' in dependencies:
                    tech_stack['devops'].append('Docker')
                if 'kubernetes' in dependencies:
                    tech_stack['devops'].append('Kubernetes')
                if 'aws-sdk' in dependencies:
                    tech_stack['devops'].append('AWS')
        except:
            pass
    
    # Check for requirements.txt (Python)
    if os.path.isfile(os.path.join(project_dir, 'requirements.txt')):
        tech_stack['backend'].append('Python')
        
        try:
            with open(os.path.join(project_dir, 'requirements.txt'), 'r', encoding='utf-8') as f:
                requirements = f.read().lower()
                
                # Python frameworks
                if 'django' in requirements:
                    tech_stack['backend'].append('Django')
                if 'flask' in requirements:
                    tech_stack['backend'].append('Flask')
                if 'fastapi' in requirements:
                    tech_stack['backend'].append('FastAPI')
                
                # Database
                if 'psycopg2' in requirements or 'psycopg' in requirements:
                    tech_stack['database'].append('PostgreSQL')
                if 'pymysql' in requirements or 'mysqlclient' in requirements:
                    tech_stack['database'].append('MySQL')
                if 'pymongo' in requirements:
                    tech_stack['database'].append('MongoDB')
                if 'sqlalchemy' in requirements:
                    tech_stack['database'].append('SQLAlchemy')
                
                # Other
                if 'pytorch' in requirements or 'torch' in requirements:
                    tech_stack['other'].append('PyTorch')
                if 'tensorflow' in requirements or 'tf' in requirements:
                    tech_stack['other'].append('TensorFlow')
        except:
            pass
    
    # Check for Dockerfile
    if os.path.isfile(os.path.join(project_dir, 'Dockerfile')):
        tech_stack['devops'].append('Docker')
    
    # Check for docker-compose.yml
    if os.path.isfile(os.path.join(project_dir, 'docker-compose.yml')):
        tech_stack['devops'].append('Docker Compose')
    
    # Check for .github/workflows directory (GitHub Actions)
    if os.path.isdir(os.path.join(project_dir, '.github', 'workflows')):
        tech_stack['devops'].append('GitHub Actions')
    
    # Infer from file extensions
    if structure['file_types'].get('jsx', 0) > 0 or structure['file_types'].get('tsx', 0) > 0:
        if 'React' not in tech_stack['frontend']:
            tech_stack['frontend'].append('React')
    
    if structure['file_types'].get('vue', 0) > 0:
        if 'Vue.js' not in tech_stack['frontend']:
            tech_stack['frontend'].append('Vue.js')
    
    if structure['file_types'].get('py', 0) > 0:
        if 'Python' not in tech_stack['backend']:
            tech_stack['backend'].append('Python')
    
    if structure['file_types'].get('rb', 0) > 0:
        tech_stack['backend'].append('Ruby')
    
    if structure['file_types'].get('go', 0) > 0:
        tech_stack['backend'].append('Go')
    
    if structure['file_types'].get('java', 0) > 0 or structure['file_types'].get('kt', 0) > 0:
        tech_stack['backend'].append('Java/Kotlin')
    
    # Remove duplicates
    for category in tech_stack:
        tech_stack[category] = list(dict.fromkeys(tech_stack[category]))
    
    return tech_stack


def generate_summary(project_dir, git_info, structure, docs_info, critical_paths, current_state, tech_stack, compact=False):
    """Generate a project summary markdown document."""
    if compact:
        return generate_compact_summary(project_dir, git_info, structure, docs_info, critical_paths, current_state, tech_stack)
    
    # Start building the summary
    summary = f"# Project Summary: {git_info.get('project_name', 'Unknown Project')}\n\n"
    summary += f"*Generated on {datetime.now().strftime('%Y-%m-%d %H:%M')}*\n\n"
    
    # Project Overview
    summary += "## Project Overview\n\n"
    
    if git_info.get('is_git_repo', False):
        summary += f"- **Repository**: {git_info.get('remote_url', 'Local repository')}\n"
        summary += f"- **Current Branch**: {git_info.get('current_branch', 'Unknown')}\n"
        summary += f"- **Latest Commit**: {git_info.get('latest_commit', 'None')}\n"
    
    # Project Structure
    summary += "\n## Project Structure\n\n"
    summary += f"- **Top-Level Directories**: {', '.join(sorted(structure['top_level_dirs']))}\n"
    summary += f"- **Total Files**: {len(structure['files'])}\n"
    
    if structure['file_types']:
        summary += "- **File Types**:\n"
        for ext, count in sorted(structure['file_types'].items(), key=lambda x: x[1], reverse=True)[:10]:
            summary += f"  - {ext}: {count} files\n"
    
    if structure['code_stats']:
        summary += f"- **Total Lines of Code**: {structure['total_loc']}\n"
        summary += "- **Code Breakdown**:\n"
        for ext, lines in sorted(structure['code_stats'].items(), key=lambda x: x[1], reverse=True):
            percentage = (lines / structure['total_loc']) * 100 if structure['total_loc'] > 0 else 0
            summary += f"  - {ext}: {lines} lines ({percentage:.1f}%)\n"
    
    # Technology Stack
    summary += "\n## Technology Stack\n\n"
    
    if tech_stack['frontend']:
        summary += f"- **Frontend**: {', '.join(tech_stack['frontend'])}\n"
    
    if tech_stack['backend']:
        summary += f"- **Backend**: {', '.join(tech_stack['backend'])}\n"
    
    if tech_stack['database']:
        summary += f"- **Database**: {', '.join(tech_stack['database'])}\n"
    
    if tech_stack['devops']:
        summary += f"- **DevOps**: {', '.join(tech_stack['devops'])}\n"
    
    if tech_stack['other']:
        summary += f"- **Other**: {', '.join(tech_stack['other'])}\n"
    
    # AI Agent Handoff Status
    summary += "\n## AI Agent Handoff Status\n\n"
    
    if docs_info['has_handoff']:
        summary += f"- ✅ **HANDOFF.md** is present (last updated: {docs_info['handoff_date'].strftime('%Y-%m-%d')})\n"
    else:
        summary += "- ❌ **HANDOFF.md** is missing\n"
    
    if docs_info['has_critical_paths']:
        summary += f"- ✅ **CRITICAL_PATHS.md** is present ({len(critical_paths)} critical/important paths identified)\n"
    else:
        summary += "- ❌ **CRITICAL_PATHS.md** is missing\n"
    
    if docs_info['has_agent_guidelines']:
        summary += "- ✅ **AGENT_GUIDELINES.md** is present\n"
    else:
        summary += "- ❌ **AGENT_GUIDELINES.md** is missing\n"
    
    if docs_info['has_dev_log']:
        summary += f"- ✅ **dev_log.md** is present ({docs_info['dev_log_entries']} entries)\n"
    else:
        summary += "- ❌ **dev_log.md** is missing\n"
    
    # Current State
    summary += "\n## Current State\n\n"
    
    if current_state['stable_commit']:
        summary += f"- **Last Stable Commit**: {current_state['stable_commit']}\n"
    
    if current_state['working_features']:
        summary += "- **Working Features**:\n"
        for feature in current_state['working_features']:
            summary += f"  - {feature}\n"
    
    if current_state['in_progress']:
        summary += "- **In Progress**:\n"
        for item in current_state['in_progress']:
            summary += f"  - {item}\n"
    
    if current_state['known_issues']:
        summary += "- **Known Issues**:\n"
        for issue in current_state['known_issues']:
            summary += f"  - {issue}\n"
    
    if current_state['next_tasks']:
        summary += "- **Next Tasks**:\n"
        for task in current_state['next_tasks']:
            summary += f"  - {task}\n"
    
    # Critical Paths
    if critical_paths:
        summary += "\n## Critical Paths\n\n"
        
        # First list critical paths
        critical_only = [path for path in critical_paths if path['level'] == 'critical']
        if critical_only:
            summary += "### 🔴 Critical Components\n\n"
            for path in critical_only:
                summary += f"- **{path['name']}**: `{path['location']}`\n"
            summary += "\n"
        
        # Then list important paths
        important_only = [path for path in critical_paths if path['level'] == 'important']
        if important_only:
            summary += "### 🟡 Important Components\n\n"
            for path in important_only:
                summary += f"- **{path['name']}**: `{path['location']}`\n"
    
    # Git History
    if git_info.get('is_git_repo', False) and git_info.get('recent_commits', []):
        summary += "\n## Recent Git History\n\n"
        summary += "```\n"
        for commit in git_info['recent_commits'][:7]:  # Show only 7 most recent commits
            summary += f"{commit}\n"
        summary += "```\n"
    
    # Recent Dev Log Entry
    if docs_info['recent_dev_log']:
        summary += "\n## Most Recent Development Log Entry\n\n"
        summary += "```\n"
        summary += docs_info['recent_dev_log']
        summary += "\n```\n"
    
    # Recommendations for AI Agents
    summary += "\n## Recommendations for AI Agents\n\n"
    
    if not docs_info['has_handoff']:
        summary += "- 🚨 **Create HANDOFF.md**: This is the entry point for AI agents.\n"
    
    if not docs_info['has_critical_paths']:
        summary += "- 🚨 **Create CRITICAL_PATHS.md**: Document the critical components and code paths.\n"
    
    if not docs_info['has_agent_guidelines']:
        summary += "- 🚨 **Create AGENT_GUIDELINES.md**: Document development workflow and guidelines.\n"
    
    if not docs_info['has_dev_log']:
        summary += "- 🚨 **Create dev_log.md**: Start tracking development history.\n"
    
    summary += "- ✅ **Read docs/HANDOFF.md**: Start here for all project work.\n"
    summary += "- ✅ **Check dev_log.md**: Understand the current development state.\n"
    summary += "- ✅ **Follow git practices**: Commit every 15-20 minutes and update dev_log.md after each commit.\n"
    
    return summary


def generate_compact_summary(project_dir, git_info, structure, docs_info, critical_paths, current_state, tech_stack):
    """Generate a compact project summary for agent consumption."""
    summary = f"# {git_info.get('project_name', 'Project')} - Quick Summary\n\n"
    
    # Core Info
    if git_info.get('is_git_repo', False):
        summary += f"Repo: {git_info.get('remote_url', 'Local')}\n"
        summary += f"Branch: {git_info.get('current_branch', '?')}\n"
        summary += f"Last commit: {git_info.get('latest_commit', '?')}\n\n"
    
    # Tech stack (compact)
    stack_parts = []
    if tech_stack['frontend']:
        stack_parts.append(f"Frontend: {'/'.join(tech_stack['frontend'])}")
    if tech_stack['backend']:
        stack_parts.append(f"Backend: {'/'.join(tech_stack['backend'])}")
    if tech_stack['database']:
        stack_parts.append(f"DB: {'/'.join(tech_stack['database'])}")
    
    summary += "## Stack\n" + " | ".join(stack_parts) + "\n\n"
    
    # Current state
    summary += "## Current State\n"
    
    if current_state['stable_commit']:
        summary += f"Stable: {current_state['stable_commit']}\n"
    
    if current_state['in_progress']:
        summary += "In progress: " + ", ".join(current_state['in_progress']) + "\n"
    
    if current_state['known_issues']:
        summary += "Issues: " + ", ".join(current_state['known_issues']) + "\n"
    
    if current_state['next_tasks']:
        summary += "Next: " + ", ".join(current_state['next_tasks'][:3]) + "\n"
    
    summary += "\n"
    
    # Critical paths (very compact)
    if critical_paths:
        summary += "## Critical Paths\n"
        
        for path in critical_paths:
            if path['level'] == 'critical':
                summary += f"🔴 {path['name']}: `{path['location']}`\n"
        
        for path in critical_paths:
            if path['level'] == 'important':
                summary += f"🟡 {path['name']}: `{path['location']}`\n"
        
        summary += "\n"
    
    # Handoff status
    summary += "## Handoff Status\n"
    summary += "✅ " if docs_info['has_handoff'] else "❌ "
    summary += "HANDOFF.md | "
    summary += "✅ " if docs_info['has_critical_paths'] else "❌ "
    summary += "CRITICAL_PATHS.md | "
    summary += "✅ " if docs_info['has_dev_log'] else "❌ "
    summary += "dev_log.md\n\n"
    
    # Agent instructions
    summary += "## Agent Instructions\n"
    summary += "1. Read docs/HANDOFF.md first\n"
    summary += "2. Check todos via TodoRead\n"
    summary += "3. Commit q15-20min\n"
    summary += "4. Update dev_log.md after each commit\n"
    
    return summary


def main():
    """Main function."""
    args = parse_arguments()
    
    # Set project directory
    project_dir = os.path.abspath(args.dir)
    
    if args.verbose:
        print(f"Analyzing project in {project_dir}...")
    
    # Collect information
    git_info = get_git_info(project_dir)
    structure = analyze_directory_structure(project_dir)
    docs_info = analyze_docs_directory(project_dir)
    critical_paths = extract_critical_paths(project_dir)
    current_state = extract_current_state(project_dir)
    tech_stack = detect_tech_stack(project_dir, structure)
    
    # Generate summary
    summary = generate_summary(
        project_dir, 
        git_info, 
        structure, 
        docs_info, 
        critical_paths, 
        current_state, 
        tech_stack,
        compact=args.compact
    )
    
    # Determine output file
    if args.output:
        output_file = args.output
    else:
        filename = "PROJECT_SUMMARY_COMPACT.md" if args.compact else "PROJECT_SUMMARY.md"
        output_file = os.path.join(project_dir, "docs", filename)
    
    # Ensure the output directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    # Write summary to file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(summary)
    
    if args.verbose:
        print(f"Summary written to {output_file}")
    else:
        print(f"Project summary generated: {output_file}")


if __name__ == "__main__":
    main()