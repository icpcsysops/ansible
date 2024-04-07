#!/bin/bash
# wf2023 value
image_number=6
ansible-playbook --limit contestants ip_link_show.yml > ip_link.output.txt
grep -B3 ether ip_link.output.txt  |egrep '(ok|ether)'  | sed 'N;s/\n/ /' | awk '{printf "%s,%s,,,,$image_number\n", $7, $2}' | tr -d \]\[ > ether.list.txt
