#!/bin/bash

# processQueue.sh - Move media files when there are no active Plex streams.
# processQueue.sh 

# Variables
debug=false
workingDir="/home/jarvis/scripts/sabNZBDtoQueue"
logfile="$workingDir/dlq.log"
plexURL="localhost"
plexPort="32400"
plexToken=`cat $HOME/.config/tokens/plex.token`
plexAPI="http://$plexURL:$plexPort/status/sessions?X-Plex-Token=$plexToken"

# Create timestamp
ts() {
	date +'%Y-%m-%d %T'
}

# Write to log file - https://en.wikipedia.org/wiki/Box-drawing_character
log() {
	if [ $# -eq 0 ]
	then
		echo "║" >>$logfile
	elif [ "$1" == "CreateNewLog" ]
	then
		echo "╔═══════════════════════════════════════════════════════════════════════════════════════════════════" >$logfile
	elif [ "$1" == "NewDivider" ]
	then
		echo "╠═══════════════════════════════════════════════════════════════════════════════════════════════════" >>$logfile
	else
		echo "║ $(ts): $1" >>$logfile
	fi
}

# Check for active streams
check_active_streams() {
	sessions=`curl -s $plexAPI | grep "MediaContainer size" | awk -F'[\"]' '{print $2}'`
	if [[ $sessions -gt 0 ]]
	then
		activeSession=true
	elif [[ $sessions -eq 0 ]]
	then
		activeSession=false
	fi
}

update_radarr() {
	# curl -s localhost:PORT/api/command?name=RescanMovie&id=1&apikey=${apikey} &
	# curl -s localhost:PORT/api/command?name=RenameMovie&id=1&apikey=${apikey} &
	echo "uh"
}

transfer_file() {
	movieSourceDir="$1"

	log "NewDivider"

	for file in "${movieSourceDir}"/*
	do
		fileExt=${file##*.}
		case $fileExt in
		mkv | mp4)
			log "$file"
			;;
		*)
			log "$file"
			;;
		esac
	done

	# rsync -qP "test1" "test2" &
	# rsync -qp "$file" "$movieDestination" &
	# if completed then delete
}

# Check for log file and create if not found
if [[ ! -f "$logfile" ]]
then
	log "CreateNewLog"
fi

check_active_streams
log "NewDivider"

if [[ $activeSession == false ]]
then
	# Read queue file
	# process queue file
	echo "Do something..."
else
	log "Plex is currently streaming. Will try again soon."
fi