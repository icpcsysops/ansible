#!/bin/bash
thinklmi=/sys/class/firmware-attributes/thinklmi

echo icpc > $thinklmi/authentication/Admin/current_password
# These don't exist anymore (as of 2025-05-23)
#echo ascii > $thinklmi/authentication/Admin/encoding
#echo us > $thinklmi/authentication/Admin/kbdlang

# Ensure it's set to follow the boot order, so we can use efibootmgr to configure next boot
echo 'Boot Order' > $thinklmi/attributes/Firstbootdevice/current_value

# This doesn't actually work...
#echo 'M.2 Drive 1:Network 1;' > $thinklmi/attributes/BootOrder/current_value

