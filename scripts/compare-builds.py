#!/usr/bin/env python3
"""Fail closed on exported symbol drift or missing container config."""
import argparse
import json
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('baseline', type=Path)
p.add_argument('container', type=Path)
p.add_argument('--vendor-symbols', type=Path)
a = p.parse_args()

def symbols(path):
    result = {}
    for line in path.read_text().splitlines():
        fields = line.split()
        if len(fields) >= 2:
            result[fields[1]] = fields[0].lower()
    return result

base = symbols(a.baseline / 'Module.symvers')
new = symbols(a.container / 'Module.symvers')
changed = sorted(k for k in base if k in new and base[k] != new[k])
removed = sorted(base.keys() - new.keys())
config = (a.container / '.config').read_text().splitlines()
required = ['SYSVIPC', 'POSIX_MQUEUE', 'IPC_NS', 'PID_NS', 'DEVTMPFS',
            'USER_NS', 'MODVERSIONS', 'CFI_CLANG', 'ARM64_4K_PAGES']
missing = [k for k in required if f'CONFIG_{k}=y' not in config]
vendor_failures = []
if a.vendor_symbols:
    for name, crc in symbols(a.vendor_symbols).items():
        # A vendor module may also depend on other vendor modules. Those cannot
        # be validated from the GKI symbol table and remain explicitly unresolved.
        if name in new and new[name] != crc:
            vendor_failures.append(name)
    unresolved = sorted(symbols(a.vendor_symbols).keys() - new.keys())
else:
    unresolved = ['vendor symbol inventory not supplied']
result = dict(changed_crcs=changed, removed_symbols=removed,
              missing_config=missing, vendor_crc_mismatches=vendor_failures,
              unresolved_vendor_symbols=unresolved,
              hardware_tested=False)
print(json.dumps(result, indent=2))
raise SystemExit(bool(changed or removed or missing or vendor_failures or unresolved))
