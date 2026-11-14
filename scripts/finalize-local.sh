#!/usr/bin/env bash
set -euo pipefail
ROOT=${TB323FU_BUILD_ROOT:-/root/tb323fu-build}
PROJECT=$(cd "$(dirname "$0")/.." && pwd)
DEST="$PROJECT/artifacts/2026-11-14"
for mode in baseline container; do
    "$ROOT/pahole-out/pahole" -C task_struct "$ROOT/out-$mode/vmlinux" > "$PROJECT/reports/$mode-task_struct.txt"
    cp "$ROOT/out-$mode/.config" "$PROJECT/reports/$mode.config"
    mkdir -p "$DEST/$mode"
    cp "$ROOT/out-$mode/arch/arm64/boot/Image" "$ROOT/out-$mode/vmlinux" "$ROOT/out-$mode/Module.symvers" "$DEST/$mode/"
    cat "$ROOT/out-$mode/include/config/kernel.release" > "$PROJECT/reports/$mode-kernel-release.txt"
    sha256sum "$ROOT/out-$mode/arch/arm64/boot/Image" "$ROOT/out-$mode/vmlinux" "$ROOT/out-$mode/Module.symvers" > "$PROJECT/reports/$mode-sha256.txt"
done
set +e
python3 "$PROJECT/scripts/compare-builds.py" "$ROOT/out-baseline" "$ROOT/out-container" --vendor-symbols "$PROJECT/reports/vendor-adsp-symbols.txt" > "$PROJECT/reports/abi-comparison.json"
ABI=$?
python3 "$PROJECT/scripts/inspect-artifacts.py" "$ROOT" "$PROJECT/reports" > "$PROJECT/reports/artifact-inspection.json"
LAYOUT=$?
set -e
printf 'ABI_STATUS=%s\nLAYOUT_STATUS=%s\n' "$ABI" "$LAYOUT" | tee "$PROJECT/reports/validation-exit-status.txt"
(cd "$DEST" && sha256sum baseline/* container/*) > "$PROJECT/reports/artifact-sha256.txt"
sha256sum "$ROOT/downloads/common.tar.gz" "$ROOT/downloads/clang-r536225.tar.gz" "$ROOT/downloads/rust-1.82.0.tar.gz" "$PROJECT/downloads/bindgen" "$PROJECT/downloads/pahole-source.tar.gz" > "$PROJECT/reports/download-sha256.txt"
python3 "$ROOT/common/scripts/diffconfig" "$PROJECT/baseline/stock.config" "$ROOT/out-baseline/.config" > "$PROJECT/reports/baseline-config-diff.txt"
python3 "$ROOT/common/scripts/diffconfig" "$ROOT/out-baseline/.config" "$ROOT/out-container/.config" > "$PROJECT/reports/container-config-diff.txt"
echo 'Artifacts retained for research. This script does not approve flashing.'
