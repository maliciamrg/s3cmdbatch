#!/usr/bin/env bash
dtl=`date +%Y-%m-%d`
echo "$(date +"%F %T") archsync2s3cmd.sh v2" 
echo "$(date +"%F %T") start"
	echo "$(date +"%F %T") locked"
	FILE=tests3cmdparam.ini
	exec 0<$FILE
	while read line <&0
	do 
		word=($(echo $line| tr ':' ' ' | sed 's/\r/ /g'))
		param1=${word[0]}
		param2=${word[1]}
		echo $param1 " - " $param2 
		echo $param1 " - " $param2 
		rm testdryrunout-$param2.txt
		sleep 5
		s3cmd --progress sync $param1/$param2/ -p -r -v --delete-removed --dry-run s3://malicia-warehouse-$param2/ > testdryrunout-$param2.txt 2>&1
		#exec('s3cmd --progress sync $param1/$param2/ -p -r -v --delete-removed --dry-run s3://malicia-warehouse-$param2/  2>&1', testdryrunout-$param2.txt); 
		sleep 5
		nbdel=$(grep -w "delete" -c testdryrunout-$param2.txt)
		nbupl=$(grep -w "upload" -c testdryrunout-$param2.txt)
		nbfil=$(find $param1/$param2/ -type f | wc -l)
		percent=0.01
		nbfillvl=$(echo $percent $nbfil | awk '{printf "%4d\n",$param1*$param2}')
		echo "${param2} - $(date +"%F %T") nb upload to aws = $nbupl / nb del in aws = $nbdel / threshold del pour cancel = $nbfillvl / nb fichier repetoire = $nbfil"  
		if (($nbupl <= 0)) ;	then
			echo "-- rien a trasferet on stop --"
			echo "${param2} - $(date +"%F %T") nothing " 
		else
			if (($nbdel > $nbfillvl)) ;	then
				echo "-- trop de delete on stop --" 
				echo "${param2} - $(date +"%F %T") not done threshold delete" 
			else
				echo "${param2} - $(date +"%F %T") done" 
			fi;
		fi;
	done 

echo "$(date +"%F %T") stop"
