import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Simple text replacements
    replacements = {
        'EdgeInsets.fromLTRB': 'EdgeInsetsDirectional.fromSTEB',
        'Alignment.centerLeft': 'AlignmentDirectional.centerStart',
        'Alignment.centerRight': 'AlignmentDirectional.centerEnd',
        'Alignment.topLeft': 'AlignmentDirectional.topStart',
        'Alignment.topRight': 'AlignmentDirectional.topEnd',
        'Alignment.bottomLeft': 'AlignmentDirectional.bottomStart',
        'Alignment.bottomRight': 'AlignmentDirectional.bottomEnd',
    }
    for k, v in replacements.items():
        content = content.replace(k, v)

    # Regex replacements
    # EdgeInsets.only(left: 10, right: 20, ...)
    # This might be tricky because there could be bottom, top as well.
    # We can just replace left: with start: and right: with end: if it's inside EdgeInsets.only or Positioned or BorderRadius.only
    
    # Replace `left:` with `start:` globally inside EdgeInsets.only(...)
    # Actually, it's safer to just replace 'left:' with 'start:' and 'right:' with 'end:' for specific widget/classes
    
    # Let's replace EdgeInsets.only -> EdgeInsetsDirectional.only
    content = content.replace('EdgeInsets.only', 'EdgeInsetsDirectional.only')
    
    # We also need to change the arguments: left -> start, right -> end.
    # Since we changed EdgeInsets.only to EdgeInsetsDirectional.only, the arguments 'left' and 'right' will cause compilation errors.
    # We must rename left to start, and right to end where EdgeInsetsDirectional is used.
    # A simple way: find EdgeInsetsDirectional.only(.*?) and replace left/right inside it.
    def replace_edgeinsets_args(match):
        inner = match.group(1)
        inner = re.sub(r'\bleft\s*:', 'start:', inner)
        inner = re.sub(r'\bright\s*:', 'end:', inner)
        return 'EdgeInsetsDirectional.only(' + inner + ')'
    content = re.sub(r'EdgeInsetsDirectional\.only\((.*?)\)', replace_edgeinsets_args, content, flags=re.DOTALL)
    
    # Similarly for Positioned -> PositionedDirectional
    content = content.replace('Positioned(', 'PositionedDirectional(')
    def replace_positioned_args(match):
        inner = match.group(1)
        inner = re.sub(r'\bleft\s*:', 'start:', inner)
        inner = re.sub(r'\bright\s*:', 'end:', inner)
        return 'PositionedDirectional(' + inner + ')'
    content = re.sub(r'PositionedDirectional\((.*?)\)', replace_positioned_args, content, flags=re.DOTALL)

    # BorderRadius.only -> BorderRadiusDirectional.only
    content = content.replace('BorderRadius.only', 'BorderRadiusDirectional.only')
    def replace_borderradius_args(match):
        inner = match.group(1)
        inner = re.sub(r'\btopLeft\s*:', 'topStart:', inner)
        inner = re.sub(r'\btopRight\s*:', 'topEnd:', inner)
        inner = re.sub(r'\bbottomLeft\s*:', 'bottomStart:', inner)
        inner = re.sub(r'\bbottomRight\s*:', 'bottomEnd:', inner)
        return 'BorderRadiusDirectional.only(' + inner + ')'
    content = re.sub(r'BorderRadiusDirectional\.only\((.*?)\)', replace_borderradius_args, content, flags=re.DOTALL)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    directory = '/Users/mahmoud/bmt_app/lib/apps/captain'
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
