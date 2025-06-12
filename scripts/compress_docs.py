#!/usr/bin/env python3
"""
Document Compression Script for AI Agent Handoff System

This script compresses documentation by:
1. Replacing common words with abbreviations
2. Removing articles (a, an, the)
3. Reducing vowels in longer words
4. Using shorthand symbols

Usage:
  ./compress_docs.py --input <input_file> --output <output_file>
  ./compress_docs.py --compress-all  # Compress all docs in /docs directory
"""

import os
import re
import sys
import argparse
import json
from pathlib import Path


# Common technical vocabulary abbreviations
REPLACEMENTS = {
    # IMPORTANT: Expand MCP to avoid confusion
    "MCP": "Model Context Protocol",
    "mcp": "Model Context Protocol",
    
    # Actions
    "function": "fn",
    "implementation": "impl",
    "parameter": "param",
    "configuration": "config",
    "application": "app",
    "database": "db",
    "authentication": "auth",
    "directory": "dir",
    "repository": "repo",
    "initialize": "init",
    "integration": "integ",
    "development": "dev",
    "production": "prod",
    "environment": "env",
    "documentation": "docs",
    "distribution": "dist",
    "architecture": "arch",
    "argument": "arg",
    "attribute": "attr",
    "background": "bg",
    "certificate": "cert",
    "command": "cmd",
    "communication": "comm",
    "configuration": "config",
    "connection": "conn",
    "constant": "const",
    "definition": "def",
    "dependency": "dep",
    "description": "desc",
    "document": "doc",
    "execution": "exec",
    "extension": "ext",
    "frequency": "freq",
    "generator": "gen",
    "identifier": "id",
    "implementation": "impl",
    "information": "info",
    "initialize": "init",
    "instance": "inst",
    "instruction": "instr",
    "interface": "iface",
    "library": "lib",
    "message": "msg",
    "modification": "mod",
    "notification": "notif",
    "operation": "op",
    "optimization": "opt",
    "organization": "org",
    "package": "pkg",
    "parameter": "param",
    "permission": "perm",
    "process": "proc",
    "production": "prod",
    "property": "prop",
    "reference": "ref",
    "registration": "reg",
    "repository": "repo",
    "request": "req",
    "resource": "res",
    "response": "resp",
    "session": "sess",
    "specification": "spec",
    "statistic": "stat",
    "structure": "struct",
    "synchronization": "sync",
    "system": "sys",
    "temporary": "temp",
    "transaction": "tx",
    "transformation": "transform",
    "utility": "util",
    "validation": "valid",
    "variable": "var",
    "version": "ver",
    
    # Phrases
    "in order to": "to",
    "make sure": "ensure",
    "take a look at": "check",
    "find out": "discover",
    "set up": "setup",
    "due to the fact that": "because",
    "for the purpose of": "for",
    "in the event that": "if",
    "in the process of": "while",
    "on the basis of": "based on",
    "in spite of the fact that": "although",
    "at this point in time": "now",
    
    # Common verbs
    "initialize": "init",
    "configure": "config",
    "execute": "exec",
    "implement": "impl",
}

# Phrases to preserve exactly (no compression)
PRESERVE_PHRASES = [
    # Command line examples
    "```bash",
    "```python",
    "```javascript",
    "```",
    "git commit",
    "git add",
    "git push",
    "git pull",
    "git reset",
    # File paths
    "/Users/",
    "/home/",
    "backend/",
    "frontend/",
    # Code elements
    "function(",
    "def ",
    "class ",
    "import ",
    "from ",
    "require(",
    # Critical sections
    "CRITICAL:",
    "WARNING:",
    "ERROR:",
    "IMPORTANT:"
]

# Words that should never be compressed
NEVER_COMPRESS = [
    # Short words
    "the",
    "and",
    "but",
    "for",
    "not",
    "with",
    "this",
    "that",
    # Technical terms that might be ambiguous
    "git",
    "npm",
    "yarn",
    "node",
    "react",
    "vue",
    "python",
    "java",
    "code",
    "file",
    "test",
    "api",
    "url",
    "json",
    "xml",
    "html",
    "css",
    "js",
    "ts"
]

