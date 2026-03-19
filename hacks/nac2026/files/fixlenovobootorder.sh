#!/bin/bash
thinklmi=/sys/class/firmware-attributes/thinklmi

echo icpc > $thinklmi/authentication/Admin/current_password

# Ensure it's set to follow the boot order, so we can use efibootmgr to configure next boot
echo 'Boot Order' > $thinklmi/attributes/Firstbootdevice/current_value


# Figure out which boot item the internal disk is
local_disk=$(efibootmgr | grep -i ubuntu | cut -f1 -d' ' | sed 's/Boot//' | tr -d '*')
# And make sure that's the default boot element
efibootmgr -o $local_disk

# This doesn't actually work...
#echo 'M.2 Drive 1:Network 1;' > $thinklmi/attributes/BootOrder/current_value

