#!/bin/bash
# This script generates a flat, unordered TOC in Markdown from a directory of Markdown files.
> tmp.md
mapfile -t ALL_FILES < <(find . -type f -name "*.md")

for i in "${ALL_FILES[@]}"
do
    awk -v filename="$i" 'BEGIN {
        FS="/"
        $0=filename
        # Replace spaces with %20 for URL encoding
        without_spaces=$0
        gsub(/ /, "%20", without_spaces)
        print "[" substr($NF, 1, length($NF)-3) "](" \
            without_spaces ")  " >> "tmp.md"
    }
    '
done