# Symbol replacements
SYMBOLS = {
    "returns": "→",
    "greater than": ">",
    "less than": "<",
    "equal to": "=",
    "not equal to": "≠",
    "approximately": "≈",
    "and": "&",
    "or": "|",
    "therefore": "∴",
    "because": "∵",
    "for all": "∀",
    "there exists": "∃",
    "element of": "∈",
    "not element of": "∉",
    "subset of": "⊂",
    "infinite": "∞",
    "degrees": "°",
    "square root": "√",
    "check": "✓",
    "important": "❗",
    "warning": "⚠️",
    "error": "🔴",
    "success": "✅",
    "failure": "❌",
    "note": "📝",
    "idea": "💡",
    "question": "❓",
    "time": "⏱️",
    "required": "◉",
    "optional": "○",
}

# URL patterns to never compress
URL_PATTERNS = [
    r'https?://[^\s<>"{}|\\^`\[\]]+',  # HTTP/HTTPS URLs
    r'ftp://[^\s<>"{}|\\^`\[\]]+',     # FTP URLs  
    r'ssh://[^\s<>"{}|\\^`\[\]]+',     # SSH URLs
    r'git@[^\s<>"{}|\\^`\[\]:]+:[^\s]+',  # Git SSH URLs
    r'[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/[^\s<>"{}|\\^`\[\]]*)?',  # Domain names
    r'localhost:[0-9]+',                # Localhost with port
    r'127\.0\.0\.1:[0-9]+',            # IP with port
]


def is_url(text, start, end):
    """Check if the text between start and end is a URL."""
    substring = text[start:end]
    for pattern in URL_PATTERNS:
        if re.match(pattern, substring):
            return True
    return False


def is_in_url(text, pos):
    """Check if position is inside a URL."""
    # Check each URL pattern
    for pattern in URL_PATTERNS:
        for match in re.finditer(pattern, text):
            if match.start() <= pos < match.end():
                return True
    return False


def is_in_code_block(text, pos):
    """Check if position is inside a code block."""
    # Find all code block markers
    code_markers = []
    i = 0
    while i < len(text):
        if text[i:i+3] == '```':
            # Check if it's escaped
            if i > 0 and text[i-1] == '\\':
                i += 3
                continue
            code_markers.append(i)
            i += 3
        else:
            i += 1
    
    if not code_markers:
        return False
    
    # Determine if position is inside a code block
    # Odd number of markers before position means we're inside
    markers_before = sum(1 for m in code_markers if m < pos)
    return markers_before % 2 == 1


def is_in_preserve_phrase(text, pos):
    """Check if position is inside a phrase that should be preserved."""
    for phrase in PRESERVE_PHRASES:
        for match in re.finditer(re.escape(phrase), text):
            if match.start() <= pos < match.end():
                return True
    return False


def remove_articles(text):
    """Remove articles (a, an, the) from text."""
    # Don't remove from code blocks, preserved phrases, or URLs
    result = []
    i = 0
    while i < len(text):
        if is_in_code_block(text, i) or is_in_preserve_phrase(text, i) or is_in_url(text, i):
            result.append(text[i])
            i += 1
            continue
        
        # Check for articles with word boundaries
        if (text[i:i+2] == "a " and (i == 0 or text[i-1].isspace())):
            i += 2  # Skip "a "
        elif (text[i:i+3] == "an " and (i == 0 or text[i-1].isspace())):
            i += 3  # Skip "an "
        elif (text[i:i+4] == "the " and (i == 0 or text[i-1].isspace())):
            i += 4  # Skip "the "
        else:
            result.append(text[i])
            i += 1
    
    return ''.join(result)


