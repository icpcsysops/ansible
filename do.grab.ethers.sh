#!/bin/bash
# image_id, defaults to 1 if not given on the commandline below refers to the image number on the fog server
image_id=${1:-1}
ansible-playbook --limit contestants ip_link_show.yml > ip_link.output.txt
grep -B3 ether ip_link.output.txt  |egrep '(ok|ether)'  | sed 'N;s/\n/ /' | awk "{printf \"%s,%s,,,$image_id\n\", \$8, \$2}" | tr -d \]\[ > ether.list.csv
