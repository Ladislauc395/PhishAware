import os
import re

WIDGET_NAMES = [
    'Icon', 'SizedBox', 'BorderSide', 'LinearGradient', 'RadialGradient',
    'AlwaysStoppedAnimation', 'Center', 'CircularProgressIndicator',
    'BoxDecoration', 'InputDecoration', 'TextStyle', 'EdgeInsets',
]

pattern = re.compile(
    r'const\s+(' + '|'.join(WIDGET_NAMES) + r')\s*\('
)

def needs_fix(line):
    return bool(pattern.search(line)) and 'AppColors.' in line

def fix_line(line):
    def replacer(m):
        return m.group(1) + '('
    return pattern.sub(replacer, line)

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    changed = 0
    new_lines = []
    for line in lines:
        if needs_fix(line):
            fixed = fix_line(line)
            new_lines.append(fixed)
            if fixed != line:
                changed += 1
        else:
            new_lines.append(line)
    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f'  Fixed {changed} line(s): {path}')
    return changed

total = 0
for root, dirs, files in os.walk('lib'):
    dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build']]
    for fname in files:
        if fname.endswith('.dart'):
            total += process_file(os.path.join(root, fname))

print(f'\nTotal lines fixed: {total}')
print('Run "flutter clean && flutter pub get" then rebuild.')
