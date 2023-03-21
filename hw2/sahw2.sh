#!/bin/bash

usage() {
echo -n -e "\nUsage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5: MD5 hashes to validate input files.\n-i: Input files.\n"
}

while getopts "hi:-:" opt; do
    case "${opt}" in
        h )
            usage
            exit 0
            ;;
        i )
            input_file=${OPTARG}
            ;;
        - )
            case "${OPTARG}" in
                md5 )
                    md5=true
                    ;;
                help )
                    usage
                    exit 0
                    ;;
		sha256 )
		    sha256=true
		    ;;
                * )
           	    echo "Error: Invalid arguments." 1>&2
                    usage
                    exit 1
            esac
            ;;
        \? )
            echo "Error: Invalid arguments." 1>&2
            usage
            exit 1
            ;;
        : )
            echo "Invalid option: -${OPTARG} requires an argument" 1>&2
            usage
            exit 1
            ;;
    esac
done

# 如果 -h 選項或沒有指定輸入文件，顯示使用信息並退出
if [[ -z "${input_file}" ]]; then
	echo "Input file not specified" 1>&2
	usage
	exit 1
fi

if [[ "${md5}" == true && "$sha256" == true ]]; then
	echo "Error: Only one type of hash function is allowed." 1>&2
	exit 1
fi

# 在這裡使用輸入文件
echo "Using input file: ${input_file}"

# 如果指定了 --md5 選項，計算 MD5 雜湊
if [[ "${md5}" == true ]]; then
    # md5 "${input_file}"
    awk 'BEGIN {
    system("md5 data.csv") | getline output
    split(output, array, " ")
    print array[1]
}'

fi

