#!/bin/bash

# store input files and hashes as hash table
declare -A file_hashes=()
hash_index=0
file_index=0

# 把每一個 argument 存入 array
args=("$@")

usage() {
echo -n -e "\nUsage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5: MD5 hashes to validate input files.\n-i: Input files.\n"
}

# Loop through all the command line arguments
for (( i=0; i<${#args[@]}; i++ ))
do
	key="${args[i]}"
	case $key in 
		-i)
		# Loop through all the input files and add them to the array
		for (( j=i+1; j<${#args[@]}; j++))
		do
			input_file="${args[$j]}"
			
			if [[ "$input_file" == -*  ]]; then
				break
			fi
		file_index=$((file_index + 1))
		file_hashes[$file_index]="$input_file:${file_hashes[$file_index]}"
		done
		;;
		-h)
		usage
		exit 0
		;;
		--md5)
		for(( j=i+1; j<${#args[@]}; j++))
		do
			hash="${args[$j]}"

			if [[ "$hash" == -* ]]; then
				break
			fi
			hash_index=$((hash_index + 1))
			file_hashes[$hash_index]="${hash}:md5"
		done
		;;
		--sha256)
		for(( j=i+1; j<${#args[@]}; j++))
		do
			hash="${args[$j]}"

			if [[ "$hash" == -* ]]; then
				break
			fi
			hash_index=$((hash_index + 1))
			file_hashes[$hash_index]="${hash}:sha256"
		done
		;;
		--*)
		echo "Error: Invalid arguments." 1>&2
		usage
		exit 1
		;;
	esac
done

if [[ "${md5}" == true && "$sha256" == true ]]; then
	echo "Error: Only one type of hash function is allowed." 1>&2
	exit 1
fi

if [[ "$hash_index" != "$file_index" ]]; then
	echo "Error: Invalid values." 1>&2
	exit 1
fi

# Loop through all the input files and hashes in the array
for file_hash in "${file_hashes[@]}"
do
	# Extract the input file and the hash value from the string
	IFS=':' read -r input_file hash hash_type <<< "$file_hash"

	# Check if the input file exists
	if [[ ! -f "$input_file" ]]; then
		echo "Error: Input file not found: $input_file"
		exit 1
	fi
	
	# Calculate the actual MD5 hash of the input file
	actual_hash=$(openssl "$hash_type" "$input_file" | awk '{print $2}')
	if [[ "$actual_hash" != "$hash" ]]; then
		echo "Error: Invalid checksum."
		exit 1
	else 
		echo "$hash_type hash matched for file: $input_file"
	fi
done
