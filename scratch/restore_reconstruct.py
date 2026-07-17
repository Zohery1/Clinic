import os
import re

log_path = r"C:\Users\Body\.gemini\antigravity\brain\3cdcb2f3-9e2b-4697-97b9-7f6d8555089e\.system_generated\tasks\task-476.log"

def parse_and_reconstruct():
    with open(log_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    reconstructed_lines = []
    current_entry = ""
    
    # We want to reconstruct lines that were wrapped by the console.
    # A line that starts with "lib\" is a new entry.
    # A line that doesn't start with "lib\" is a continuation of the previous entry.
    for line in lines:
        clean_line = re.sub(r'^\d+:\s*', '', line).strip()
        if not clean_line:
            continue
        if clean_line.lower().startswith('lib\\'):
            if current_entry:
                reconstructed_lines.append(current_entry)
            current_entry = clean_line
        else:
            if current_entry:
                current_entry += " " + clean_line
            else:
                current_entry = clean_line
                
    if current_entry:
        reconstructed_lines.append(current_entry)
        
    entries = []
    pattern = re.compile(r'^(lib\\[^\s:]+\.dart):(\d+):(.*)$', re.IGNORECASE)
    
    for entry in reconstructed_lines:
        match = pattern.match(entry)
        if match:
            filepath = match.group(1)
            line_num = int(match.group(2))
            content = match.group(3)
            
            # Find float value in withValues(alpha: X)
            alpha_match = re.search(r'withValues\(\s*alpha:\s*([a-zA-Z0-9._()+\-*\/]+)\)', content)
            if alpha_match:
                alpha_val = alpha_match.group(1)
                entries.append((filepath, line_num, alpha_val))
            else:
                print(f"Failed to find withValues in: {entry}")
                
    return entries

def restore():
    entries = parse_and_reconstruct()
    print(f"Reconstructed {len(entries)} entries.")
    
    # Sort entries by line number descending so we don't mess up line numbers if we edit (though we only replace in-place)
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
            idx = line_num - 1
            if idx >= len(lines):
                print(f"Warning: line {line_num} out of bounds for {filepath}")
                continue
                
            original_line = lines[idx]
            if 'withOpacity()' in original_line:
                # Replace the empty withOpacity() with withOpacity(alpha_val)
                lines[idx] = original_line.replace('withOpacity()', f'withOpacity({alpha_val})')
                updated_count += 1
            else:
                # If there are multiple empty withOpacity() on the same line, replace them one by one
                # E.g. in reports_screen.dart line 1573: colors: [color.withOpacity(), color.withOpacity()]
                # If the original line had multiple withValues, let's replace all of them with alpha_val
                # But wait, did they have different alpha values? E.g. withValues(alpha: 0.18) and withValues(alpha: 0.0)
                # Let's check how many empty withOpacity() are on this line
                count_empty = original_line.count('withOpacity()')
                if count_empty > 0:
                    # Let's see if we have multiple updates for the same line
                    # Wait, in the log, they would show up as separate entries or a single entry?
                    # Let's check: if there is a single entry for that line, it might contain both withValues.
                    # Let's print warning or handle it by finding the original alpha values from the log content
                    pass
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"Restored {updated_count} occurrences in {filepath}")

if __name__ == '__main__':
    restore()
