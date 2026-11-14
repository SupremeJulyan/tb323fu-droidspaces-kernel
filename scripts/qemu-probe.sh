#!/usr/bin/env bash
set -euo pipefail
ROOT=${TB323FU_BUILD_ROOT:-/root/tb323fu-build}
PROJECT=$(cd "$(dirname "$0")/.." && pwd)
MODE=${1:?baseline or container or baseline-lkm}
[[ "$MODE" == baseline || "$MODE" == container || "$MODE" == baseline-lkm ]]
KERNEL_MODE=$MODE
FLAGS=()
INIT="$ROOT/probe-initramfs-$MODE"
mkdir -p "$INIT"/{dev,proc,sys,cgroup}
if [[ "$MODE" == baseline-lkm ]]; then
    KERNEL_MODE=baseline
    FLAGS=(-DWITH_LKM)
    for name in lkm4ctr devtmpfs_lkm; do
        mapfile -t matches < <(find "$PROJECT/downloads/lkm-android16-6.12" -name "$name-android16-6.12.ko")
        [[ ${#matches[@]} == 1 ]]
        cp "${matches[0]}" "$INIT/$name.ko"
    done
fi
"$ROOT/clang/bin/clang" --target=aarch64-linux-gnu -fuse-ld=lld -nostdlib -static -fno-stack-protector -fno-builtin -O2 "${FLAGS[@]}" "$PROJECT/scripts/probe-init.c" -o "$INIT/init"
[[ -e "$INIT/dev/console" ]] || mknod "$INIT/dev/console" c 5 1
[[ -e "$INIT/dev/ttyAMA0" ]] || mknod "$INIT/dev/ttyAMA0" c 204 64
(cd "$INIT" && find . -print0 | cpio --null -o -H newc --quiet) > "$ROOT/probe-initramfs-$MODE.cpio"
set +e
timeout 120 qemu-system-aarch64 -M virt -cpu max -smp 2 -m 1024 -nographic -no-reboot -nic none \
    -kernel "$ROOT/out-$KERNEL_MODE/arch/arm64/boot/Image" -initrd "$ROOT/probe-initramfs-$MODE.cpio" \
    -append 'console=ttyAMA0 earlycon=pl011,0x9000000 rdinit=/init nokaslr panic=-1' \
    > "$PROJECT/reports/$MODE-qemu.log" 2>&1
STATUS=$?
set -e
echo "qemu exit status: $STATUS"
grep -E 'TB323FU_QEMU|^(PASS|FAIL) ' "$PROJECT/reports/$MODE-qemu.log"
[[ "$STATUS" == 0 ]]
grep -q '^TB323FU_QEMU_PROBE_PASSED' "$PROJECT/reports/$MODE-qemu.log"
! grep -qE 'BUG:|Kernel panic|KASAN:|Oops:' "$PROJECT/reports/$MODE-qemu.log"
