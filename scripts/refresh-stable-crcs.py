#!/usr/bin/env python3
"""Refresh cached gendwarfksyms output when enabling Android stable mode.

Kbuild's saved CC command does not include KBUILD_GENDWARFKSYMS_STABLE.
Existing object files therefore need their generated CRC comments refreshed.
No object bytes or symbol definitions are changed.
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import re
import subprocess
import sys

root = Path(sys.argv[1])
tool = root / 'scripts/gendwarfksyms/gendwarfksyms'
jobs = []
for cmd in root.rglob('.*.o.cmd'):
    text = cmd.read_text()
    names = re.findall(r'^#SYMVER (\S+) ', text, re.M)
    if names:
        obj = cmd.with_name(cmd.name[1:-4])
        dwarf = obj.with_suffix('.gendwarfksyms.o')
        jobs.append((cmd, text, names, dwarf if dwarf.exists() else obj))

def refresh(job):
    cmd, text, names, obj = job
    out = subprocess.check_output([str(tool), '--stable', str(obj)],
                                  input='\n'.join(names)+'\n', text=True)
    if len(re.findall(r'^#SYMVER ', out, re.M)) != len(names):
        raise RuntimeError(f'CRC count changed: {obj}')
    new = re.sub(r'^#SYMVER .*\n?', '', text, flags=re.M).rstrip()+'\n'+out
    if new != text:
        cmd.write_text(new)
        # Force downstream archive/modpost/link steps without recompiling C.
        cmd.with_name(cmd.name[1:-4]).touch()
        return 1
    return 0

with ThreadPoolExecutor(max_workers=4) as pool:
    changed = sum(pool.map(refresh, jobs))
print(f'Stable CRC metadata checked: {len(jobs)} objects; refreshed: {changed}')
