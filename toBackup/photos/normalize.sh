#!/bin/bash


ensureUniqBaseFn(){
	[ "$1" == "is" ] && return 0  # to handle '___ is a function' printed by 'type' command
	local FN=$1
	local COUNT=0
	while filePatternExists "$FN.*"; do
		let COUNT=$COUNT+1
		FN=$1_$COUNT
		echo "Trying file $FN" >&2
	done
	echo "$FN"
}

filePatternExists(){
	[ "$1" == "is" ] && return 0  # to handle '___ is a function' printed by 'type' command
	#echo "Check filePatternExists: $1" >&2
	for F in $1; do
		## Check if the glob gets expanded to existing files.
		## If not, f here will be exactly the pattern above
		## and the exists test will evaluate to false.
		if [ -e "$F" ]; then
			return 0
		else
			return 1
		fi
		## This is all we needed to know, so we can break after the first iteration
		break
	done
}

getDirDate(){
	set -e
	local DIRYEAR DIRMON DIRDAY
	: ${DIRYEAR:=$(pwd | sed -n 's/.*\/photos\/\([0-9][0-9][0-9][0-9]\).*/\1/p' )}
	: ${DIRYEAR:=$(pwd | sed -n 's/.*\/\([0-9][0-9][0-9][0-9]\).*/\1/p' )}

	: ${DIRMON:=$(pwd | sed -n 's/.*\/\([0-9][0-9][0-9][0-9]\)-\([0-9]*\)-.*/\2/p' )}
	: ${DIRMON:=$(pwd | sed -n 's/.*\/\([0-9][0-9][0-9][0-9]\)-\([0-9]*\)\/.*/\2/p' )}
	: ${DIRMON:=$(pwd | sed -n 's/.*\/\([0-9][0-9][0-9][0-9]\)-\([0-9]*\)$/\2/p' )}
	: ${DIRMON:=06}

	: ${DIRDAY:=$(pwd | sed -n 's/.*\/\([0-9][0-9][0-9][0-9]\)-\([0-9]*\)-\([0-9]*\).*/\3/p' )}
	: ${DIRDAY:=01}

	case "$1" in
		exif) echo "$DIRYEAR:$DIRMON:$DIRDAY ${DEF_TIME:-01:00:00}" ;;
		fn) ensureUniqBaseFn "$DIRYEAR$DIRMON${DIRDAY}_${DEF_TIME:-010000}" ;;
		vars) echo "$DIRYEAR $DIRMON $DIRDAY" ;;
		*) echo "Usage: getDirDate vars|exif|fn" >&2; return 3 ;;
	esac
	set +e
}

getFileDate(){
	if [ -e "$2" ]; then
		local FPERMISSIONS FCOUNTA FUSER FGROUP FCOUNTB FDATE FTIME FZONE FFILE 
		read  FPERMISSIONS FCOUNTA FUSER FGROUP FCOUNTB FDATE FTIME FZONE FFILE < <(ls -l --time-style=full-iso "$2")
		#echo "$FDATE $FTIME $FFILE" >&2
		case "$1" in
			exif) date --date="$FDATE $FTIME"  "+%Y:%m:%d %X" ;;
			fnbase) date --date="$FDATE $FTIME" "+%Y%m%d_%H%M%S" ;;
			fn) ensureUniqBaseFn $(date --date="$FDATE $FTIME" "+%Y%m%d_%H%M%S") ;;
			vars) date --date="$FDATE $FTIME"  "+%Y %m %d %H %M %S" ;;
			*) echo "Usage: getFileDate vars|exif|fn onefilename" >&2; return 3 ;;
		esac
	else
		echo "File not found: $2 -- Usage: getFileDate vars|exif|fn onefilename" >&2
		return 1
	fi
}