def replace_common_words(text):
    """Replace common technical words with abbreviations."""
    for word, replacement in REPLACEMENTS.items():
        # Only replace full words with boundaries
        pattern = r'\b' + re.escape(word) + r'\b'
        
        # Find all matches
        matches = list(re.finditer(pattern, text, re.IGNORECASE))
        
        # Process matches in reverse order to avoid index issues
        for match in reversed(matches):
            start, end = match.span()
            
            # Skip if in code block, preserved phrase, or URL
            if is_in_code_block(text, start) or is_in_preserve_phrase(text, start) or is_in_url(text, start):
                continue
            
            # Replace while preserving case
            if text[start:end].islower():
                replacement_text = replacement.lower()
            elif text[start:end].isupper():
                replacement_text = replacement.upper()
            elif text[start:end][0].isupper():
                replacement_text = replacement.capitalize()
            else:
                replacement_text = replacement
            
            text = text[:start] + replacement_text + text[end:]
    
    return text


def replace_symbols(text):
    """Replace words/phrases with symbols."""
    for phrase, symbol in SYMBOLS.items():
        # Only replace with word boundaries
        pattern = r'\b' + re.escape(phrase) + r'\b'
        
        # Find all matches
        matches = list(re.finditer(pattern, text, re.IGNORECASE))
        
        # Process matches in reverse order
        for match in reversed(matches):
            start, end = match.span()
            
            # Skip if in code block, preserved phrase, or URL
            if is_in_code_block(text, start) or is_in_preserve_phrase(text, start) or is_in_url(text, start):
                continue
            
            text = text[:start] + symbol + text[end:]
    
    return text


def reduce_vowels(text):
    """Reduce vowels in longer words."""
    words = []
    for word in re.finditer(r'\b\w+\b', text):
        word_text = word.group()
        start, end = word.span()
        
        # Skip if in code block, preserved phrase, URL, or never compress list
        if (is_in_code_block(text, start) or 
            is_in_preserve_phrase(text, start) or
            is_in_url(text, start) or
            word_text.lower() in NEVER_COMPRESS or
            len(word_text) <= 6):  # Only process longer words
            words.append((start, end, word_text))
            continue
        
        # Reduce vowels - keep first vowel after each consonant cluster
        vowels = "aeiouAEIOU"
        result = ""
        i = 0
        
        while i < len(word_text):
            char = word_text[i]
            
            if char.lower() not in vowels:
                # Consonant - always keep it
                result += char
                i += 1
            else:
                # Vowel - keep first vowel in a sequence
                result += char
                i += 1
                # Skip subsequent vowels
                while i < len(word_text) and word_text[i].lower() in vowels:
                    i += 1
        
        words.append((start, end, result))
    
    # Rebuild text with compressed words
    words.sort()  # Sort by position
    result = ""
    last_end = 0
    
    for start, end, word in words:
        result += text[last_end:start] + word
        last_end = end
    
    result += text[last_end:]
    return result


def compress_document(text):
    """Apply all compression techniques to a document."""
    # Skip compression for code blocks
    lines = text.split('\n')
    in_code_block = False
    result = []
    
    for line in lines:
        if line.startswith('```'):
            in_code_block = not in_code_block
            result.append(line)
            continue
        
        if in_code_block:
            result.append(line)
            continue
        
        # Apply compression techniques
        compressed = line
        compressed = replace_common_words(compressed)
        compressed = remove_articles(compressed)
        compressed = replace_symbols(compressed)
        compressed = reduce_vowels(compressed)
        
        result.append(compressed)
    
    return '\n'.join(result)


def compress_file(input_file, output_file, silent=False):
    """Compress a single file."""
    # Validate input path
    if not os.path.exists(input_file):
        if not silent:
            print(f"Error: Input file '{input_file}' does not exist")
        return False
    
    if not os.path.isfile(input_file):
        if not silent:
            print(f"Error: Input path '{input_file}' is not a file")
        return False
    
    # Validate output path directory exists
    output_dir = os.path.dirname(output_file)
    if output_dir and not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir, exist_ok=True)
        except Exception as e:
            if not silent:
                print(f"Error creating output directory '{output_dir}': {e}")
            return False
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Get file stats before compression
        original_size = len(content)
        
        if original_size == 0:
            if not silent:
                print(f"Warning: Input file '{input_file}' is empty")
            return False
        
        # Compress content
        compressed = compress_document(content)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(compressed)
        
        # Get file stats after compression
        compressed_size = len(compressed)
        if original_size > 0:
            savings = (1 - compressed_size / original_size) * 100
        else:
            savings = 0
        
        if not silent:
            print(f"Compressed {input_file} → {output_file}")
            print(f"Original: {original_size} chars, Compressed: {compressed_size} chars")
            print(f"Reduction: {savings:.1f}%")
        
        return True
    except PermissionError as e:
        if not silent:
            print(f"Error: Permission denied accessing files: {e}")
        return False
    except UnicodeDecodeError as e:
        if not silent:
            print(f"Error: Unable to decode file '{input_file}' as UTF-8: {e}")
        return False
    except Exception as e:
        if not silent:
            print(f"Error compressing {input_file}: {e}")
        return False


