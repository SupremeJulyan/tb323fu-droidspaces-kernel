#!/usr/bin/env bash
set -euo pipefail
ROOT=${TB323FU_BUILD_ROOT:-/root/tb323fu-build}
PROJECT=$(cd "$(dirname "$0")/.." && pwd)
MODE=${1:?usage: build-local.sh baseline|container}
[[ "$MODE" == baseline || "$MODE" == container ]]
export PATH="$ROOT/pahole-out:$ROOT/clang/bin:$ROOT/rust/bin:$PATH"
export ARCH=arm64 LLVM=1
export KBUILD_GENDWARFKSYMS_STABLE=1
export LIBCLANG_PATH="$ROOT/clang/lib"
export KBUILD_BUILD_USER=kleaf KBUILD_BUILD_HOST=build-host
export KBUILD_BUILD_TIMESTAMP='Thu Aug 14 19:19:26 UTC 2025'
export KBUILD_BUILD_VERSION=1
export LOCALVERSION=-android16-5-g1750f757fabe-ab13938768
OUT="$ROOT/out-$MODE"
SRC="$ROOT/common-$MODE"
mkdir -p "$SRC" "$OUT" "$PROJECT/reports"
STAMP="$ROOT/prepared-$MODE.sha256"
FINGERPRINT=$({
  printf '%s\n' '1750f757fabea014ecc59d327c0c9d3c15ab1e6d' "$MODE"
  if [[ "$MODE" == container ]]; then cat "$PROJECT"/patches/*.patch; fi
} | sha256sum | cut -d' ' -f1)
if [[ ! -f "$STAMP" || "$(cat "$STAMP")" != "$FINGERPRINT" ]]; then
  rsync -a --delete "$ROOT/common/" "$SRC/"
  if [[ "$MODE" == container ]]; then
    for PATCH in "$PROJECT"/patches/*.patch; do
      git -C "$SRC" apply --check "$PATCH"
      git -C "$SRC" apply "$PATCH"
    done
  fi
  printf '%s\n' "$FINGERPRINT" > "$STAMP"
fi
cp "$PROJECT/baseline/stock.config" "$OUT/.config"
if [[ "$MODE" == container ]]; then
  "$SRC/scripts/config" --file "$OUT/.config" -e SYSVIPC -e POSIX_MQUEUE -e IPC_NS -e PID_NS -e DEVTMPFS -e USER_NS
fi
# Kleaf generates these files. Reconstruct from the source lists; record hashes.
python3 - "$SRC" "$OUT" <<'PY'
import pathlib,sys
s,o=map(pathlib.Path,sys.argv[1:])
symbols=set()
for p in (s/'gki/aarch64/symbols').rglob('*'):
    if p.is_file():
        for line in p.read_text().splitlines():
            line=line.strip()
            if line and not line.startswith(('#','[')): symbols.add(line)
if o.name == 'out-container':
    symbols.update(['init_ipc_ns', 'put_ipc_ns'])
(o/'abi_symbollist.raw').write_text('\n'.join(sorted(symbols))+'\n')
# modules.bzl at the pinned revision uses Python-compatible list/functions.
namespace={}
exec(compile((s/'modules.bzl').read_text(), 'modules.bzl', 'exec'), namespace)
names=namespace['get_gki_protected_modules_list']('arm64')
(o/'protected_module_names_list').write_text('\n'.join(pathlib.Path(n).stem for n in names)+'\n')
PY
make -C "$SRC" O="$OUT" olddefconfig
grep -qx 'CONFIG_RUST=y' "$OUT/.config"
grep -qx 'CONFIG_GENDWARFKSYMS=y' "$OUT/.config"
grep -qx 'CONFIG_CFI_CLANG=y' "$OUT/.config"
cp "$OUT/.config" "$PROJECT/reports/$MODE.config"
python3 "$PROJECT/scripts/refresh-stable-crcs.py" "$OUT"
make -C "$SRC" O="$OUT" -j"${JOBS:-4}" Image vmlinux modules 2>&1 | tee "$PROJECT/reports/$MODE-build.log"
sha256sum "$OUT/arch/arm64/boot/Image" "$OUT/vmlinux" "$OUT/Module.symvers" > "$PROJECT/reports/$MODE-sha256.txt"
pahole -C task_struct "$OUT/vmlinux" > "$PROJECT/reports/$MODE-task_struct.txt"
pahole -C ipc_namespace "$OUT/vmlinux" > "$PROJECT/reports/$MODE-ipc_namespace.txt" || true
