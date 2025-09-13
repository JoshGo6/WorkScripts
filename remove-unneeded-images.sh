# This script removes unnecessary image files in the attachments folder in a Markdown docs repo. Here are the details:

# In the Markdown files, look for references to image files
# (for example, strings that end in ".jpeg")
# If you find a line that contains an image name, print the image file name
# without the full path. (Omit everything up to the final /.)
mapfile -t REFERENCED_IMAGES < <(find . -type f -name "*.md" -exec \
  awk '{  
    if (match($0, /[a-zA-Z_0-9-]+\.((png)|(gif)|(jpg)|(jpeg))/))
      {print substr($0, RSTART, RLENGTH)}
  }' {} + | sort -u )

# Look in the /attachments directory, and extract the file names as the text
# after the last / and store these in an array
mapfile -t ALL_IMAGE_NAMES < <(find . -type f -regextype posix-extended -regex ".*/attachments/.*" | rev | cut -d "/" -f 1 | rev |sort -u)

# We're only allowed to delete files that have this extension.
EXTENSIONS=(png gif bmp jpg jpeg)

# I need to delete images but don't know how deep they are, so I'll use ** syntax.
shopt -s globstar

# Initialize the number of matches to 0.
number_of_matches=0

# Initialize the number of deleted images.
deleted_images=0

# Loop through the outer array, which contains all image names in /attachments,
# and also loop through an inner array, which contains all image names
# referenced in the Markdown docs.
# If none of the image file names present in the Markdown file match a particular
# image name in the /attachments folder, delete that image from the /attachments as long as the file name extension is one of the allowed extensions.
# Then check the next image name in the /attachments folder against all of the image
# names referenced in the docs, repeating the process until all referenced image names are checked.

for name_in_full_list in "${ALL_IMAGE_NAMES[@]}"; do
  match=false #Assume initially that we're not going to have a match for this file.
  for referenced_image in "${REFERENCED_IMAGES[@]}"; do
    if [ "$name_in_full_list" == "$referenced_image" ]; then
      match=true
      (( number_of_matches++ ))
      continue 2
    fi
  done
  if [[ "${match}" == false ]]
  then
  #Even if we don't have a file match, we need to check that the file name
  #extension is safe for deletion.
    for extension in "${EXTENSIONS[@]}"; do
      if [[ ${name_in_full_list: -3} == ${extension} ]]; then
        rm **/$name_in_full_list
        (( deleted_images++ ))
        continue 2
      fi
    done
  fi
done


#Output some statistics for the user to look at.
echo "The extensions are ${EXTENSIONS[@]}."
echo "The total number of matched images is ${number_of_matches}."
echo "The total number of image references in the Markdown file is ${#REFERENCED_IMAGES[@]}."
echo "The total number of stored images is originally ${#ALL_IMAGE_NAMES[@]}."
echo "The total number of deleted images is ${deleted_images}."
