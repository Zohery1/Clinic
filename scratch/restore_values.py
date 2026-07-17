import os
import re

log_path = r"C:\Users\Body\.gemini\antigravity\brain\3cdcb2f3-9e2b-4697-97b9-7f6d8555089e\.system_generated\tasks\task-476.log"

def parse_log(path):
    # Regex to match: filepath:line_num: content
    # Note that the line number is followed by a colon.
    pattern = re.compile(r'^(lib\\[^\s:]+\.dart):(\d+):(.*)$', re.IGNORECASE)
    
    entries = []
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        # Strip line numbers prefixed by the logger if any (e.g. "12: ")
        clean_line = re.sub(r'^\d+:\s*', '', line).strip()
        match = pattern.match(clean_line)
        if match:
            filepath = match.group(1)
            line_num = int(match.group(2))
            content = match.group(3)
            
            # Find float value in withValues(alpha: X)
            alpha_match = re.search(r'withValues\(\s*alpha:\s*([0-9.]+)\)', content)
            if alpha_match:
                alpha_val = alpha_match.group(1)
                entries.append((filepath, line_num, alpha_val))
            else:
                # If wrapped, look at the next line
                if i + 1 < len(lines):
                    next_line_clean = re.sub(r'^\d+:\s*', '', lines[i+1]).strip()
                    # Check if next line contains the float value
                    float_match = re.match(r'^([0-9.]+)\)', next_line_clean)
                    if float_match:
                        alpha_val = float_match.group(1)
                        entries.append((filepath, line_num, alpha_val))
    return entries

def restore():
    entries = parse_log(log_path)
    print(f"Parsed {len(entries)} entries from log.")
    
    # Sort entries by line number descending so we don't mess up line numbers if we edit (though we only replace in-place)
    # Group by file
    files_to_restore = {}
    for filepath, line_num, alpha_val in entries:
        files_to_restore.setdefault(filepath, []).append((line_num, alpha_val))
        
    for filepath, updates in files_to_restore.items():
        if not os.path.exists(filepath):
            print(f"File not found: {filepath}")
            continue
            
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        updated_count = 0
        for line_num, alpha_val in updates:
            # 1-indexed to 0-indexed
            idx = line_num - 1
            if idx >= len(lines):
                print(f"Warning: line {line_num} out of bounds for {filepath}")
                continue
                
            original_line = lines[idx]
            # Replace empty withOpacity() with withOpacity(alpha_val) on this line
            if 'withOpacity()' in original_line:
                lines[idx] = original_line.replace('withOpacity()', f'withOpacity({alpha_val})')
                updated_count += 1
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"Restored {updated_count} occurrences in {filepath}")

if __name__ == '__main__':
    restore()
