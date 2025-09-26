declare -a ALL_MARKDOWN_FILES
declare -a FILES_WITH_IMAGES
declare -a ORIGINAL_IMG__REFS

# Find all Markdown files recursively, and write them to the array ALL_MARKDOWN_FILES
mapfile -t ALL_MARKDOWN_FILES < <(find . -type f -name "*.md" -exec ls {} +)

# Search through all the Markdown files and every time find a file that contains an image reference, write to the array FILES_WITH_IMAGES
for file in "${ALL_MARKDOWN_FILES[@]}"; do
    grep -lPq "!\[(\w|-)+\]\((\w|-)+\.\w{3}\)" "$file" && FILES_WITH_IMAGES+=("$file")
done

# Process the FILES_WITH_IMAGES array.
for file in "${FILES_WITH_IMAGES[@]}"; do

    # Find out how many folders deep the current file is in the hierarchy, and assign that depth to the `depth` variable
    depth=$(echo "$file" | \
    awk '
        {temp = $0}
        {print gsub(/\//, "", temp)}
    ')

    # Find all of the image references in the currently processed file, and assign them to ORIGINAL_IMG__REFS.
    echo -e "\nProcessing file ${file}."
    mapfile -t ORIGINAL_IMG__REFS < <(grep -oP "!\[(\w|-)+\]\((\w|-)+\.\w{3}\)(\{.*?\})?" "$file")
        for ref in "${ORIGINAL_IMG__REFS[@]}"; do
            echo "$ref"
        done



done


