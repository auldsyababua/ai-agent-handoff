#!/usr/bin/env python3
"""
Decompress LLM-written compressed docs back to human-readable format

This script reverses the compression applied by compress_docs.py:
1. Expands abbreviations back to full words
2. Restores vowels in compressed words
3. Converts structured data back to prose
4. Adds articles and formatting for readability

Usage:
  ./decompress.py                     # Decompress all _COMPACT.md files
  ./decompress.py --input <file>      # Decompress specific file
  ./decompress.py --silent            # Run without output
"""

import os
import re
import sys
import argparse
import yaml
import json
from pathlib import Path

# Extended mapping for decompression (reverse of compress_docs.py)
EXPANSIONS = {
    # Note: MCP is handled specially - it's expanded during compression
    # so we don't need to handle it here
    
    # Common abbreviations
    'fn': 'function',
    'impl': 'implementation', 
    'param': 'parameter',
    'config': 'configuration',
    'app': 'application',
    'db': 'database',
    'auth': 'authentication',
    'dir': 'directory',
    'repo': 'repository',
    'init': 'initialize',
    'integ': 'integration',
    'dev': 'development',
    'prod': 'production',
    'env': 'environment',
    'docs': 'documentation',
    'dist': 'distribution',
    'arch': 'architecture',
    'arg': 'argument',
    'attr': 'attribute',
    'bg': 'background',
    'cert': 'certificate',
    'cmd': 'command',
    'comm': 'communication',
    'conn': 'connection',
    'desc': 'description',
    'dest': 'destination',
    'exec': 'execute',
    'ext': 'extension',
    'fig': 'figure',
    'gen': 'generate',
    'impl': 'implementation',
    'incl': 'include',
    'info': 'information',
    'lib': 'library',
    'loc': 'location',
    'max': 'maximum',
    'min': 'minimum',
    'msg': 'message',
    'num': 'number',
    'obj': 'object',
    'opt': 'option',
    'orig': 'original',
    'pkg': 'package',
    'pref': 'preference',
    'proc': 'process',
    'ref': 'reference',
    'req': 'requirement',
    'resp': 'response',
    'spec': 'specification',
    'src': 'source',
    'std': 'standard',
    'str': 'string',
    'sync': 'synchronize',
    'temp': 'temporary',
    'usr': 'user',
    'util': 'utility',
    'val': 'value',
    'var': 'variable',
    'ver': 'version',
    'mgmt': 'management',
    'deps': 'dependencies',
    'nm': 'node_modules',
    'auto': 'automatically',
    
    # Tech stack
    'js': 'JavaScript',
    'ts': 'TypeScript',
    'py': 'Python',
    'rb': 'Ruby',
    'go': 'Go',
    'rs': 'Rust',
    'cpp': 'C++',
    'cs': 'C#',
    'kt': 'Kotlin',
    'sw': 'Swift',
    
    # Common phrases
    'chk': 'check if',
    'w/': 'with',
    'w/o': 'without',
    'b/c': 'because',
    'thru': 'through',
    'tho': 'though',
    'btw': 'by the way',
    
    # File extensions
    '.md': '.md',
    '.json': '.json',
    '.yaml': '.yaml',
    '.yml': '.yml',
    '.txt': '.txt',
    '.log': '.log',
    '.sh': '.sh',
    '.py': '.py',
    '.js': '.js',
    '.ts': '.ts',
    '.jsx': '.jsx',
    '.tsx': '.tsx',
    '.html': '.html',
    '.css': '.css',
}

# Common compressed patterns that need expansion
COMPRESSED_PATTERNS = [
    # Pattern: "- key: value" -> "- The key system/feature value"
    (r'^- (\w+): (.+)$', lambda m: expand_yaml_line(m)),
    # Pattern: "x → y" -> "x returns/leads to y"
    (r'(\w+)\s*→\s*(.+)', r'\1 returns \2'),
    # Pattern: compressed file paths
    (r'(\w+)/(\w+)\.(\w+)', lambda m: expand_path(m)),
]

