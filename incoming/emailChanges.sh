#!/bin/bash

# put this script in a directory to monitor and add a cronjob

if [ -z "$1" ]; then
	echo "Usage: $0 notification@email.net"
	exit 1
fi

FROM_EMAIL="filesChanged@home"
TO_EMAIL="$1"

if ! [ -f referenceFile ]; then
	echo "Creating initial referenceFile"
	touch referenceFile
	exit
fi

NF=/tmp/newFiles-`date +%Y-%m-%d-%T`
find . -type f -newer referenceFile > $NF.txt
touch referenceFile

if [ -s "$NF.txt" ]; then
	{ # create a more detailed file listing
	cat $NF.txt | while read F; do 
		if [ -d "$F" ]; then 
			echo "Directory $F"; 
		else 
			ls -l "$F"; fi; 
		done
	} > $NF-stats.txt

	sendemail  -f "$FROM_EMAIL" -o tls=no -t "$TO_EMAIL" -u "$PWD changed - `date`" -o message-file="$NF.txt" -a "$NF-stats.txt"
fi

rm -f "$NF"

