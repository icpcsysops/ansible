#!/bin/bash
#streams=$(curl https://{{ cds_credentials }}@172.24.0.207/api/contests/{{ cds_contest }}/teams | jq -r '.[] | .{{ stream_type }}[0].href')
webcams=$(curl https://{{ cds_credentials }}@172.24.0.207/api/contests/{{ cds_contest }}/teams | jq -r '.[] | .webcam[0].href')
desktops=$(curl https://{{ cds_credentials }}@172.24.0.207/api/contests/{{ cds_contest }}/teams | jq -r '.[] | .desktop[0].href')
#webcams=""

stream_count={{ stream_count }}
index={{ host_index }}

start=$(( index * stream_count + 1 ))
end=$(( start + stream_count + 1))
echo "Running streams $start - $end"

streams=$(echo "$streams" | sed -n "$start,${end}p")
streams=$(echo "$webcams\n$desktops" | sed -n "$start,${end}p")

echo "$streams"
while IFS= read -r stream_url; do
  echo "$stream_url"
  timeout {{stream_duration}} curl -o /dev/null $stream_url &
done <<< "$streams"

# Wait for them to finish
wait $(jobs -p)
