#!/usr/bin/env bash
dtl=`date +%Y-%m-%d`
echo "$(date +"%F %T") archsync2s3cmd.sh v2" >> "./log/archsync2s3cmd-log-${dtl}.txt"
echo "$(date +"%F %T") start" >> "./log/archsync2s3cmd-log-${dtl}.txt"
(
    function quit {
    	file=$(ls -t ./log/archsync2s3cmd-log-*-s3cmd.txt | head -1)
        filestring=$(tail -n1 $file)
        numd=$((`expr index "$filestring" :` + 2))
        lend=$((`expr index "${filestring:$numd}" /` - 1))
        numf=$((`expr index "$filestring" [` - 1))
        tweet "archsync2s3cmd : backup en cours ${filestring:$numf} sur ${filestring:$numd:lend}"
    	exit 1
    }
    flock -n 200 || quit;
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
		rm dryrunout-$param2.txt
		sleep 5
		s3cmd sync $param1/$param2/ -p -r -v --delete-removed --dry-run s3://malicia-warehouse-$param2/ > dryrunout-$param2.txt
		sleep 5
		nbdel=$(grep -w "delete" -c dryrunout-$param2.txt)
		nbupl=$(grep -w "upload" -c dryrunout-$param2.txt)
		nbfil=$(find $param1/$param2/ -type f | wc -l)
		percent=0.01
		nbfillvl=$(echo $percent $nbfil | awk '{printf "%4d\n",$param1*$param2}')
		echo "${param2} - $(date +"%F %T") nb upload to aws = $nbupl / nb del in aws = $nbdel / threshold del pour cancel = $nbfillvl / nb fichier repetoire = $nbfil"  >> "./log/archsync2s3cmd-log-${dtl}.txt"
		if (($nbupl <= 0)) ;	then
			echo "-- rien a trasferet on stop --" >> "./log/archsync2s3cmd-log-${dtl}-s3cmd.txt"
			echo "${param2} - $(date +"%F %T") nothing " >> "./log/archsync2s3cmd-log-${dtl}.txt"
		else
			if (($nbdel > $nbfillvl)) ;	then
				echo "-- trop de delete on stop --" >> "./log/archsync2s3cmd-log-${dtl}-s3cmd.txt"
				echo "${param2} - $(date +"%F %T") not done threshold delete" >> "./log/archsync2s3cmd-log-${dtl}.txt"
            	tweet "archsync2s3cmd : trop de delete pour $param2 => $nbdel (nbdel) ,  $nbfillvl (threshold) "
			else
            	tweet "archsync2s3cmd : lancement backup pour $param2 => $nbupl (nbupload) , $nbdel (nbdel) "
				s3cmd sync $param1/$param2/ -p -r -v --delete-removed s3://malicia-warehouse-$param2/ >> "./log/archsync2s3cmd-log-${dtl}-s3cmd.txt"  2>&1
				echo "${param2} - $(date +"%F %T") done" >> "./log/archsync2s3cmd-log-${dtl}.txt"
				tweet "archsync2s3cmd : fin backup pour $param2"
			fi;
		fi;
	done 
	exec 0<&-
	echo "$(date +"%F %T") unlocked "  >> "./log/archsync2s3cmd-log-${dtl}.txt"
) 200>archsync2s3cmd.lock
echo "$(date +"%F %T") stop" >> "./log/archsync2s3cmd-log-${dtl}.txt"