getFilenameDate(){
	if [ -e "$2" ]; then
		local BASEFILE=${2%.*}
		local FN_YEAR=`echo "$BASEFILE" | cut -c 1-4`
		local FN_MON=`echo "$BASEFILE" | cut -c 5-6`
		local FN_DAY=`echo "$BASEFILE" | cut -c 7-8`
		local FN_H=`echo "$BASEFILE" | cut -c 10-11`
		local FN_M=`echo "$BASEFILE" | cut -c 12-13`
		local FN_S=`echo "$BASEFILE" | cut -c 14-15`
		local FN_SUFFIX=`echo "$BASEFILE" | cut -c 16-`
				
		case "$1" in
			exif) echo "$FN_YEAR:$FN_MON:$FN_DAY $FN_H:$FN_M:$FN_S" ;;
			vars) echo "$FN_YEAR $FN_MON $FN_DAY $FN_H $FN_M $FN_S $FN_SUFFIX" ;;
			*) echo "Usage: getFilenameDate vars|exif onefilename" >&2; return 3 ;;
		esac
	else
		echo "File not found: $2 -- Usage: getFilenameDate vars|exif onefilename" >&2
		return 1
	fi
}

getMetadataPhotoDate(){
	MD_KEY="Exif.Photo.DateTimeOriginal" getMetadataDate "$@"
}
getMetadataDate(){
	if [ -e "$2" ]; then
		local MD_DATETIMELINE=$(exiv2 -PE -K "${MD_KEY:=Exif.Photo.DateTimeOriginal}" "$2" 2>/dev/null)
		if [ "$MD_DATETIMELINE" ]; then
			local M_KEY M_TYPE M_LENGTH M_DATE M_TIME M_OTHER
			read  M_KEY M_TYPE M_LENGTH M_DATE M_TIME M_OTHER < <(echo "$MD_DATETIMELINE")

			local      MD_YR MD_MO MD_DY
			IFS=: read MD_YR MD_MO MD_DY < <(echo $M_DATE)
			[ "$MD_YR" ] || { echo "# No year in metadata: $2 -- $M_DATE $M_TIME" >&2; return 50; }
			[ "$MD_MO" ] || { echo "# No month in metadata: $2 -- $M_DATE $M_TIME" >&2; return 51; }
			[ "$MD_DY" ] || { echo "# No day in metadata: $2 -- $M_DATE $M_TIME" >&2; return 52; }
			[ "$MD_YR" ] && [ "$MD_YR" -lt 1900 ] && { echo "Invalid year in metadata: $2 -- $M_DATE $M_TIME" >&2; return 53; }

			local      MD_HR MD_MIN MD_SEC MD_SECSUFFIX
			IFS=: read MD_HR MD_MIN MD_SEC MD_SECSUFFIX < <(echo $M_TIME)
			[ "$MD_HR" ]  || { echo "# No hour in metadata: $2 -- $M_DATE $M_TIME" >&2; return 60; }
			[ "$MD_MIN" ] || { echo "# No minute in metadata: $2 -- $M_DATE $M_TIME" >&2; return 61; }
			[ "$MD_SEC" ] || { echo "# No second in metadata: $2 -- $M_DATE $M_TIME" >&2; return 62; }

			case "$1" in
				exif) echo "$M_DATE $M_TIME" ;;
				fnbase) echo "$MD_YR$MD_MO${MD_DY}_$MD_HR$MD_MIN${MD_SEC}" ;;
				fn) ensureUniqBaseFn "$MD_YR$MD_MO${MD_DY}_$MD_HR$MD_MIN${MD_SEC}" ;;
				vars) echo "$MD_YR $MD_MO $MD_DY $MD_HR $MD_MIN $MD_SEC $MD_SECSUFFIX" ;;
				*) echo "Usage: getMetadataDate vars|exif|fn onefilename" >&2; return 3 ;;
			esac
		else
			echo "No metadata found for '$MD_KEY' in $2" >&2
			return 2
		fi
	else
		echo "File not found: $2 -- Usage: getMetadataDate vars|exif|fn onefilename" >&2
		return 1
	fi
}

