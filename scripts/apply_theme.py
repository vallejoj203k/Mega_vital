#!/usr/bin/env python3
"""
Applies light/dark theme support to a Flutter screen file:
 1. Adds DynamicColors import
 2. Adds `final c = context.colors;` to every build() method
 3. Adds `final c = context.colors;` to every private _buildXxx() method (State has this.context)
 4. Replaces AppColors dynamic refs with c.xxx
 5. Removes `const` from widget constructors on lines that now reference c.xxx
"""
import re, sys, os

DYNAMIC_COLORS_IMPORT = "import '../../../core/theme/dynamic_colors.dart';"

REPLACEMENTS = [
    # surfaceVariant before surface to avoid partial match
    (r'AppColors\.surfaceVariant', 'c.surfaceVariant'),
    (r'AppColors\.background',    'c.background'),
    (r'AppColors\.surface\b',     'c.surface'),
    (r'AppColors\.border\b',      'c.border'),
    (r'AppColors\.textPrimary\b', 'c.textPrimary'),
    (r'AppColors\.textSecondary\b','c.textSecondary'),
    (r'AppColors\.textMuted\b',   'c.textMuted'),
]

DYNAMIC_REFS = re.compile(r'c\.(background|surface|surfaceVariant|border|textPrimary|textSecondary|textMuted)\b')

def process_file(path: str, import_prefix: str = "../../../core/theme/dynamic_colors.dart"):
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()

    # ── 1. Add import ──────────────────────────────────────────
    import_line = f"import '{import_prefix}';\n"
    already_has = any(import_prefix in l for l in lines)
    if not already_has:
        # Insert after the last existing import line
        last_import = 0
        for i, l in enumerate(lines):
            if l.strip().startswith('import '):
                last_import = i
        lines.insert(last_import + 1, import_line)

    # ── 2. Do color replacements (line by line) ────────────────
    for i, line in enumerate(lines):
        for pattern, replacement in REPLACEMENTS:
            line = re.sub(pattern, replacement, line)
        lines[i] = line

    # ── 3. Remove `const` from constructors that now use c.xxx ─
    # Targets patterns like:  const Icon(... c.textMuted ...)
    #                         const TextStyle(... c.textPrimary ...)
    # Only single-line occurrences (multi-line unlikely with these colors)
    CONST_RE = re.compile(r'\bconst\s+([A-Z][A-Za-z0-9_]*)\s*\(')
    for i, line in enumerate(lines):
        if DYNAMIC_REFS.search(line) and 'const ' in line:
            lines[i] = CONST_RE.sub(r'\1(', line)

    # ── 4. Add `final c = context.colors;` to build methods ────
    # Pattern A: Widget build(BuildContext context) {
    # Pattern B: Widget _buildXxx(...)  (private helpers — in State, context is a property)
    # Pattern C: common builder callbacks with BuildContext param
    BUILD_OPEN = re.compile(
        r'^\s*(Widget|@override)\s*$|'               # @override on its own line before build
        r'Widget\s+build\s*\(\s*BuildContext\s+\w+\s*\)\s*\{|'
        r'Widget\s+_\w+\s*\([^)]*\)\s*\{|'
        r'Widget\s+_\w+\s*\(\s*\)\s*\{'
    )
    # More targeted: look for lines that open a widget-returning method
    # Insert `final c = context.colors;` as first non-blank line inside the body
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        new_lines.append(line)

        stripped = line.rstrip()
        # Match build(BuildContext context) {  (may span two lines if @override is above)
        is_build = bool(re.search(
            r'Widget\s+build\s*\(\s*BuildContext\s+\w+\s*\)\s*\{', stripped))
        is_private = bool(re.search(
            r'Widget\s+_\w+\s*\([^)]*\)\s*\{', stripped))

        if (is_build or is_private) and stripped.endswith('{'):
            indent = len(line) - len(line.lstrip())
            # Check if next non-blank line already has `final c = context.colors`
            j = i + 1
            while j < len(lines) and lines[j].strip() == '':
                j += 1
            if j < len(lines) and 'final c = context.colors' not in lines[j]:
                new_lines.append(' ' * (indent + 4) + 'final c = context.colors;\n')
        i += 1

    return ''.join(new_lines)


def main():
    files = sys.argv[1:]
    for path in files:
        print(f'Processing {path}...')
        result = process_file(path)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(result)
        print(f'  Done.')

if __name__ == '__main__':
    main()
