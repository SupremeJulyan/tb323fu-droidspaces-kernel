#!/usr/bin/env python3
import argparse
import json
import re
import struct
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('build_root', type=Path)
p.add_argument('reports', type=Path)
a = p.parse_args()
results = {}
failures = []
layouts = {}
for mode in ('baseline', 'container'):
    image = a.build_root / f'out-{mode}/arch/arm64/boot/Image'
    with image.open('rb') as f:
        header = f.read(64)
    offset, size, flags = struct.unpack_from('<QQQ', header, 8)
    ok = header[56:60] == b'ARM\x64' and ((flags >> 1) & 3) == 1 and size > 0
    results[mode] = dict(image_header_valid=ok, declared_size=size,
                         file_size=image.stat().st_size, text_offset=offset,
                         page_size=4096 if ((flags >> 1) & 3) == 1 else None)
    if not ok:
        failures.append(f'{mode}: invalid ARM64 4K Image header')
    text = (a.reports / f'{mode}-task_struct.txt').read_text()
    members = {}
    for name, at, count in re.findall(r'\b(\w+)(?:\[[^\]]+\])?;\s*/\*\s*(\d+)\s+(\d+)\s*\*/', text):
        members[name] = (int(at), int(count))
    match = re.search(r'/\* size:\s*(\d+)', text)
    if not match:
        failures.append(f'{mode}: task_struct size unavailable')
    layouts[mode] = dict(size=int(match[1]) if match else None, members=members)

if layouts['baseline']['size'] != layouts['container']['size']:
    failures.append('task_struct total size changed')
for name in ('prio', 'normal_prio', 'rt_priority', 'se', 'rt', 'dl', 'pid', 'tgid', 'real_cred', 'cred', 'comm', 'thread'):
    before = layouts['baseline']['members'].get(name)
    after = layouts['container']['members'].get(name)
    if before is None or before != after:
        failures.append(f'task_struct field changed or unresolved: {name}: {before} -> {after}')
results['task_struct'] = layouts
results['failures'] = failures
print(json.dumps(results, indent=2))
raise SystemExit(bool(failures))
