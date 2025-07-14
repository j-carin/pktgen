------------------------------------------------------------------
-- Make Pktgen.lua visible
local PKTGEN_HOME = os.getenv("PKTGEN_HOME") or (os.getenv("HOME") .. "/Pktgen-DPDK")
package.path = package.path .. ";" .. PKTGEN_HOME .. "/app/?.lua"
require "Pktgen"                     -- creates global pktgen
------------------------------------------------------------------

-- Parameters ----------------------------------------------------
local PORT      = "0"
local RATE      = tonumber(os.getenv("RATE") or "10")
local PKT_SIZE  = 64
local DST_MAC   = "40:a6:b7:c3:3e:d0"
local SRC_IP    = "10.10.1.1/32"
local DST_IP    = "10.10.1.2"
local DST_PORT  = 8000
------------------------------------------------------------------

-- 1. Wait until the PHY is up --------------------------------------
while true do
    local state = pktgen.linkState(PORT)[tonumber(PORT)]    -- string: "<--Down-->" or "<UP-...>"
    printf("Link state: %s\n", state)
    if state:find("UP") then break end
    pktgen.delay(1000)
end
print("Link is UP — applying settings")

-- 2. Apply settings (no stop/ start yet) ------------------------
pktgen.set_mac (PORT, "dst", DST_MAC)
pktgen.set_ipaddr(PORT, "src", SRC_IP)
pktgen.set_ipaddr(PORT, "dst", DST_IP)
pktgen.set_proto(PORT, "udp")
pktgen.set     (PORT, "dport", DST_PORT)
pktgen.set     (PORT, "size",  PKT_SIZE)
pktgen.set     (PORT, "rate",  RATE)
pktgen.set     (PORT, "count", 0)          -- continuous

-- 3. Start traffic and wait 30 s --------------------------------
printf("=== Traffic %d %% ===\n", RATE)
pktgen.start(PORT)

-- Show link state immediately after start
printf("Link state after start: %s\n",
       pktgen.linkState(PORT)[tonumber(PORT)])

-- Check if link dropped after start
if pktgen.linkState(PORT)[tonumber(PORT)]:find("UP") == nil then
    printf("ERROR: link dropped after start\n")
end

pktgen.delay(30000)
pktgen.stop (PORT)

-- 4. One-line summary -------------------------------------------
local tot  = pktgen.portStats(PORT, "port")[tonumber(PORT)]
local rate = pktgen.portStats(PORT, "rate")[tonumber(PORT)]
local tx_mbps = (rate.tx_bps or 0) / 1e6
local rx_mbps = (rate.rx_bps or 0) / 1e6
printf("RESULT: TxPkts=%d  RxPkts=%d  TxMbps=%.2f  RxMbps=%.2f\n",
       tot.opackets or 0, tot.ipackets or 0, tx_mbps, rx_mbps)

pktgen.quit()