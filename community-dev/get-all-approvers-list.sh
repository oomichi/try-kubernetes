#!/usr/bin/env bash

owners=$(ls */OWNERS ./OWNERS)
approvers=()
aliases=()

for file in $owners
do
	for approver in $(cat $file | yq '.approvers' | grep '"' | sed s/[,\"]//g)
	do
		approvers+=( "$approver" )
	done
done

temp=$(tempfile) || exit
for approver in "${approvers[@]}"
do
	if [[ $approver == *"approvers" ]]
	then
		aliases+=( "$approver" )
		continue
	fi
	echo $approver >> $temp
done

temp_aliases=$(tempfile) || exit
for aliase in "${aliases[@]}"
do
	# This is a really tricky workaround, but "yq" command considers the filter(e.g: ".aliases.api-approvers") which contains "-" as its own options.
	# So here copies OWNERS_ALIASES to a temp file and replaces "-" to "-" for the workaround.
	mod_aliase=$(echo $aliase | sed s/"-"/"_"/g)
	cat ./OWNERS_ALIASES | sed s/"${aliase}"/"${mod_aliase}"/ > $temp_aliases
	for approver in $(cat $temp_aliases | yq ".aliases.${mod_aliase}" | grep '"' | sed s/[,\"]//g)
	do
		# github IDs are sometimes written with CamelCase or lowercase for the same ID in OWNERS files.
		# So here translates all IDs in lowercase.
		echo $approver | tr '[A-Z]' '[a-z]' >> $temp
	done
done
	
for githubid in $(cat $temp | sort | uniq)
do
	name=$(curl "https://github.com/${githubid}" 2>/dev/null | grep '"name"' | awk -F">" '{print $2}' | awk -F"<" '{print $1}')
	echo "${name} <${githubid}>"
done
rm -f -- "$temp"
rm -f -- "$temp_aliases"