def expand_yaml_line(match):
    """Convert YAML-style line back to prose."""
    key = match.group(1)
    value = match.group(2)
    
    # Context-aware expansion
    if key in ['auth', 'db', 'api', 'cache', 'queue']:
        return f"- The {expand_word(key)} system uses {value}"
    elif key == 'chk':
        return f"- Check if {value}"
    elif key == 'run':
        parts = value.split(' → ')
        if len(parts) == 2:
            return f"- Run {parts[0]} to {parts[1]}"
        return f"- Run {value}"
    elif key == 'if':
        parts = value.split(' → ')
        if len(parts) == 2:
            return f"- If {parts[0]}, then {parts[1]}"
        return f"- If {value}"
    else:
        return f"- {expand_word(key)}: {value}"

def expand_path(match):
    """Expand compressed file paths."""
    dir_name = expand_word(match.group(1))
    file_name = expand_word(match.group(2))
    extension = match.group(3)
    return f"{dir_name}/{file_name}.{extension}"

def expand_word(word):
    """Expand a single word if it's in our abbreviation map."""
    return EXPANSIONS.get(word.lower(), word)

def restore_vowels(text):
    """
    Restore vowels in compressed words.
    This is heuristic-based and won't be perfect, but should handle common cases.
    """
    # Common patterns where vowels were removed
    vowel_patterns = [
        # Pattern: consonant clusters that likely had vowels
        (r'\b(\w*[bcdfghjklmnpqrstvwxyz]{3,}\w*)\b', restore_word_vowels),
    ]
    
    for pattern, handler in vowel_patterns:
        text = re.sub(pattern, handler, text, flags=re.IGNORECASE)
    
    return text

