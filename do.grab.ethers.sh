#!/bin/bash
ansible-playbook --limit contestants ip_link_show.yml > ip_link.output.txt
grep -B3 ether ip_link.output.txt  |egrep '(ok|ether)'  | sed 'N;s/\n/ /' | awk '{printf "%s,%s,,,,2\n", $7, $2}' | tr -d \]\[ > ether.list.txt

