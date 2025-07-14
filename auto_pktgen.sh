#!/usr/bin/env bash
#
# Minimal Pktgen launcher.
# Assumes:
#   • The NIC (0000:17:00.0) is already bound to vfio-pci
#   • Huge pages are mounted
#   • $HOME/Pktgen-DPDK/Builddir/app/pktgen exists and is executable
#   • $HOME/dpdk variables are already exported if you need them
#   • Link is UP before you run this script
#
set -euo pipefail

PKTGEN_BIN="$HOME/Pktgen-DPDK/Builddir/app/pktgen"
LUA_SCRIPT="$PWD/auto_test.lua"          # this dir holds the Lua file
LOG="pktgen_$(date +%Y%m%d_%H%M%S).log"  # timestamped console log

echo "Launching Pktgen; console will be saved to: $LOG"
RATE="${RATE:-10}"

sudo "$PKTGEN_BIN" -l 6-8 -n 4 -- \
     -m "[7:8].0" -f "$LUA_SCRIPT" -P | tee "$LOG"

echo "Run complete. Result line:"
grep '^RESULT:' "$LOG" || echo "(no RESULT line found — check $LOG)"

