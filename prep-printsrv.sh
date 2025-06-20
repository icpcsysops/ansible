#!/bin/bash
# Run this from the contest directory where there is a teams.json and an organizations directory

mkdir -p printsrv/UniversityNames printsrv/Logos printsrv/Pictures
tempscript=$(mktemp)

# write out university names
cat teams.json | jq -r '.[] | ("echo \"" + .display_name +  "\" > printsrv/UniversityNames/team" + .id + ".txt")' > $tempscript
bash -x $tempscript

# copy university logos to be named by team id
cat teams.json | jq -r '.[] | ("cp organizations/" + .organization_id +  "/logo.png printsrv/Logos/team" + .id + ".png")' > $tempscript
bash -x $tempscript

cat teams.json | jq -r '.[] | ("cp teams/" + .id +  "/photo.jpg printsrv/Pictures/team" + .id + ".jpg")' > $tempscript
bash -x $tempscript

# cleanup
rm $tempscript

tar czvf printsrv.tar.gz -C printsrv UniversityNames Logos Pictures

scp printsrv.tar.gz printsrv:/tmp
ssh printsrv 'tar -C /usr/share/cups/data -xf /tmp/printsrv.tar.gz'
