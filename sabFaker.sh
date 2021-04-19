#!/bin/bash

## bash sabFaker.sh targetDirectory

## 1 The final directory of the job (full path)
## 2 The original name of the NZB file
## 3 Clean version of the job name (no path info and ".nzb" removed)
## 4 Indexer's report number (if supported)
## 5 User-defined category

# SabNZBD Arg 1: /home/staging/downloads/The Firm 1993 1080p BluRay DD5 1 x264-RDK123
# SabNZBD Arg 2: The.Firm.1993.1080p.BluRay.DD5.1.x264-RDK123.nzb
# SabNZBD Arg 3: The Firm 1993 1080p BluRay DD5 1 x264-RDK123
# SabNZBD Arg 4: 
# SabNZBD Arg 5: movies

scriptLoc="/home/jarvis/scripts/sabNZBDtoQueue/sabNZBDtoQueue.sh"
targetDir="$1"

for dir in "$targetDir"*
do
    one="$dir"
    two=`echo ${dir} | awk -F'/' '{ print $6 }'`
    three=`echo ${dir} | awk -F'/' '{ print $6 }'`
    four="1"
    five="movies"

    # echo "sf1: " $one
    # echo "sf2: " $two
    # echo "sf3: " $three
    # echo "sf4: " $four
    # echo "sf5: " $five

    # echo "$scriptLoc" "$one" "$two" "$three" "$four" "$five"
    bash "$scriptLoc" "$one" "$two" "$three" "$four" "$five" &
    wait $!
done