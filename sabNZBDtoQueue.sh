#!/bin/bash

# sabNZBDtoQueue.sh - Add media files to a queue to be processed by a cron job.
# sabNZBDtoQueue.sh $sabArg1 $sabArg2 $sabArg3 $sabArg4 $sabArg5

# Variables
workingDir="/home/jarvis/scripts/sabNZBDtoQueue"
logFile="$workingDir/dlq.log"
queueFile="$workingDir/queue.csv"

# Create timestamp
ts() {
	date +'%Y-%m-%d %T'
}

# Print SabNZBD variables
sabDebug() {
	log "NewDivider"
	log "SAB_SCRIPT: $SAB_SCRIPT (The name of the current script)"
	log "SAB_NZO_ID: $SAB_NZO_ID (The unique ID assigned to the job)"
	log "SAB_FINAL_NAME: $SAB_FINAL_NAME (The name of the job in the queue and of the final folder)"
	log "SAB_FILENAME: $SAB_FILENAME (The NZB filename (after grabbing from the URL))"
	log "SAB_COMPLETE_DIR: $SAB_COMPLETE_DIR (The whole path to the output directory of the job)"
	log "SAB_PP_STATUS: $SAB_PP_STATUS (Was post-processing succesfully completed (repair and/or unpack, if enabled by user))"
	log "SAB_CAT: $SAB_CAT (What category was assigned)"
	log "SAB_BYTES: $SAB_BYTES (Total number of bytes)"
	log "SAB_BYTES_TRIED: $SAB_BYTES_TRIED (How many bytes of the total bytes were tried)"
	log "SAB_BYTES_DOWNLOADED: $SAB_BYTES_DOWNLOADED (How many bytes were recieved (can be more than tried, due to overhead))"
	log "SAB_DUPLICATE: $SAB_DUPLICATE (Was it detected as duplicate)"
	log "SAB_UNWANTED_EXT: $SAB_UNWANTED_EXT (Were there unwanted extensions)"
	log "SAB_OVERSIZED: $SAB_OVERSIZED (Was the job over the user's size limit)"
	log "SAB_PASSWORD: $SAB_PASSWORD (What was the password supplied by the NZB or the user)"
	log "SAB_ENCRYPTED: $SAB_ENCRYPTED (Was the job detected as encrypted)"
	log "SAB_STATUS: $SAB_STATUS (Current status (completed/failed/running))"
	log "SAB_FAIL_MSG: $SAB_FAIL_MSG (If job failed, why did it fail)"
	log "SAB_AGE: $SAB_AGE (Average age of the articles in the post)"
	log "SAB_URL: $SAB_URL (URL from which the NZB was retrieved)"
	log "SAB_AVG_BPS: $SAB_AVG_BPS (Average bytes/second speed during active downloading)"
	log "SAB_DOWNLOAD_TIME: $SAB_DOWNLOAD_TIME (How many seconds did we download)"
	log "SAB_PP: $SAB_PP (What post-processing was activated (download/repair/unpack/delete))"
	log "SAB_REPAIR: $SAB_REPAIR (Was repair selected by user)"
	log "SAB_UNPACK: $SAB_UNPACK (Was unpack selected by user)"
	log "SAB_FAILURE_URL: $SAB_FAILURE_URL (Provided by some indexers as alternative NZB if download fails)"
	log "SAB_PRIORITY: $SAB_PRIORITY (Priority set by user)"
	log "SAB_GROUP: $SAB_GROUP (Newsgroup where (most of) the job's articles came from)"
	log "SAB_VERSION: $SAB_VERSION (The version of SABnzbd used)"
	log "SAB_ORIG_NZB_GZ: $SAB_ORIG_NZB_GZ (Path to the original NZB-file of the job.The NZB-file is compressed with gzip (.gz))"
	log "SAB_PROGRAM_DIR: $SAB_PROGRAM_DIR (The directory where the current SABnzbd instance is located)"
	log "SAB_PAR2_COMMAND: $SAB_PAR2_COMMAND (The path to the par2 command on the system that SABnzbd uses)"
	log "SAB_MULTIPAR_COMMAND: $SAB_MULTIPAR_COMMAND (Windows-only (empty on other systems).The path to the MultiPar command on the system that SABnzbd uses)"
	log "SAB_RAR_COMMAND: $SAB_RAR_COMMAND (The path to the unrar command on the system that SABnzbd uses)"
	log "SAB_ZIP_COMMAND: $SAB_ZIP_COMMAND (The path to the unzip command on the system that SABnzbd uses)"
	log "SAB_7ZIP_COMMAND: $SAB_7ZIP_COMMAND (The path to the 7z command on the system that SABnzbd uses. Not all systems have 7zip installed (it's optional for SABnzbd), so this can also be empty)"
}

