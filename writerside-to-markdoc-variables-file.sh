#!/bin/bash
#
# This script reads in an input Markdoc variable file and converts it to a Markdoc variable file named markdoc_variables.json.

# Initialize the JSON file by emptying it.
> markdoc_variables.json

# Process the input file and extract variable names to an array
# called VARIABLE_NAMES
mapfile -t VARIABLE_NAMES < <(cat $1 | \
awk ' BEGIN {FS="\""} /<var name="/ {print $2}' )

# Process the input file and extract variable values to an array
# called VARIABLE_VALUES
mapfile -t VARIABLE_VALUES < <(cat $1 | \
awk ' BEGIN {FS="\""} /<var name="/ {print $4}' )

# Create the static content at the top of the JSON file.
echo "{variables:" >> markdoc_variables.json
echo -e "\t{" >> markdoc_variables.json

# Write each value of the variable name and variable value to
# the JSON file.
for (( i=0; i<"${#VARIABLE_NAMES[@]}"; i++ )); do
    echo -e "\t\t'${VARIABLE_NAMES[$i]}': '${VARIABLE_VALUES[$i]}'," >> markdoc_variables.json
done

# Write the static closing text to the file.
echo -e "\t}" >> markdoc_variables.json
echo } >> markdoc_variables.json