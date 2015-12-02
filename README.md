# s3cmdbatch

## the idea
have a bucket for each /media directory where the backup is needed

ex : backup /media/html in bucket s3://malicia-warehouse-html .... where `malicia-warehouse-` is my bucket fixe name 

## launch 
`sh archsync2s3cmd.sh warehouse_name`

launch a sync action between /media/**warehouse_name** and s3://malicia-warehouse-**warehouse_name**

## detail

first a sync `--dry-run` between /media/**warehouse_name** and s3://malicia-warehouse-**warehouse_name**

if more than 1% of file is marked for delete , the script stop

see in script for `percent=0.01`

if all is ok the script do a `s3cmd sync -p -r -v --delete-removed ` more info on parameter see [s3tools usage](http://s3tools.org/usage)

## log

action do on S3 bucket on aws in ./log/**warehouse_name**-log-`date +%Y-%m-%d`.txt

minimal centralize log of script in archsync2s3cmd.log

## tip
for long time backup use the s3 lifecyle rules and make `Transition to Glacier 0 days from object creation date`

