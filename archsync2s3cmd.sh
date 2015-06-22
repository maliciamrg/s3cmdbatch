#!/bin/bash
echo "$(date +"%F %T")"
s3cmd sync /media/$1/ -p -r -v --delete-removed --dry-run s3://malicia-warehouse-$1/ > dryrunout.txt
nbdel=$(grep -w "delete" -c dryrunout.txt)
nbfil=$(find /media/$1/ -type f | wc -l)
percent=0.01
nbfillvl=$(echo $percent $nbfil | awk '{printf "%4d\n",$1*$2}')
echo "nb del = $nbdel / nb fichier lvl = $nbfillvl / nb fichier = $nbfil"
if [ "$nbdel" -gt "$nbfillvl" ]
then
	echo "-- trop de delete on stop --"
else
	s3cmd sync /media/$1/ -p -r -v --delete-removed s3://malicia-warehouse-$1/
fi
echo "$(date +"%F %T")"

