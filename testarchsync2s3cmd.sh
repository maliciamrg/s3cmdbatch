#!/usr/bin/env bash
dtl=`date +%Y-%m-%d`
echo "$(date +"%F %T") archsync2s3cmd.sh v2" 
echo "$(date +"%F %T") start"

	echo "$(date +"%F %T") locked"
	FILE=s3cmdparam.ini
	exec 0<$FILE
	while read line <&0
	do 
		word=($(echo $line| tr ':' ' ' | sed 's/\r/ /g'))
		param1=${word[0]}
		param2=${word[1]}
		echo $param1 " - " $param2 
		echo $param1 " - " $param2 
		rm dryrunout-$param2.txt
		s3cmd sync $param1/$param2/ -p -r -v --delete-removed --dry-run s3://malicia-warehouse-$param2/ > dryrunout-$param2.txt
		nbdel=$(grep -w "delete" -c dryrunout-$param2.txt)
		nbupl=$(grep -w "upload" -c dryrunout-$param2.txt)
		nbfil=$(find $param1/$param2/ -type f | wc -l)
		percent=0.01
		nbfillvl=$(echo $percent $nbfil | awk '{printf "%4d\n",$param1*$param2}')
		echo "${param2} - $(date +"%F %T") nb upload to aws = $nbupl / nb del in aws = $nbdel / threshold del pour cancel = $nbfillvl / nb fichier repetoire = $nbfil"  
	done 

echo "$(date +"%F %T") stop"