def restore_word_vowels(match):
    """
    Attempt to restore vowels in a compressed word.
    This uses common patterns and a small dictionary of known compressions.
    """
    word = match.group(1)
    
    # Dictionary of known compressed -> full words
    known_restorations = {
        'prjct': 'project',
        'srvc': 'service',
        'cmpnt': 'component',
        'tst': 'test',
        'dbg': 'debug',
        'tmp': 'temporary',
        'rmv': 'remove',
        'crt': 'create',
        'updt': 'update',
        'del': 'delete',
        'rtrn': 'return',
        'err': 'error',
        'func': 'function',
        'mthd': 'method',
        'prm': 'parameter',
        'vld': 'valid',
        'invld': 'invalid',
        'enbld': 'enabled',
        'dsbld': 'disabled',
        'actv': 'active',
        'inactv': 'inactive',
        'pndng': 'pending',
        'sccss': 'success',
        'fail': 'failure',
        'hndlr': 'handler',
        'mdlwr': 'middleware',
        'rtr': 'router',
        'ctrl': 'controller',
        'mdl': 'model',
        'schma': 'schema',
        'vldtn': 'validation',
        'sess': 'session',
        'tkn': 'token',
        'pwd': 'password',
        'hsh': 'hash',
        'slt': 'salt',
        'encr': 'encrypt',
        'decr': 'decrypt',
        'hdr': 'header',
        'bdy': 'body',
        'qry': 'query',
        'prms': 'params',
        'sts': 'status',
        'cd': 'code',
        'dflt': 'default',
        'len': 'length',
        'sz': 'size',
        'cnt': 'count',
        'idx': 'index',
        'pos': 'position',
        'strt': 'start',
        'frst': 'first',
        'lst': 'last',
        'prev': 'previous',
        'nxt': 'next',
        'curr': 'current',
        'prsnt': 'present',
        'abst': 'absent',
        'avail': 'available',
        'unavail': 'unavailable',
        'disconn': 'disconnection',
        'tm': 'time',
        'dt': 'date',
        'yr': 'year',
        'mo': 'month',
        'dy': 'day',
        'hr': 'hour',
        'sec': 'second',
        'ms': 'millisecond',
        'tz': 'timezone',
        'fmt': 'format',
        'prs': 'parse',
        'conv': 'convert',
        'calc': 'calculate',
        'comp': 'compute',
        'bld': 'build',
        'inst': 'install',
        'cfg': 'configure',
        'stp': 'stop',
        'rst': 'restart',
        'pse': 'pause',
        'rsme': 'resume',
        'hndl': 'handle',
        'mon': 'monitor',
        'trc': 'trace',
        'wrn': 'warning',
        'notif': 'notification',
        'alrt': 'alert',
        'evt': 'event',
        'trgr': 'trigger',
        'lstnr': 'listener',
        'emt': 'emit',
        'brdcst': 'broadcast',
        'sub': 'subscribe',
        'unsub': 'unsubscribe',
        'pub': 'publish',
        'q': 'queue',
        'stck': 'stack',
        'buff': 'buffer',
        'strm': 'stream',
        'btch': 'batch',
        'sngl': 'single',
        'mult': 'multiple',
        'flt': 'filter',
        'rdce': 'reduce',
        'grp': 'group',
        'aggr': 'aggregate',
        'splt': 'split',
        'mrg': 'merge',
        'comb': 'combine',
        'extr': 'extract',
        'enc': 'encode',
        'dec': 'decode',
        'ser': 'serialize',
        'deser': 'deserialize',
        'cmp': 'compress',
        'decmp': 'decompress',
        'rd': 'read',
        'wr': 'write',
        'apnd': 'append',
        'mv': 'move',
        'cp': 'copy',
        'rnm': 'rename',
        'pth': 'path',
        'fl': 'file',
        'fldr': 'folder',
        'perm': 'permission',
        'own': 'owner',
        'crtd': 'created',
        'mdfd': 'modified',
        'accssd': 'accessed',
        'lck': 'lock',
        'unlck': 'unlock',
        'opn': 'open',
        'cls': 'close',
        'sv': 'save',
        'ld': 'load',
        'imprt': 'import',
        'exprt': 'export',
        'incl': 'include',
        'excl': 'exclude',
        'dpnd': 'depend',
        'dpndncy': 'dependency',
        'frmwrk': 'framework',
        'plgn': 'plugin',
        'wdgt': 'widget',
        'elm': 'element',
        'prop': 'property',
        'cstm': 'custom',
        'ovrd': 'override',
        'inhrt': 'inherit',
        'extnd': 'extend',
        'abstr': 'abstract',
        'intrf': 'interface',
        'cls': 'class',
        'cnstr': 'constructor',
        'dstr': 'destructor',
        'priv': 'private',
        'prot': 'protected',
        'stat': 'static',
        'thrw': 'throw',
        'ctch': 'catch',
        'finlly': 'finally',
        'elif': 'else if',
        'swtch': 'switch',
        'brk': 'break',
        'cont': 'continue',
        'iter': 'iterate',
        'recur': 'recursive',
        'prom': 'promise',
        'rslv': 'resolve',
        'rjct': 'reject',
        'obs': 'observer',
        'subj': 'subject',
        'vec': 'vector',
        'dict': 'dictionary',
        'tbl': 'table',
        'grph': 'graph',
        'prnt': 'parent',
        'chld': 'child',
        'sib': 'sibling',
        'anc': 'ancestor',
        'dpth': 'depth',
        'hght': 'height',
        'lvl': 'level',
        'trvrs': 'traverse',
        'srch': 'search',
        'fnd': 'find',
        'ins': 'insert',
        'upd': 'update',
        'repl': 'replace',
        'rev': 'reverse',
        'shffl': 'shuffle',
        'rndm': 'random',
        'avg': 'average',
        'cap': 'capacity',
        'lmt': 'limit',
        'thr': 'threshold',
        'rng': 'range',
        'bnd': 'bound',
        'loc': 'location',
        'coord': 'coordinate',
        'wdth': 'width',
        'rad': 'radius',
        'diam': 'diameter',
        'vol': 'volume',
        'wght': 'weight',
        'dens': 'density',
        'press': 'pressure',
        'vel': 'velocity',
        'acc': 'acceleration',
        'frc': 'force',
        'enrg': 'energy',
        'pwr': 'power',
        'freq': 'frequency',
        'amp': 'amplitude',
        'phs': 'phase',
        'wvlngth': 'wavelength',
        'clr': 'color',
        'brght': 'brightness',
        'contr': 'contrast',
        'opac': 'opacity',
        'transp': 'transparency',
        'vis': 'visible',
        'hid': 'hidden',
        'dspl': 'display',
        'rndr': 'render',
        'pnt': 'paint',
        'refr': 'refresh',
        'anim': 'animate',
        'trans': 'transition',
        'transf': 'transform',
        'rot': 'rotate',
        'scl': 'scale',
        'skw': 'skew',
        'flp': 'flip',
        'mirr': 'mirror',
        'algn': 'align',
        'cntr': 'center',
        'lft': 'left',
        'rght': 'right',
        'btm': 'bottom',
        'horiz': 'horizontal',
        'vert': 'vertical',
        'diag': 'diagonal',
        'prll': 'parallel',
        'perp': 'perpendicular',
        'tang': 'tangent',
        'norm': 'normal',
        'curv': 'curve',
        'rect': 'rectangle',
        'sqr': 'square',
        'circ': 'circle',
        'ellps': 'ellipse',
        'poly': 'polygon',
        'tri': 'triangle',
        'quad': 'quadrilateral',
        'pent': 'pentagon',
        'hex': 'hexagon',
        'oct': 'octagon',
        'sph': 'sphere',
        'cyl': 'cylinder',
        'pyr': 'pyramid',
        'prsm': 'prism',
    }
    
    # Check if we have a known restoration
    word_lower = word.lower()
    if word_lower in known_restorations:
        # Preserve original case
        if word.isupper():
            return known_restorations[word_lower].upper()
        elif word[0].isupper():
            return known_restorations[word_lower].capitalize()
        else:
            return known_restorations[word_lower]
    
    # If not in dictionary, return as-is
    return word

