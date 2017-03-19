#!/bin/bash

operation="$1"

DB_FILE="music_folders.list"

trap wait EXIT

run_parallel() {
	local MAX_COUNT=8

	while true; do
		local job_count=$(jobs -p | wc -l)
		[[ $job_count < $MAX_COUNT ]] && break
		sleep 1
	done

	"$@" &
}

add() {
	local db_file="$DB_FILE"
	[[ "$1" != "" ]] && db_file="$1"

	{
		cat "$db_file"
		while read dir; do
			find "$dir" \
				-name \*.mp3 -or \
				-name \*.flac -or \
				-name \*.ogg -or \
				-name \*.opus
		done < <(zenity \
			--file-selection \
			--multiple \
			--directory \
			--separator '
')
	} \
	| sort -uo "$db_file"
}

convert_file() {
	in_file="$1"

	out_dir="$(basename "$(dirname "$in_file")")"

	out_file="$(basename "$in_file")"
	out_file="${out_file%.*}.opus"

	echo "Converting ${in_file}"

	mkdir -p "$out_dir"
	ffmpeg -loglevel 0 \
		-n -i "$in_file" -b:a 96k -bufsize 96k "${out_dir}/${out_file}" \
		&> /dev/null

	echo Done >&5
}

display_progress() {
	local total=$1
	local progress=0

	while read; do
		let progress+=1
		echo $((100 * progress / total))
	done | zenity --progress --text='Converting...' --auto-close --no-cancel
}

convert() {
	local db_file="$DB_FILE"
	[[ "$1" != "" ]] && db_file="$1"

	file_count=$(wc -l "$db_file")

	while read file; do
		run_parallel convert_file "$file"
	done < "$db_file" 5>&1 >&2 \
		| display_progress $file_count
}

case $operation in
	add)
		add "$2"
		;;
	convert)
		convert "$2"
		;;
	*)
		echo 'No option was specified.'
		;;
esac
