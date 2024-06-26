#!/bin/bash
# Run this from the contest directory where there is a teams.json and an organizations directory

mkdir -p printsrv/UniversityNames printsrv/Logos
tempscript=$(mktemp)

# write out university names
cat teams.json | jq -r '.[] | ("echo \"" + .display_name +  "\" > printsrv/UniversityNames/team" + .id + ".txt")' > $tempscript
bash -ex $tempscript

# copy university logos to be named by team id
cat teams.json | jq -r '.[] | ("cp organizations/" + .organization_id +  "/logo.png printsrv/Logos/team" + .id + ".png")' > $tempscript
bash -ex $tempscript

# cleanup
rm $tempscript

tar czvf printsrv.tar.gz -C printsrv UniversityNames Logos
