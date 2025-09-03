#!/bin/bash
TARGET=${1:-"contestants"}
echo "TARGET of reimaging is \"$TARGET\""
echo "Continue?  (yes/NO)"
read key
if [ "$key" == "yes" ]; then
    ./fast-ansible -m shell -a "efibootmgr -n \$(efibootmgr | grep -E 'PXE BOOT|IPv4|Network Device' | head -n1 | awk '{print \$1}' | tr -d '[A-z*]')" "$TARGET"
    ./fast-ansible -m shell -a reboot "$TARGET"
fi
