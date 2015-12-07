#!/usr/bin/env bash
dtl=`date +%Y-%m-%d`
logger_cmd="logger  -p local6.debug -t $0[$$]"
tmpfile="~/tmp/s3cmdbatch-sync.txt"
$logger_cmd "start"
(
    function quit {
        if [ -f $tmpfile ]; then
          file=$(ls -t "$tmpfile" | head -1)
          filestring=$(tail -n1 $file)
          numd=$((`expr index "$filestring" :` + 2))
          lend=$((`expr index "${filestring:$numd}" /` - 1))
          numf=$((`expr index "$filestring" [` - 1))
          tweet "archsync2s3cmd : backup en cours ${filestring:$numf} sur ${filestring:$numd:lend}"
        fi
    	exit 1
    }
    flock -n 200 || quit;
    $logger_cmd "locked"
	FILE=s3cmdparam.ini
	exec 0<$FILE
	while read line <&0
	do 
		word=($(echo $line| tr ':' ' ' | sed 's/\r/ /g'))
		param1=${word[0]}
		param2=${word[1]}
		$logger_cmd "${param2} <- $param1"
		rm dryrunout-$param2.txt
		sleep 5
		s3cmd sync $param1/$param2/ -p -r -v --delete-removed --dry-run s3://malicia-warehouse-$param2/ > dryrunout-$param2.txt
		sleep 5
		nbdel=$(grep -w "delete" -c dryrunout-$param2.txt)
		nbupl=$(grep -w "upload" -c dryrunout-$param2.txt)
		nbfil=$(find $param1/$param2/ -type f | wc -l)
		percent="0.01"
		#nbfillvl=$(echo $percent $nbfil | awk '{printf "%4d\n",$param1*$param2}')
        nbfillvl=($(echo "${nbfil} * ${percent}" | bc -l))
		$logger_cmd "${param2} nb upload to aws = ${nbupl} / nb del in aws = ${nbdel} / threshold del pour cancel = ${nbfillvl} / nb fichier repetoire = ${nbfil}"
		if (($nbupl <= 0)) ;	then
			 $logger_cmd "${param2} nothing "
		else
			if (($nbdel > $nbfillvl)) ;	then
				$logger_cmd "${param2} not done threshold delete"
            	tweet "archsync2s3cmd : trop de delete pour $param2 => $nbdel (nbdel) ,  $nbfillvl (threshold) "
			else
            	tweet "archsync2s3cmd : lancement backup pour $param2 => $nbupl (nbupload) , $nbdel (nbdel) "
				s3cmd sync $param1/$param2/ -p -r -v --delete-removed s3://malicia-warehouse-$param2/ >> $tmpfile  2>&1
				$logger_cmd "${param2} done"
				tweet "archsync2s3cmd : fin backup pour $param2"
			fi;
		fi;
	done 
	exec 0<&-
	$logger_cmd "unlocked"
) 200>archsync2s3cmd.lock
 $logger_cmd "stop"
