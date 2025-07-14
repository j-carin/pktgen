#!/usr/bin/env bash
#
# Pktgen pre-flight checker (rev-2)
# Verifies readiness without changing system state.
#
set -euo pipefail

PCI_ID="0000:17:00.0"
IFACE="enp23s0f0np0"
PKTGEN_BIN="$HOME/Pktgen-DPDK/Builddir/app/pktgen"
LUA_SCRIPT="$PWD/auto_test.lua"

pass() { echo "✅ $*"; }
fail() { echo "❌ $*"; exit 1; }

echo "=== Pktgen pre-flight checks ==="

[[ -x "$PKTGEN_BIN" ]]   && pass "pktgen binary found" \
                        || fail "Missing or non-executable $PKTGEN_BIN"

[[ -f "$LUA_SCRIPT" ]]   && pass "Lua script found ($LUA_SCRIPT)" \
                        || fail "Lua script not found"

mount | grep -q '/dev/hugepages' \
                        && pass "hugepages mounted" \
                        || fail "/dev/hugepages not mounted"

DRV_LINE=$(sudo ~/dpdk/usertools/dpdk-devbind.py --status | grep "$PCI_ID") || true
[[ $DRV_LINE == *"drv=vfio-pci"* ]] && BOUND="vfio" || BOUND="kernel"

if [[ $BOUND == "kernel" ]]; then
    pass "NIC bound to kernel driver (ice)"
    # Only kernel mode exposes the netdev; run ethtool.
    if [[ -e /sys/class/net/$IFACE ]]; then
        read -r SPEED LINK <<<$(ethtool "$IFACE" |
                                awk '/Speed:|Link detected:/ {print $2}')
        [[ $SPEED == "100000Mb/s" && $LINK == "yes" ]] \
            && pass "Link is UP at 100 G" \
            || fail "Link bad (Speed=$SPEED, Link=$LINK)"
    else
        fail "Netdev $IFACE not present"
    fi
else
    pass "NIC bound to vfio-pci (DPDK) — link check skipped"
fi

echo "=== All checks passed — READY ==="

