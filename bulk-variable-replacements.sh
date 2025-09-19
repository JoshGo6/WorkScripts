#!/bin/bash

# Read in original variable names, using awk on v.list, from the 4th line through the next-to-last line. Put the variable names in an array, ORIGINAL_VARS.
# Loop through the array:
# 1. Store the original array value to ORGINAL_VALUE.
# 2. Use tr to replace the periods with underscores and store an updated value to UPDATED_VALUE.
# 3. Use sed to replace all instances of %ORIGINAL_VALUE% with % UPDATED_VALUE %.

number_of_lines=$(cat v.list | wc -l) 

mapfile -t ORIGINAL_VARS < <(awk -F '"' -v number_of_lines="$number_of_lines" '
    NR > 3 && NR < number_of_lines { print $2 }
' ./v.list)

for original_var in ${ORIGINAL_VARS[@]}; do
    updated_var=$(echo $original_var | tr '.' '_')
    echo ${updated_var}
    find . -type f -name "*.md" -exec sed 's/%$original_var/% $updated_var %/g' {} +
done


