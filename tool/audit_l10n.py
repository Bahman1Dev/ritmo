import os
import re
import json

def run_audit():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    lib_dir = os.path.join(repo_root, 'lib')
    arb_path = os.path.join(lib_dir, 'l10n', 'app_fa.arb')

    arb_values = set()
    if os.path.exists(arb_path):
        with open(arb_path, 'r', encoding='utf-8') as f:
            arb_keys = json.load(f)
            arb_values = set(v for k, v in arb_keys.items() if isinstance(v, str))

    pattern = re.compile(r"""'([^'\n]*[\u0600-\u06FF]+[^'\n]*)'|"([^"\n]*[\u0600-\u06FF]+[^"\n]*)"=""")

    cat_a_presentation = 0
    cat_b_data_logic = 0
    cat_a_files = {}
    cat_b_files = {}

    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                rel_path = os.path.relpath(filepath, lib_dir)
                is_presentation = 'presentation' in rel_path.split(os.sep)

                with open(filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    for line in lines:
                        line_clean = line.strip()
                        if line_clean.startswith('//') or line_clean.startswith('/*') or line_clean.startswith('*'):
                            continue
                        matches = pattern.findall(line)
                        for m in matches:
                            val = m[0] or m[1]
                            if not val:
                                continue
                            if is_presentation:
                                cat_a_presentation += 1
                                cat_a_files[rel_path] = cat_a_files.get(rel_path, 0) + 1
                            else:
                                cat_b_data_logic += 1
                                cat_b_files[rel_path] = cat_b_files.get(rel_path, 0) + 1

    total = cat_a_presentation + cat_b_data_logic
    print("==========================================")
    print("       RITMO L10N AUDIT REPORT           ")
    print("==========================================")
    print(f"Total Hardcoded Persian Strings: {total}")
    print(f"Category A (Presentation UI Only): {cat_a_presentation} ({(cat_a_presentation/total)*100:.1f}%)")
    print(f"Category B (Data / Logic / Seed / Enum): {cat_b_data_logic} ({(cat_b_data_logic/total)*100:.1f}%)")
    print("\n--- Category A (Top Presentation Files) ---")
    for f, c in sorted(cat_a_files.items(), key=lambda x: x[1], reverse=True)[:10]:
        print(f"  {f}: {c}")

    print("\n--- Category B (Top Data/Logic Files) ---")
    for f, c in sorted(cat_b_files.items(), key=lambda x: x[1], reverse=True)[:10]:
        print(f"  {f}: {c}")

if __name__ == '__main__':
    run_audit()
