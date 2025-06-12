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


def is_in_code_block(text, pos):
    """Check if position is inside a code block."""
    code_starts = [m.start() for m in re.finditer(r'```', text)]
    if not code_starts:
        return False
    
    # Group into pairs
    code_blocks = []
    for i in range(0, len(code_starts) - 1, 2):
        if i + 1 < len(code_starts):
            code_blocks.append((code_starts[i], code_starts[i + 1]))
    
    # Check if position is inside any code block
    for start, end in code_blocks:
        if start < pos < end:
            return True
    
    return False


def is_in_preserve_phrase(text, pos):
    """Check if position is inside a phrase that should be preserved."""
    for phrase in PRESERVE_PHRASES:
        for match in re.finditer(re.escape(phrase), text):
            if match.start() <= pos < match.end():
                return True
    return False


def remove_articles(text):
    """Remove articles (a, an, the) from text."""
    # Don't remove from code blocks or preserved phrases
    result = []
    i = 0
    while i < len(text):
        if is_in_code_block(text, i) or is_in_preserve_phrase(text, i):
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
            
            # Skip if in code block or preserved phrase
            if is_in_code_block(text, start) or is_in_preserve_phrase(text, start):
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
            
            # Skip if in code block or preserved phrase
            if is_in_code_block(text, start) or is_in_preserve_phrase(text, start):
                continue
            
            text = text[:start] + symbol + text[end:]
    
    return text


def reduce_vowels(text):
    """Reduce vowels in longer words."""
    words = []
    for word in re.finditer(r'\b\w+\b', text):
        word_text = word.group()
        start, end = word.span()
        
        # Skip if in code block, preserved phrase, or never compress list
        if (is_in_code_block(text, start) or 
            is_in_preserve_phrase(text, start) or
            word_text.lower() in NEVER_COMPRESS or
            len(word_text) <= 6):  # Only process longer words
            words.append((start, end, word_text))
            continue
        
        # Reduce vowels, keeping first vowel
        vowels = "aeiouAEIOU"
        result = ""
        found_first = False
        
        for char in word_text:
            if char.lower() in vowels:
                if not found_first:
                    result += char
                    found_first = True
                # Skip additional vowels
            else:
                result += char
        
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


def compress_file(input_file, output_file):
    """Compress a single file."""
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Get file stats before compression
        original_size = len(content)
        
        # Compress content
        compressed = compress_document(content)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(compressed)
        
        # Get file stats after compression
        compressed_size = len(compressed)
        savings = (1 - compressed_size / original_size) * 100
        
        print(f"Compressed {input_file} → {output_file}")
        print(f"Original: {original_size} chars, Compressed: {compressed_size} chars")
        print(f"Reduction: {savings:.1f}%")
        
        return True
    except Exception as e:
        print(f"Error compressing {input_file}: {e}")
        return False


def compress_all_docs(docs_dir='docs'):
    """Compress all markdown documents in the docs directory."""
    success_count = 0
    total_count = 0
    
    # Ensure docs directory exists
    if not os.path.exists(docs_dir):
        print(f"Error: {docs_dir} directory not found")
        return False
    
    for file in os.listdir(docs_dir):
        if file.endswith('.md') and not file.endswith('_COMPACT.md'):
            total_count += 1
            input_path = os.path.join(docs_dir, file)
            output_path = os.path.join(docs_dir, file.replace('.md', '_COMPACT.md'))
            
            if compress_file(input_path, output_path):
                success_count += 1
    
    print(f"Compressed {success_count}/{total_count} documents")
    return success_count == total_count


def main():
    parser = argparse.ArgumentParser(description='Compress documentation for AI Agent Handoff System')
    parser.add_argument('--input', help='Input file path')
    parser.add_argument('--output', help='Output file path')
    parser.add_argument('--compress-all', action='store_true', help='Compress all docs in /docs directory')
    parser.add_argument('--stats', action='store_true', help='Print compression statistics only')
    
    args = parser.parse_args()
    
    if args.compress_all:
        compress_all_docs()
    elif args.input and args.output:
        compress_file(args.input, args.output)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()