def add_articles(text):
    """Add articles (a, an, the) where appropriate for readability."""
    # Add "the" before certain nouns
    text = re.sub(r'\b(system|service|database|server|client|user|file|directory|configuration|environment)\b',
                  r'the \1', text, flags=re.IGNORECASE)
    
    # Add "a" or "an" before singular nouns that aren't already preceded by articles
    # This is simplified - a full implementation would need better grammar understanding
    text = re.sub(r'(?<!\w)(is|was|has|have|create|add|implement|build)\s+([bcdfghjklmnpqrstvwxyz]\w+)\b',
                  r'\1 a \2', text, flags=re.IGNORECASE)
    text = re.sub(r'(?<!\w)(is|was|has|have|create|add|implement|build)\s+([aeiou]\w+)\b',
                  r'\1 an \2', text, flags=re.IGNORECASE)
    
    return text

def expand_dev_log_yaml(yaml_content):
    """Convert compressed dev log YAML back to narrative format."""
    try:
        # Parse YAML
        entries = yaml.safe_load(yaml_content)
        if not isinstance(entries, list):
            return yaml_content
        
        expanded = []
        for entry in entries:
            # Timestamp
            if 't' in entry:
                expanded.append(f"## {entry['t']}")
                expanded.append("")
            
            # Changes
            if 'changes' in entry and entry['changes']:
                expanded.append("### What Changed")
                for change in entry['changes']:
                    expanded_change = expand_abbreviations(change)
                    expanded.append(f"- {expanded_change}")
                expanded.append("")
            
            # Issues
            if 'issues' in entry and entry['issues']:
                expanded.append("### Issues Encountered")
                for issue in entry['issues']:
                    expanded_issue = expand_abbreviations(issue)
                    expanded.append(f"- {expanded_issue}")
                expanded.append("")
            
            # Next steps
            if 'next' in entry and entry['next']:
                expanded.append("### Next Steps")
                expanded_next = expand_abbreviations(entry['next'])
                expanded.append(f"- {expanded_next}")
                expanded.append("")
            
            expanded.append("---")
            expanded.append("")
        
        return '\n'.join(expanded)
    except:
        # If YAML parsing fails, return original
        return yaml_content

