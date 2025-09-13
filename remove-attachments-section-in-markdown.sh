#!/bin/bash
# This script looks through Markdown files recursively in the current directory and removes
# everything from the Attachments section header through the end of the file.
find . -type f -name "*.md" -exec sed -i -r "/^#+ Attachments/,\$d" {} +