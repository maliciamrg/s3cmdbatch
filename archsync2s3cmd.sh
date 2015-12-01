#!/usr/bin/env bash
dtl=`date +%Y-%m-%d`
echo "$(date +"%F %T") start" >> "./log/archsync2s3cmd-log-${dtl}.txt"
(
    flock -n 200 || exit 1;
	echo "$(date +"%F %T") locked" >> "./log/archsync2s3cmd-log-${dtl}.txt"

	FILE=s3cmdparam.ini
	exec 0<$FILE
	while read line <&0
	do 
		word=($(echo $line| tr ':' ' ' | sed 's/\r/ /g'))
		param1=${word[0]}
		param2=${word[1]}
		echo $param1 " - " $param2 >> "./log/archsync2s3cmd-log-${dtl}.txt"
		echo $param1 " - " $param2 >> "./log/archsync2s3cmd-log-${dtl}-s3cmd.txt"
		rm dryrunout.txt
		s3cmd sync $param1/$param2/ -p -r -v --delete-removed --dry-run s3://malicia-warehouse-$param2/ > dryrunout.txt
		nbdel=$(grep -w "delete" -c dryrunout.txt)
		nbupl=$(grep -w "upload" -c dryrunout.txt)
		nbfil=$(find $param1/$param2/ -type f | wc -l)
		percent=0.01
		nbfillvl=$(echo $percent $nbfil | awk '{printf "%4d\n",$param1*$param2}')
		echo "${param2} - $(date +"%F %T") nb upload to aws = $nbupl / nb del in aws = $nbdel / threshold del pour cancel = $nbfillvl / nb fichier repetoire = $nbfil"  >> "./log/archsync2s3cmd-log-${dtl}.txt"
		if $nbdel > $nbfillvl
		then
			echo "-- trop de delete on stop --" >> "./log/archsync2s3cmd-log-${dtl}-s3cmd.txt"
			echo "${param2} - $(date +"%F %T") not done threshold delete" >> "./log/archsync2s3cmd-log-${dtl}.txt"
		else
			s3cmd sync $param1/$param2/ -p -r -v --delete-removed s3://malicia-warehouse-$param2/ >> "./log/archsync2s3cmd-log-${dtl}-s3cmd.txt"
			echo "${param2} - $(date +"%F %T") done" >> "./log/archsync2s3cmd-log-${dtl}.txt"
		fi
	done 
	exec 0<&-
	echo "$(date +"%F %T") unlock "  >> "./log/archsync2s3cmd-log-${dtl}.txt"
) 200>archsync2s3cmd.lock
echo "$(date +"%F %T") stop" >> "./log/archsync2s3cmd-log-${dtl}.txt"
