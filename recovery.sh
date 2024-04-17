#!/bin/bash
team_id=$1
if [ "x$team_id" == "x" ]; then
		echo Missing team_id argument
		exit 1
fi
today=`date +%Y%m%d`
case $today in
	"20240416")
      	contest_id=challenge
		;;
	"20240417")
       	contest_id=dress
		;;
	"20240418")
       	contest_id=finals
		;;
  *)
	  echo Please update dates in $0; exit 2
esac
backup_dir=/backups/data/`date +%Y%m%d`
found=`find $backup_dir -name backup.${team_id}.zip -size +0 | sort | tail -1`
if [ "x$found" == "x" ]; then
    echo Could not find a backup.${team_id}.zip that was not empty
    exit 3
fi
echo Run: scp $found @team${team_id}:
echo Run: ansible-playbook --limit team${team_id} do_wf`echo $team_id | cut -b1-2`_${contest_id}.yml
echo Run: ssh team${team_id}
echo Comment: now extract zip under the teams new blank home dir,  and fix the ownership
echo run: unzip -d /home/team${team_id}
echo run: chown -R team${team_id} /home/team${team_id}

