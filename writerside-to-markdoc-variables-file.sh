#!/bin/bash
#
# This script reads in an input Markdoc variable file and converts it to a Markdoc variable file named markdoc_variables.json.

# Initialize the JSON and temp file by emptying them.
> markdoc_variables.json
> tmp.txt

# Process the input file and extract variable names to an array
# called VARIABLE_NAMES
mapfile -t VARIABLE_NAMES < <(cat $1 | \
awk ' BEGIN {FS="\""} /<var name="/ {print $2}' )

# Process the input file and extract variable values to an array
# called VARIABLE_VALUES
mapfile -t VARIABLE_VALUES < <(cat $1 | \
awk ' BEGIN {FS="\""} /<var name="/ {print $4}' )

# Create the static content at the top of the JSON file.
echo "{\"variables\":" >> markdoc_variables.json
echo -e "\t{" >> markdoc_variables.json

VARIABLE_NAMES_AND_VALUES=()

# Create a third array where each entry is a colon-separated pair
# from the first two arrays, so we can sort and eliminate duplicates.

for (( counter=0; counter<${#VARIABLE_NAMES[@]}; counter++ )); do
    VARIABLE_NAMES_AND_VALUES[$counter]="${VARIABLE_NAMES[$counter]}:${VARIABLE_VALUES[$counter]}"
done

# Create a fourth array that is the sorted version of the third array
# where duplicates have been removed, and remove any empty values that snuck in during processing.
printf "%s\n" "${VARIABLE_NAMES_AND_VALUES[@]}" | sort -u | xargs -I {} echo \"{}\" >> tmp.txt
mapfile -t SORTED_WITHOUT_DUPES < <(cat tmp.txt | grep -v -P "^\"$")

# Process the array, writing to the JSON file, splitting on the field separator, which is the colon, so we can add quotes and spaces and a trailing comma as needed to form proper JSON. The first if/fi clause handles every entry except the very last one, which should not have a closing comma.
for (( i=0; i<"${#SORTED_WITHOUT_DUPES[@]}"; i++ )); do
    if (( i < "${#SORTED_WITHOUT_DUPES[@]}" - 1 )) ; then
        echo "${SORTED_WITHOUT_DUPES[$i]}" | awk -F ":" '{ print "\t\t" $1 "\": \"" $2 "," }' >> markdoc_variables.json
    else
        echo "${SORTED_WITHOUT_DUPES[$i]}" | awk -F ":" '{ print "\t\t" $1 "\": \"" $2 }' >> markdoc_variables.json
    fi
done

# Write the static closing text to the file.
echo -e "\t}" >> markdoc_variables.json
echo } >> markdoc_variables.json