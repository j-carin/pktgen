#!/bin/bash

sudo modprobe uio
sudo modprobe uio_pci_generic
sudo ip link set enp23s0f0np0 down
sudo dpdk-devbind.py -b uio_pci_generic 0000:17:00.0
echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
sudo mkdir -p /mnt/huge
sudo mount -t hugetlbfs nodev /mnt/huge

echo "Run pktgen with:"
echo "sudo \$HOME/Pktgen-DPDK/Builddir/app/pktgen -l 6-8 -n 4 -- -m \"[7:8].0\" -P"
echo
echo "Pktgen commands:"
cat pktgen_commands.txt