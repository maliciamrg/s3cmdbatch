#!/bin/bash
echo "$(date +"%F %T") start" >> "./log/${1}-log-`date +%Y-%m-%d`.txt"
s3cmd sync /media/$1/ -p -r -v --delete-removed --dry-run s3://malicia-warehouse-$1/ > dryrunout.txt
nbdel=$(grep -w "delete" -c dryrunout.txt)
nbupl=$(grep -w "upload" -c dryrunout.txt)
nbfil=$(find /media/$1/ -type f | wc -l)
percent=0.01
nbfillvl=$(echo $percent $nbfil | awk '{printf "%4d\n",$1*$2}')
echo "$(1) - $(date +"%F %T") nb upload to aws = $nbupl / nb del in aws = $nbdel / threshold del pour cancel = $nbfillvl / nb fichier repetoire = $nbfil" >> archsync2s3cmd.log
if [ "$nbdel" -gt "$nbfillvl" ]
then
	echo "-- trop de delete on stop --" >>  "./log/${1}-log-`date +%Y-%m-%d`.txt"
else
	s3cmd sync /media/$1/ -p -r -v --delete-removed s3://malicia-warehouse-$1/ >> "./log/${1}-log-`date +%Y-%m-%d`.txt"
	echo "$(1) - $(date +"%F %T") done" >> archsync2s3cmd.log
fi
echo "$(date +"%F %T") stop " >>  "./log/${1}-log-`date +%Y-%m-%d`.txt"

