#!/bin/bash
ansible-playbook --limit contestants ip_link_show.yml > ip_link.output.txt
#ansible-playbook --limit team4600* ip_link_show.yml > ip_link.output.txt
# 10 below refers to the image number on the fog server
grep -B3 ether ip_link.output.txt  |egrep '(ok|ether)'  | sed 'N;s/\n/ /' | awk '{printf "%s,%s,,,10\n", $8, $2}' | tr -d \]\[ > ether.list.csv