setMetadataDate(){
	echo "exiv2 -M \"set Exif.Photo.DateTimeOriginal '$1'\" \"$2\""
}

useImageMDToSetMD(){
	for F in ${1:-*.png *.PNG *.jpg *.JPG}; do
		if [ -e "$F" ]; then
			#echo "# Examining $F " >&2
			local IMD_DATE IMD_TIME
			read  IMD_DATE IMD_TIME < <(MD_KEY="Exif.Image.DateTime" getMetadataDate exif $F)
			local MD_YEAR MD_MON MD_DAY MD_TIME
			read  MD_YEAR MD_MON MD_DAY MD_TIME < <(getMetadataPhotoDate vars "$F")
			if [ "$IMD_DATE" ] && [ "$IMD_TIME" ]; then
				if [ -z "$MD_YEAR" ]; then
					echo "#    Setting date to $IMD_DATE $IMD_TIME for $F with $MD_YEAR:$MD_MON:$MD_DAY" >&2
					setMetadataDate "$IMD_DATE $IMD_TIME" "$F"
				elif [ "$FORCE" ]; then
					echo "#    Setting date to $IMD_DATE $IMD_TIME for $F with $MD_YEAR:$MD_MON:$MD_DAY" >&2
					setMetadataDate "$IMD_DATE $IMD_TIME" "$F"
				fi
			else
				echo "#   No Exif.Image.DateTime=$IMD_DATE $IMD_TIME for $F with $MD_YEAR:$MD_MON:$MD_DAY" >&2
			fi
			#echo "AFTER: $(exiv2 -PE -K "Exif.Photo.DateTimeOriginal" "$F" ) - $F"
		fi
	done
}

useDirToSetMD(){
	local LDIRYEAR LDIRMON LDIRDAY
	read  LDIRYEAR LDIRMON LDIRDAY < <(getDirDate vars)
	: ${DIRYEAR:=$LDIRYEAR}
	: ${DIRMON:=$LDIRMON}
	: ${DIRDAY:=$LDIRDAY}
	echo "Using DATE=$DIRYEAR-$DIRMON-$DIRDAY for `pwd`" >&2
	read -p "Press Enter within 5 seconds to continue; or a letter followed by ENTER to stop: " -t 5 SKIP
	[ "$SKIP" ] && { echo "SKIPPING `pwd`" >&2; return 11; }
	[ -z "$DIRYEAR" ] && { echo "!!! Could not get DIRYEAR for `pwd`" >&2; return 10; }

	for F in ${1:-*.png *.PNG *.jpg *.JPG}; do
		#echo "Examining $F" >&2
		if [ -e "$F" ]; then
			local MD_YEAR MD_MON MD_DAY MD_TIME
			read  MD_YEAR MD_MON MD_DAY MD_TIME < <(getMetadataPhotoDate vars "$F")
			if [ -z "$MD_YEAR" ]; then
				echo "#    Setting date to $DIRYEAR-$DIRMON-$DIRDAY for $F with $MD_YEAR:$MD_MON:$MD_DAY" >&2
				setMetadataDate "$DIRYEAR:$DIRMON:$DIRDAY 01:00:00" "$F"
			elif [ "$FORCE" ]; then
				if [ "$DIRYEAR" != "$MD_YEAR" ]; then
					echo "#    Setting date to $DIRYEAR-$DIRMON-$DIRDAY for $F with $MD_YEAR:$MD_MON:$MD_DAY" >&2
					setMetadataDate "$DIRYEAR:$DIRMON:$DIRDAY 01:00:00" "$F"
				elif [ "$DIRMON" != "$MD_MON" ]; then
					echo "#    Setting month to $DIRYEAR-$DIRMON-$DIRDAY for $F with $MD_YEAR:$MD_MON:$MD_DAY" >&2
					setMetadataDate "$DIRYEAR:$DIRMON:$DIRDAY 01:00:00" "$F"
				elif [ "$DIRDAY" != "$MD_DAY" ]; then
					echo "#    Setting day to $DIRYEAR-$DIRMON-$DIRDAY for $F with $MD_YEAR:$MD_MON:$MD_DAY" >&2
					setMetadataDate "$DIRYEAR:$DIRMON:$DIRDAY 01:00:00" "$F"
				fi
			fi
			#echo "AFTER: $(exiv2 -PE -K "Exif.Photo.DateTimeOriginal" "$F" ) - $F"
		fi
	done
}

