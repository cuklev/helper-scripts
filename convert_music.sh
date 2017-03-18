#!/bin/bash

operation=$1

DB_FILE="music_folders.list"

add() {
	local db_file="$DB_FILE"
	[[ "$1" != "" ]] && db_file="$1"

	{
		cat "$db_file"
		zenity \
			--file-selection \
			--multiple \
			--directory \
			--separator '
'
	} \
	| sort -uo "$db_file"
}

convert_file() {
	in_file="$1"
	out_dir="$(basename "$(dirname "$in_file")")"
	out_file="${out_dir}/$(basename "$in_file")"
	out_file="${out_file%.*}.opus"

	echo "Converting ${in_file}"

	mkdir -p "$out_dir"
	ffmpeg -loglevel 0 \
		-n -i "$in_file" -b:a 92k -bufsize 92k "$out_file" \
		2> /dev/null
}

convert() {
	local db_file="$DB_FILE"
	[[ "$1" != "" ]] && db_file="$1"

	while read dir; do
		find "$dir" \
			-name \*.mp3 -or \
			-name \*.flac -or \
			-name \*.ogg -or \
			-name \*.opus \
			| while read file; do
				convert_file "$file"
			done
	done < "$db_file"
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
