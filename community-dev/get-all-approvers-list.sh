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
		echo $approver >> $temp
	done
done
	
cat $temp | sort | uniq

rm -f -- "$temp"
rm -f -- "$temp_aliases"