useFNtoSetMD(){
		for FILE in ${1:-*.JPG *.jpg *.PNG *.png}; do if [ -e "$FILE" ]; then
  		   FN_YEAR=`echo "$FILE" | cut -c 1-4`
		   FN_MON=`echo "$FILE" | cut -c 5-6`
		   FN_DAY=`echo "$FILE" | cut -c 7-8`
		   [ "$FN_H" ] || FN_H=`echo "$FILE" | cut -c 10-11`
		   [ "$FN_M" ] || FN_M=`echo "$FILE" | cut -c 12-13`
		   [ "$FN_S" ] || FN_S=`echo "$FILE" | cut -c 14-15`
			EXIF_DATE="$FN_YEAR:$FN_MON:$FN_DAY $FN_H:$FN_M:$FN_S"

			local MD_YEAR MD_MON MD_DAY MD_H MD_M MD_S
			read  MD_YEAR MD_MON MD_DAY MD_H MD_M MD_S < <(getMetadataPhotoDate vars "$FILE")

		   echo [ "$EXIF_DATE" == "$MD_YEAR:$MD_MON:$MD_DAY $MD_H:$MD_M:$MD_S" ] >&2
		   if [ "$EXIF_DATE" == "$MD_YEAR:$MD_MON:$MD_DAY $MD_H:$MD_M:$MD_S" ]; then
		   	echo "#  Skipping $FILE with correct date: $EXIF_DATE" >&2
		   else
		   	echo "#    Setting date to $EXIF_DATE for $FILE with $MD_YEAR:$MD_MON:$MD_DAY $MD_H:$MD_M:$MD_S" >&2
		   	setMetadataDate "$EXIF_DATE" "$FILE"
		   fi
		fi; done
}

mvToUnique(){
	[ "$1" == "is" ] && return 0  # to handle '___ is a function' printed by 'type' command
	NEWFN=`ensureUniqBaseFn $2`
	mv -i "$1" "$NEWFN.${1##*.}"
	for F in ${1%.*}.*; do
		[ -e "$F" ] && mv -i "$F" "$NEWFN.${F##*.}"
	done
}

useMDtoSetFN(){
	type mvToUnique
	type ensureUniqBaseFn
	type filePatternExists
	for F in ${1:-*.png *.PNG *.jpg *.JPG}; do
		if [ -e "$F" ]; then
			local BASEFN
			read  BASEFN < <(getMetadataPhotoDate fnbase "$F")
			# if filename does not start with BASEFN, then rename it
			if [[ "$F" != "$BASEFN"* ]]; then
				echo "#   Rename \"$F\" to \"$BASEFN\"" >&2
				echo "mvToUnique \"$F\" \"$BASEFN\""
			fi
		fi
	done
}

useDirToSetFN(){
	type mvToUnique
	type ensureUniqBaseFn
	type filePatternExists

	local LDIRYEAR LDIRMON LDIRDAY
	read  LDIRYEAR LDIRMON LDIRDAY < <(getDirDate vars)
	: ${DIRYEAR:=$LDIRYEAR}
	: ${DIRMON:=$LDIRMON}
	: ${DIRDAY:=$LDIRDAY}
	echo "Using DATE=$DIRYEAR-$DIRMON-$DIRDAY for `pwd`" >&2

	for F in ${1:-MOV*}; do
		BASEFN=`ensureUniqBaseFn "$DIRYEAR$DIRMON$DIRDAY"`
		echo "#   Rename \"$F\" to \"$BASEFN\"" >&2
		echo "mvToUnique \"$F\" \"$BASEFN\""
	done
}

