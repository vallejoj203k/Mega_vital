#!/usr/bin/env python3
"""
Removes `const` from widget constructors that contain dynamic color references (c.xxx).
Handles both single-line and multi-line cases using a bracket-depth tracker.
"""
import re, sys

DYNAMIC_REF = re.compile(
    r'c\.(background|surface|surfaceVariant|border|textPrimary|textSecondary|textMuted)\b'
)
CONST_KW = re.compile(r'\bconst\b')

def find_const_violations(text: str) -> list[int]:
    """Return character offsets of `const` keywords that start a constructor
    containing a dynamic color ref."""
    violations = []
    i = 0
    while i < len(text):
        m = CONST_KW.search(text, i)
        if not m:
            break
        # Find the opening paren after const keyword
        j = m.end()
        # Skip whitespace and the widget name
        while j < len(text) and text[j] in ' \t\n\r':
            j += 1
        # Skip identifier (widget name)
        name_start = j
        while j < len(text) and (text[j].isalnum() or text[j] == '_'):
            j += 1
        if j == name_start:
            i = m.end()
            continue
        # Skip whitespace
        while j < len(text) and text[j] in ' \t\n\r':
            j += 1
        if j >= len(text) or text[j] != '(':
            i = m.end()
            continue
        # Now scan from opening paren to matching closing paren
        depth = 0
        k = j
        body_start = j
        while k < len(text):
            if text[k] == '(':
                depth += 1
            elif text[k] == ')':
                depth -= 1
                if depth == 0:
                    break
            k += 1
        body = text[body_start:k+1]
        if DYNAMIC_REF.search(body):
            violations.append(m.start())
        i = m.end()
    return violations

def remove_const_violations(text: str) -> str:
    violations = find_const_violations(text)
    if not violations:
        return text
    # Remove in reverse order to preserve offsets
    for offset in reversed(violations):
        # Find the const keyword at offset and remove it + trailing space
        m = CONST_KW.match(text, offset)
        if m:
            end = m.end()
            # Remove one space after `const` if present
            if end < len(text) and text[end] == ' ':
                end += 1
            text = text[:offset] + text[end:]
    return text

def process_file(path: str):
    with open(path, encoding='utf-8') as f:
        text = f.read()
    new_text = remove_const_violations(text)
    if new_text != text:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_text)
        print(f'  Fixed const violations in {path}')
    else:
        print(f'  No const violations in {path}')

for path in sys.argv[1:]:
    process_file(path)