def compress_all_docs(source_dirs=None, output_dir='.compressed', silent=False):
    """Compress all markdown documents from multiple source directories."""
    if source_dirs is None:
        # Default source directories to check
        source_dirs = ['.human/docs', 'docs', '.', 'templates']
    
    success_count = 0
    total_count = 0
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Track processed files to avoid duplicates
    processed_files = set()
    
    for source_dir in source_dirs:
        if not os.path.exists(source_dir):
            continue
        
        # Find all markdown files
        for file in os.listdir(source_dir):
            if file.endswith('.md') and not file.endswith('_COMPACT.md'):
                # Skip README files (they're for humans)
                if file.upper() == 'README.MD':
                    continue
                
                # Skip if already processed
                if file in processed_files:
                    continue
                
                processed_files.add(file)
                total_count += 1
                
                input_path = os.path.join(source_dir, file)
                output_file = file.replace('.md', '_COMPACT.md')
                output_path = os.path.join(output_dir, output_file)
                
                if compress_file(input_path, output_path, silent):
                    success_count += 1
    
    if not silent:
        print(f"\nCompressed {success_count}/{total_count} documents")
    
    # Create symlinks in docs directory for agent access
    create_symlinks(output_dir, silent)
    
    return success_count == total_count


def create_symlinks(compressed_dir='.compressed', silent=False):
    """Create symlinks in docs/ directory pointing to compressed files."""
    docs_dir = 'docs'
    os.makedirs(docs_dir, exist_ok=True)
    
    if not os.path.exists(compressed_dir):
        return
    
    # Remove old symlinks
    for file in os.listdir(docs_dir):
        file_path = os.path.join(docs_dir, file)
        if os.path.islink(file_path):
            os.unlink(file_path)
    
    # Create new symlinks
    for file in os.listdir(compressed_dir):
        if file.endswith('_COMPACT.md'):
            compressed_path = os.path.join('..', compressed_dir, file)
            # Create symlink without _COMPACT suffix
            link_name = file.replace('_COMPACT.md', '.md')
            link_path = os.path.join(docs_dir, link_name)
            
            try:
                os.symlink(compressed_path, link_path)
                if not silent:
                    print(f"Created symlink: {link_path} -> {compressed_path}")
            except Exception as e:
                if not silent:
                    print(f"Error creating symlink {link_path}: {e}")


def main():
    parser = argparse.ArgumentParser(description='Compress documentation for AI Agent Handoff System')
    parser.add_argument('--input', help='Input file path')
    parser.add_argument('--output', help='Output file path')
    parser.add_argument('--compress-all', action='store_true', help='Compress all docs')
    parser.add_argument('--source-dirs', nargs='+', help='Source directories to compress from')
    parser.add_argument('--output-dir', default='.compressed', help='Output directory for compressed files')
    parser.add_argument('--silent', action='store_true', help='Suppress output')
    parser.add_argument('--stats', action='store_true', help='Print compression statistics only')
    
    args = parser.parse_args()
    
    # Default behavior: compress all
    if not args.input and not args.output:
        args.compress_all = True
    
    if args.compress_all:
        compress_all_docs(args.source_dirs, args.output_dir, args.silent)
    elif args.input and args.output:
        compress_file(args.input, args.output, args.silent)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()