useTStoSetFN(){
	type mvToUnique
	type ensureUniqBaseFn
	type filePatternExists
	for F in ${1:-*.png *.PNG *.jpg *.JPG *.MOV}; do
		if [ -e "$F" ]; then
			local BASEFN
			read  BASEFN < <(getFileDate fnbase "$F")
			# if filename does not start with BASEFN, then rename it
			if [[ "$F" != "$BASEFN"* ]]; then
				echo "#   Rename \"$F\" to \"$BASEFN\"" >&2
				echo "mvToUnique \"$F\" \"$BASEFN\""
			fi
		fi
	done
}

findMissingDates(){
	local DIRYEAR DIRMON DIRDAY
	read  DIRYEAR DIRMON DIRDAY < <(getDirDate vars)
	for F in ${1:-*.png *.PNG *.jpg *.JPG}; do
      if [ -e "$F" ]; then
			local MD_YEAR MD_MON MD_DAY MD_TIME
			read  MD_YEAR MD_MON MD_DAY MD_TIME < <(getMetadataPhotoDate vars "$F")
			if [ "$MD_YEAR" != "$DIRYEAR" ]; then
				echo "#   WARN: MD_YEAR=$MD_YEAR != DIRYEAR=$DIRYEAR : $F with timestamp: $MD_YEAR/$MD_MON/$MD_DAY $MD_TIME "
			fi
		fi
	done
}

findMissingDatesRecurse(){
	find . -type d | while read D; do
		if [ -d "$D" ]; then
			echo "# Checking $D"
			pushd "$D" >/dev/null
			findMissingDates "$@"
			popd >/dev/null
		fi
	done
}

case "$1" in
	FIND) shift; findMissingDates "$@" ;;
	FINDALL) shift; findMissingDatesRecurse "$@" ;;
	LIST) shift; exiv2 -PIE ${1:-*.jpg *.JPG *.png *.PNG} 2>/dev/null ;;
	LISTDATES) shift; exiv2 -PIE ${1:-*.jpg *.JPG *.png *.PNG} 2>/dev/null | grep "DateTime" ;;
	SET) shift; exiv2 -M "set Exif.Photo.DateTimeOriginal \"$1\"" $2 ;;
	USEPSDATE) shift; 
		EXIF_DATE=$(exiv2 -px -K Xmp.photoshop.DateCreated "$1" | while read A B C D; do date --date="$D" "+%Y:%m:%d %X"; done)
		exiv2 -M "set Exif.Photo.DateTimeOriginal \"$EXIF_DATE\"" $1 
		unset EXIF_DATE
		;;
   USEFILEDATE) shift;
		ls -la --time-style=full-iso ${1:-*.JPG *.jpg *.PNG *.png} | while read A B C D E F G H FILE J K L; do 
         ORIGDATE=$(exiv2 -PE -K "Exif.Photo.DateTimeOriginal" "$FILE" 2>/dev/null )
			#echo "ORIGDATE=$ORIGDATE"
			if [ "$ORIGDATE" ]; then
				echo "Skipping $FILE with $ORIGDATE" 
			else
				EXIF_DATE=$(date --date="$F $G"  "+%Y:%m:%d %X")
				exiv2 -M "set Exif.Photo.DateTimeOriginal \"$EXIF_DATE\"" $FILE 
				#[ -f "$FILE" ] && exiv2 -M "set Exif.Photo.DateTimeOriginal \"$EXIF_DATE\"" $FILE 
			fi
		done
		;;
	Fn2Md)  shift; useFNtoSetMD "$@" ;;
	Dir2Md) shift; useDirToSetMD "$@" ;;
	Dir2Fn) shift; useDirToSetFN "$@" ;;
	Md2Fn)  shift; useMDtoSetFN "$@" ;;
	Ts2Fn)  shift; useTStoSetFN "$@" ;;
   *) echo "Running function: $@" >&2
		"$@"
	;;
esac


