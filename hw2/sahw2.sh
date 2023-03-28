#!/bin/bash

# store input files and hashes as hash table
declare -A file_hashes=()
input_files=()
user=()
usernames=()
passwords=()
shells=()
groups=()
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
		input_files[$file_index]="$input_file"
		file_index=$((file_index + 1))
		done
		;;
		-h)
		usage
		exit 0
		;;
		--md5)
		md5=true
		for(( j=i+1; j<${#args[@]}; j++))
		do
			hash="${args[$j]}"

			if [[ "$hash" == -* ]]; then
				break
			fi
			file_hashes[$hash_index]="${hash}:md5"
			hash_index=$((hash_index + 1))
		done
		;;
		--sha256)
		sha256=true
		for(( j=i+1; j<${#args[@]}; j++))
		do
			hash="${args[$j]}"

			if [[ "$hash" == -* ]]; then
				break
			fi
			file_hashes[$hash_index]="${hash}:sha256"
			hash_index=$((hash_index + 1))
		done
		;;
		--*)
		echo -n "Error: Invalid arguments." 1>&2
		usage
		exit 1
		;;
	esac
done

if [[ "$md5" == true && "$sha256" == true ]]; then
	echo -n "Error: Only one type of hash function is allowed." 1>&2
	exit 1
fi

if [[ "$hash_index" != "$file_index" ]]; then
	echo -n "Error: Invalid values." 1>&2
	exit 1
fi
# Loop through all the input files and hashes in the array
for ((i=0; i<"${#file_hashes[@]}"; i++)); do
	# Extract the input file and the hash value from the string
	IFS=':' read -r hash hash_type <<< "${file_hashes[$i]}"
	input_file="${input_files[$i]}"
	# Check if the input file exists
	if [[ ! -f "$input_file" ]]; then
		echo "Error: Input file not found: $input_file" 1>&2
		exit 1
	fi
	
	# Calculate the actual MD5 hash of the input file
	actual_hash=$(openssl "$hash_type" "$input_file" | awk '{print $2}')
	if [[ "$actual_hash" != "$hash" ]]; then
		echo -n "Error: Invalid checksum."
		exit 1
	else 
		#echo "$hash_type hash matched for file: $input_file"
		file_type=$(file -b "$input_file")

		if [[ "$file_type" != *"JSON"* && "$file_type" != *"CSV"* ]]; then
			echo -n "Error: Invalid file format." 1>&2
			exit 1	
		fi

		if [[ "$file_type" == *"JSON"* ]]; then
			temp_usernames=($(cat "$input_file" | jq -r ".[] | .username"))
			temp_passwords=($(cat "$input_file" | jq -r ".[] | .password"))
			temp_shells=($(cat "$input_file" | jq -r ".[] | .shell"))
			temp_groups=($(cat "$input_file" | jq -r '.[] | .groups | join(",")'))
			for ((j=0; j<"${#temp_usernames[@]}"; j++)); do
				# Change ',' to space
				if echo "${temp_groups[$j]}" | grep -q ','; then
					temp_groups[$j]=$(echo "${temp_groups[$j]}" | sed 's/,/ /g')
				fi
				usernames+=("${temp_usernames[$j]}")
				passwords+=("${temp_passwords[$j]}")
				shells+=("${temp_shells[$j]}")
				groups+=("${temp_groups[$j]}")
			done
		elif [[ "$file_type" == *"CSV"* ]]; then
			while IFS=',' read -r username password shell group || [[ -n "$line" ]]; do
				if [[ "$username" != "username" ]]; then
					usernames+=("$username")
					passwords+=("$password")
					shells+=("$shell")
					groups+=("$group")
				fi
			done < "$input_file"
		else
			exit 1
		fi
	fi

done

user_string="${usernames[@]}"
echo -n "This script will create the following user(s): ${user_string} Do you want to continue? [y/n]"
read selection

if [[ "$selection" == "y" ]]; then
	# Create users
	for i in "${!usernames[@]}"; do
		#echo "User ${usernames[$i]} creating..."
		# Check if user already exists
		if id -u "${usernames[$i]}" >/dev/null 2>&1; then
			echo -n "Warning: user ${usernames[$i]} already exists."
		else
			# Create user with specified data
			echo "${passwords[$i]}" | pw useradd -n "${usernames[$i]}" -m -s "${shells[$i]}" -h 0
			# Create groups
			if [[ -n "${groups[$i]}" ]]; then
				read -ra group_array <<< "${groups[$i]}"
				#echo "正在給 ${usernames[$i]} 加入群組..."
				# Check if group exists
				for group in "${group_array[@]}"; do
					if ! grep -q "^$group:" /etc/group; then
						pw groupadd "$group"
					fi
				done
				pw usermod "${usernames[$i]}" -G "$(IFS=','; echo "${group_array[@]}")"
			fi

			#echo "使用者 ${usernames[$i]} 建立完成"
		fi
		done
else
	exit 0
fi
