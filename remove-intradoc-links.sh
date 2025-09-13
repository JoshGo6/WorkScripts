#!/bin/bash
# This script looks through Markdown files recursively in the current directory and removes
# lines that start with either a space or a dash that are followed by one or more spaces
# that are followed by an intradoc link and then an EOL.
find . -type f -name "*.md" -exec sed -i -r "/^( )*[-]( )+\[.+\]\(#/d" {} +