def expand_abbreviations(text):
    """Expand all abbreviations in text."""
    # Sort by length descending to avoid partial replacements
    sorted_expansions = sorted(EXPANSIONS.items(), key=lambda x: len(x[0]), reverse=True)
    
    for abbrev, full in sorted_expansions:
        # Use word boundaries to avoid partial matches
        text = re.sub(r'\b' + re.escape(abbrev) + r'\b', full, text, flags=re.IGNORECASE)
    
    return text

def decompress_document(text):
    """Apply all decompression techniques to a document."""
    lines = text.split('\n')
    in_code_block = False
    result = []
    
    for line in lines:
        if line.startswith('```'):
            in_code_block = not in_code_block
            result.append(line)
            continue
        
        if in_code_block:
            # Don't decompress code blocks
            result.append(line)
            continue
        
        # Apply decompression techniques
        decompressed = line
        
        # First expand abbreviations
        decompressed = expand_abbreviations(decompressed)
        
        # Apply pattern-based expansions
        for pattern, replacement in COMPRESSED_PATTERNS:
            if callable(replacement):
                decompressed = re.sub(pattern, replacement, decompressed, flags=re.MULTILINE)
            else:
                decompressed = re.sub(pattern, replacement, decompressed)
        
        # Restore vowels in compressed words
        decompressed = restore_vowels(decompressed)
        
        # Add articles for readability (optional, can be aggressive)
        # decompressed = add_articles(decompressed)
        
        result.append(decompressed)
    
    return '\n'.join(result)

def decompress_file(input_file, output_file, silent=False):
    """Decompress a single file."""
    if not os.path.exists(input_file):
        if not silent:
            print(f"Error: Input file '{input_file}' does not exist")
        return False
    
    # Ensure output directory exists
    output_dir = os.path.dirname(output_file)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if it's a dev log (special handling)
        if 'dev_log' in input_file and content.strip().startswith('['):
            decompressed = expand_dev_log_yaml(content)
        else:
            decompressed = decompress_document(content)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(decompressed)
        
        if not silent:
            print(f"Decompressed {input_file} → {output_file}")
        
        return True
    except Exception as e:
        if not silent:
            print(f"Error decompressing {input_file}: {e}")
        return False

def decompress_all(compressed_dir='.compressed', output_dir='.human/docs', silent=False):
    """Decompress all _COMPACT.md files."""
    if not os.path.exists(compressed_dir):
        if not silent:
            print(f"Compressed directory '{compressed_dir}' not found")
        return False
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    success_count = 0
    total_count = 0
    
    for file in os.listdir(compressed_dir):
        if file.endswith('_COMPACT.md'):
            total_count += 1
            input_path = os.path.join(compressed_dir, file)
            # Remove _COMPACT suffix for output
            output_file = file.replace('_COMPACT.md', '.md')
            output_path = os.path.join(output_dir, output_file)
            
            if decompress_file(input_path, output_path, silent):
                success_count += 1
    
    if not silent:
        print(f"\nDecompressed {success_count}/{total_count} files")
    
    return success_count == total_count

def main():
    parser = argparse.ArgumentParser(description='Decompress LLM-written docs to human-readable format')
    parser.add_argument('--input', help='Input compressed file')
    parser.add_argument('--output', help='Output decompressed file')
    parser.add_argument('--compressed-dir', default='.compressed', help='Directory with compressed files')
    parser.add_argument('--output-dir', default='.human/docs', help='Output directory for decompressed files')
    parser.add_argument('--silent', action='store_true', help='Suppress output')
    
    args = parser.parse_args()
    
    if args.input and args.output:
        decompress_file(args.input, args.output, args.silent)
    else:
        # Default: decompress all
        decompress_all(args.compressed_dir, args.output_dir, args.silent)

if __name__ == '__main__':
    main()