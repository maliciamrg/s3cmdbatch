#!/bin/bash
echo "debut "`date +%Y-%m-%d-%H-%M-%S`
s3cmd $* > `date +%Y-%m-%d-%H-%M-%S`.log 2>&1
echo "fin.  "`date +%Y-%m-%d-%H-%M-%S`