# Write to log file - https://en.wikipedia.org/wiki/Box-drawing_character
log() {
	if [ $# -eq 0 ]
	then
		echo "║" >>$logFile
	elif [ "$1" == "CreateNewLog" ]
	then
		echo "╔═══════════════════════════════════════════════════════════════════════════════════════════════════" >$logFile
	elif [ "$1" == "NewDivider" ]
	then
		echo "╠═══════════════════════════════════════════════════════════════════════════════════════════════════" >>$logFile
	else
		echo "║ $(ts): $1" >>$logFile
	fi
}

# Write to CSV file
toCSV() {
	if [[ "$1" == "newFile" ]]
	then
		echo -e "movieId;movieTitle;sourceFile;destinationFile;fileSize;transferred" >$queueFile
	else
		echo -e "$1" >>$queueFile
	fi
}

# Look up file destination
get_movie_details() {
	# Declare variables
	arrPos=0
	searchSize=50
	radarrURL="localhost"
	radarrPort="3078"
	radarrToken=`cat $HOME/scripts/.access/radarr.api`
	radarrAPI="http://$radarrURL:$radarrPort/api/history?apikey=$radarrToken&page=1&pageSize=$searchSize" #https://github.com/Radarr/Radarr/wiki/API:History
	jsonLatestDownloads=`curl -s "$radarrAPI" | jq -r '.'`
	jsonDownloadIds=`echo $jsonLatestDownloads | jq -r '.records[].downloadId'`

	# Iterate through latest downloads until a match is found
	for downloadId in ${jsonDownloadIds}
	do
		if [[ $downloadId == $SAB_NZO_ID ]]
		then 
			# log "Yes [$arrPos]: $downloadId"
			movieId=`echo $jsonLatestDownloads | jq -r --argjson pos "$arrPos" '.records[$pos].movie.id'`
			movieTitle=`echo $jsonLatestDownloads | jq -r --argjson pos "$arrPos" '.records[$pos].movie.title'`
			movieDestination=`echo $jsonLatestDownloads | jq -r --argjson pos "$arrPos" '.records[$pos].movie.path'`
			break
		fi
    	let arrPos=$arrPos+1
	done
}

add_to_queue() {
	for file in "${SAB_COMPLETE_DIR}"/*
	do
		fileSize=`du -b "$file" | cut -f 1`
		fileExt=${file##*.}

		# Skip files without an extension
		if [[ "$fileExt" == "" ]]
		then
			fileExt = "SKIP"
		fi

		case $fileExt in
		mkv | mp4 | srr | srt | sub | idx)
			fileLower=`echo "$file" | tr '[:upper:]' '[:lower:]'`
			# Skip sample files
			if [[ "$fileLower" != *"sample"* ]]
			then
				toCSV "$movieId;$movieTitle;$file;$movieDestination;$fileSize;false"
			fi
			;;
		SKIP | par2 | jpg | png | nzb | 81O | 3bd)
			# Skip unwanted files
			toCSV "SKIP;$movieTitle;$file;SKIP;SKIP;SKIP"
			;;
		*)
			toCSV "$movieId;$movieTitle;$file;$movieDestination;$fileSize;ERROR"
			;;
		esac
	done
}


# Check for log file and create if not found
if [[ ! -f "$logFile" ]]
then
	log "CreateNewLog"
fi

# Check for queue file and create if not found
if [[ ! -f "$queueFile" ]]
then
	toCSV "newFile"
fi

# Only process movies category
if [[ "$5" == "movies" ]]
then
	get_movie_details
	add_to_queue
	echo "Completed. [${0##*/}: (Not) Imported]"
fi
