from pathlib import Path
import re, sys, zipfile

root = Path(__file__).resolve().parents[1]
problems=[]

for p in root.rglob("*"):
    if not p.is_file() or ".git" in p.parts:
        continue
    if p.name=="config.js":
        problems.append(f"Release must not contain production config.js: {p}")
    if p.suffix.lower() in {".sql",".js",".html",".md",".txt"}:
        text=p.read_text(encoding="utf-8",errors="ignore")
        if p.suffix.lower()==".sql":
            forbidden=[
                r"ON\s+ALL\s+TABLES\s+IN\s+SCHEMA\s+public",
                r"ON\s+ALL\s+SEQUENCES\s+IN\s+SCHEMA\s+public",
                r"ALTER\s+DEFAULT\s+PRIVILEGES",
                r"DROP\s+SCHEMA\s+public",
                r"DROP\s+OWNED\s+BY",
                r"REASSIGN\s+OWNED"
            ]
            for pat in forbidden:
                if re.search(pat,text,re.I):
                    problems.append(f"Forbidden schema-wide SQL in {p}: {pat}")
            other_project=re.findall(r'\b(?:TblP|P)(?!106)\d{1,3}[A-Za-z_]*',text)
            if other_project:
                problems.append(f"Possible cross-project object in {p}: {sorted(set(other_project))}")

if problems:
    print("PREFLIGHT FAILED")
    for x in problems: print("-",x)
    sys.exit(1)
print("PREFLIGHT OK")
