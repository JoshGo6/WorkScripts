declare -a ALL_MARKDOWN_FILES
declare -a FILES_WITH_IMAGES
declare -a ORIGINAL_IMG__REFS

# Find all Markdown files recursively, and write them to the array ALL_MARKDOWN_FILES
mapfile -t ALL_MARKDOWN_FILES < <(find . -type f -name "*.md" -exec ls {} +)

# Search through all the Markdown files in ALL_MARKDOWN_FILES and every time we find a file that contains an image reference, add that file name to FILES_WITH_IMAGES. We search for image references using regex. The regex is based on the following typical image reference:
#
# ![A02-00_0001-Amelia-Capabilities](A02-00_0001-Amelia-Capabilities.png){width="900" style="block"}

for file in "${ALL_MARKDOWN_FILES[@]}"; do
    grep -lPq "!\[(\w|-)+\]\((\w|-)+\.\w{3}\)" "$file" && FILES_WITH_IMAGES+=("$file")
done

# Process the FILES_WITH_IMAGES array
for file in "${FILES_WITH_IMAGES[@]}"; do

    # Find out how many folders deep the current file is in the hierarchy, and assign that integer to the `depth` variable
    depth=$(echo "$file" | \
    awk '
        {temp = $0}
        {print gsub(/\//, "", temp)}
    ')

    # Find all of the image references in the currently processed file, and assign them to the array ORIGINAL_IMG__REFS. The image references are strings of the following form:
    # ![...](...png){width=...style=...}
    mapfile -t ORIGINAL_IMG__REFS < <(grep -oP "!\[(\w|-)+\]\((\w|-)+\.\w{3}\)(\{.*?\})?" "$file")
        # Extract the file name from each image reference and assign it to the `file_name` variable
        for original_text in "${ORIGINAL_IMG__REFS[@]}"; do
            file_name=$(echo "$original_text" | awk '
                BEGIN { FS="(" }
                {last_pos=match($2, ")")}
                {print substr($2, 1, last_pos - 1) }
            ')

            # Use awk to find the alt. text for `file_name` and assign that information to `alt_text`
            alt_text=$(awk -v file_match="$file_name" ' 
                BEGIN {FS="\""}
                $0 ~ file_match {print $4}
            ' ./img-alt-text.yaml)
            
            # Construct new text to replace the original text. Since we'll use sed to make the replacements, we need to escape the following character class: [&\""]
            # This is the form of the text replacement:
            # {% Image src="[https://upload.wikimedia.org/wikipedia/commons/8/8c/SoundHound_AI_logo_black.jpg](https://upload.wikimedia.org/wikipedia/commons/8/8c/SoundHound_AI_logo_black.jpg)" alt="SoundHound AI logo" size="natural" /%} 

            # Use sed on `file` to replace `original_text` with a new string built from the following:
            # 
            # -'depth'
            # - `file_name`
            # - `alt_text`
            #
            # The new string will be of thef following form:
            # {% Image src="[https://upload.wikimedia.org/wikipedia/commons/8/8c/SoundHound_AI_logo_black.jpg](https://upload.wikimedia.org/wikipedia/commons/8/8c/SoundHound_AI_logo_black.jpg)" alt="SoundHound AI logo" size="natural" /%}

        done
done


