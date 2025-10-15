declare -a ALL_MARKDOWN_FILES # Stores the names of all .md files
declare -a FILES_WITH_IMAGES # Stores only names of files that contain images.
declare -a ORIGINAL_IMG__REFS #Stores all of the original Markdown image references.

# This function escapes regex characters in the sed input so they're treated literally.
escaped_sed_input() {
    printf '%s\n' "$1" | sed 's:[][\\/.^$*]:\\&:g'
}

# This function escapes the sed reserved characters in the sed substitution so they're treated literally.
escaped_sed_output() {
    printf '%s\n' "$1" | sed 's:[\\/&]:\\&:g; $!s/$/\\/'
}

# Find all Markdown files recursively, and write them to the array ALL_MARKDOWN_FILES
mapfile -d '' ALL_MARKDOWN_FILES < <( find . -type f -name "*.md" -print0 )

# Search through all the Markdown files in ALL_MARKDOWN_FILES and every time we find a file that contains an image reference, add that file name to FILES_WITH_IMAGES. We search for image references using regex. The regex is based on the following typical image reference:
#
# ![A02-00_0001-Amelia-Capabilities](A02-00_0001-Amelia-Capabilities.png){width="900" style="block"}


for file in "${ALL_MARKDOWN_FILES[@]}"; do
    grep -lPq "!\[.*?\]\(.*?\.\w{3}\)(\{.*?\})?" "$file" && FILES_WITH_IMAGES+=("$file")  
done

# Process the FILES_WITH_IMAGES array
for file in "${FILES_WITH_IMAGES[@]}"; do

    # Find all of the image references in the currently processed file, and assign them to the array ORIGINAL_IMG__REFS. The image references are strings of the following form:
    # ![...](...png){width=...style=...}
    mapfile -t ORIGINAL_IMG__REFS < <(grep -oP "!\[.*?\]\(.*?\.\w{3}\)(\{.*?\})?" "$file")
   
        for original_text in "${ORIGINAL_IMG__REFS[@]}"; do

            # Store an escaped version of the original text that we'll use in sed. The escaped version treats all regex metachars as literals.
            escaped_original_text="$(escaped_sed_input "$original_text" )"
        
            # Now we'll start to construct the replacement text to use in sed. The replacement string in sed will use a new string built from the following:
            # 
            # - `file_name`
            # - `alt_text`
        
            # Extract the file name from each image reference and assign it to the `file_name` variable
            file_name="$(echo "$original_text" | awk '
                BEGIN { FS="(" }
                {last_pos=match($2, ")")}
                {print substr($2, 1, last_pos - 1) }
            ')"

            # Use awk to find the alt. text for `file_name` and assign that information to `alt_text`
            alt_text="$(awk -v file_match="$file_name" ' 
                BEGIN {FS="\""}
                $0 ~ file_match {print $4}
            ' ./img-alt-text.yaml)"
            
            path_to_image="/docs-assets/${file_name}"

            # This is the form of the text replacement:
            # {% Image src="/docs-assets/sample-hero.svg" alt="Sample Hero Image" size="hero" /%}
            # We need to escape the following character class, because these are reserved characters in sed: [&\""]
            new_text_before_escapes="{% Image src=\"${path_to_image}\" alt=\"${alt_text}\" size=\"natural\" /%}"
            escaped_new_text="$(escaped_sed_output "$new_text_before_escapes")"

            # We're finally ready to perform the substitutions
            sed -i "s/${escaped_original_text}/${escaped_new_text}/g" "$file"
        done
done


