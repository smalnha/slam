#!/bin/bash 

: ${DEST:=/mnt/share/toBackup/photos/2017}
: ${NORMPATH:=/mnt/share/archive/photos/normalize.sh}

mkdir -p $DEST

F="${1:-some.zip}"
D=`basename "$F" .zip`
unzip -d "$D" "$F"
cd "$D"
{
ls
$NORMPATH Md2Fn "IMG*.JPG IMG*.jpg DSC*.JPG DSC*.jpg DSC*.png DSC*.PNG" | . /dev/stdin ; ls -al
$NORMPATH Ts2Fn "IMG*.MOV" | source /dev/stdin; ls -al

#  echo "------------ Renaming jpg files"
#  exiv2 -v mv *.jpg
#  exiv2 -v mv *.JPG
#  
#  #ls -la --time-style=full-iso IMG*.JPG | while read A B C D E F G H FILE J K L; do NEW=$(date --date="$F $G"  "+%Y%m%d_%H%M%S"); [ -e "$NEW.jpg" ] && sleep 1 && NEW=$NEW-`date "+%s"` ; mv $FILE $NEW.jpg; done
#  
#  echo "------------ Renaming png files"
#  for P in *.png *.PNG; do 
#    if [ -e "$P" ]; then
#    PNGFILENAME=`exiv2 -px -K Xmp.photoshop.DateCreated "$P" | while read A B C D; do echo $D | tr -d ":-"; done`
#    if [ "$PNGFILENAME" ]; then
#  	  [ -e "$PNGFILENAME.png" ] && sleep 1 && PNGFILENAME=$PNGFILENAME-`date "+%s"`
#  	  echo mv -v "$P" "$PNGFILENAME".png
#    else
#       echo "PNGFILENAME=$PNGFILENAME for $P"
#    fi
#    fi
#  done

} > origFilenames.log
cd -
mv -v "$D" "$DEST"

[ -d DONE ] || mkdir DONE
mv "$F" DONE/

