#!/usr/bin/env python3
"""
Initialize Project Context for AI Agent Handoff System

This script helps gather project-specific information on first run,
creating a customized context section for the HANDOFF.md file.
"""

import os
import sys
from datetime import datetime
from pathlib import Path


def get_multiline_input(prompt):
    """Get multiline input from user (empty line to finish)"""
    print(f"{prompt} (empty line to finish):")
    lines = []
    while True:
        line = input()
        if not line:
            break
        lines.append(line)
    return '\n'.join(lines) if lines else "None specified"


def init_project_context():
    """Interactive questionnaire to gather project context"""
    
    print("\n🚀 AI Agent Handoff - Project Context Initialization")
    print("=" * 50)
    print("This will help Claude understand your project better.")
    print("Please answer the following questions:\n")
    
    context = {}
    
    # Basic project info
    project_name = input("Project name: ").strip() or "Unnamed Project"
    context['project_name'] = project_name
    
    # External services
    print("\n1. External Services/APIs")
    print("   Examples: Stripe API, PostgreSQL, Redis, AWS S3")
    context['external_services'] = input("   > ").strip() or "None"
    
    # Fragile areas
    print("\n2. Fragile Areas")
    print("   What parts of the codebase need special care?")
    print("   Examples: Authentication flow, payment processing, data migrations")
    context['fragile_areas'] = input("   > ").strip() or "None identified yet"
    
    # Test commands
    print("\n3. Testing Commands")
    print("   How do you run tests?")
    print("   Examples: npm test, pytest, cargo test")
    context['test_commands'] = input("   > ").strip() or "No tests configured"
    
    # Build commands
    print("\n4. Build Commands")
    print("   How do you build the project?")
    print("   Examples: npm run build, make, cargo build")
    context['build_commands'] = input("   > ").strip() or "No build step required"
    
    # Lint commands
    print("\n5. Lint/Format Commands")
    print("   How do you lint or format code?")
    print("   Examples: npm run lint, black ., cargo fmt")
    context['lint_commands'] = input("   > ").strip() or "No linting configured"
    
    # Common ports
    print("\n6. Common Ports")
    print("   What ports does your application use?")
    print("   Examples: 3000 (frontend), 8000 (backend), 5432 (postgres)")
    context['common_ports'] = input("   > ").strip() or "Default ports"
    
    # Project conventions
    print("\n7. Project Conventions")
    print("   Any coding style or conventions?")
    print("   Examples: Use async/await not promises, REST not GraphQL")
    context['conventions'] = input("   > ").strip() or "Standard conventions"
    
    # Common issues
    print("\n8. Common Issues")
    print("   What typically breaks or causes problems?")
    print("   Examples: Port conflicts, auth tokens expiring, cache invalidation")
    context['common_issues'] = input("   > ").strip() or "None documented yet"
    
    # Recovery procedures
    print("\n9. Recovery Procedures")
    recovery = get_multiline_input("   Common fixes for when things break")
    context['recovery_procedures'] = recovery
    
    # Environment variables
    print("\n10. Critical Environment Variables")
    print("    Which env vars are required?")
    print("    Examples: DATABASE_URL, API_KEY, NODE_ENV")
    context['env_vars'] = input("    > ").strip() or "See .env.example"
    
    # Generate the output
    output = generate_context_section(context)
    
    # Show the result
    print("\n" + "=" * 50)
    print("Generated Project Context Section:")
    print("=" * 50)
    print(output)
    
    # Ask if they want to save it
    save = input("\nSave this to a file? (y/n): ").lower().strip()
    if save == 'y':
        filename = "PROJECT_CONTEXT.md"
        with open(filename, 'w') as f:
            f.write(output)
        print(f"\n✅ Saved to {filename}")
        print("\nNext steps:")
        print("1. Copy this content to the Project-Specific Context section in docs/HANDOFF.md")
        print("2. Run: cat PROJECT_CONTEXT.md >> docs/HANDOFF.md")
        print("3. Edit docs/HANDOFF.md to integrate it properly")
    
    return output


def generate_context_section(context):
    """Generate the markdown section for project context"""
    
    output = f"""
## Project-Specific Context
*Generated on {datetime.now().strftime('%Y-%m-%d %H:%M')}*

### Project: {context['project_name']}

### External Dependencies
- **Services/APIs**: {context['external_services']}
- **Critical Environment Variables**: {context['env_vars']}

### Fragile Areas
{context['fragile_areas']}

### Common Commands
- **Test**: `{context['test_commands']}`
- **Build**: `{context['build_commands']}`
- **Lint**: `{context['lint_commands']}`

### Port Usage
{context['common_ports']}

### Project Conventions
{context['conventions']}

### Common Issues & Solutions
**Known Issues**: {context['common_issues']}

### Recovery Procedures
{context['recovery_procedures']}

### Quick Fixes
- If build fails: Check node_modules, run fresh install
- If tests fail: Check environment variables
- If ports blocked: `lsof -i :{port} | grep LISTEN`
- If DB issues: Check connection string in env vars
"""
    
    return output


def check_existing_context():
    """Check if HANDOFF.md already has project context"""
    handoff_path = Path("docs/HANDOFF.md")
    if handoff_path.exists():
        content = handoff_path.read_text()
        if "## Project-Specific Context" in content:
            # Check if it's empty (just has the template)
            lines = content.split('\n')
            idx = lines.index("## Project-Specific Context")
            # Look at the next few lines
            if idx + 1 < len(lines):
                next_lines = lines[idx+1:idx+5]
                if any("IF THIS SECTION IS EMPTY" in line for line in next_lines):
                    return "empty"
                else:
                    return "exists"
    return "missing"


if __name__ == "__main__":
    # Check if we should run automatically
    status = check_existing_context()
    
    if status == "exists":
        print("ℹ️  Project context already exists in HANDOFF.md")
        override = input("Do you want to create a new one anyway? (y/n): ").lower().strip()
        if override != 'y':
            sys.exit(0)
    elif status == "empty":
        print("📋 Empty project context detected - let's fill it in!")
    
    # Run the initialization
    init_project_context()