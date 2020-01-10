#!/usr/bin/env bash

find_files() {
  # TODO: Need to check other go files also
  find test/ -name '*.go'
}

invalid_files=()
for gofile in `find_files`
do
	if [ -n "$(file -i ${gofile} | grep utf-8)" ]
	then
		invalid_files+=( "${gofile}" )
	fi
done

if [ ${#invalid_files[@]} -ne 0 ]; then
  {
    echo "Errors:"
    for err in "${invalid_files[@]}"; do
      echo "$err"
    done
    echo
    echo 'The above files contains non-ascii string, need to remove it'
    echo
  } >&2
  exit 1
fi
