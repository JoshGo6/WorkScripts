#!/usr/bin/env python3

# This script converts a TREE TOC file into a JSON TOC file.
# Execute the script by running the following at the command line:
#
# <path/to/script> <file-to-convert>

import sys
import json
import xml.etree.ElementTree as ET
from pathlib import Path

def remove_md_extension(path):
    """Remove .md extension from path if present"""
    if path and path.endswith('.md'):
        return path[:-3]
    return path

def convert_element(element):
    """Convert a single XML element to JSON dictionary"""
    result = {}
    
    # Get the label from toc-title attribute
    if 'toc-title' in element.attrib:
        result['label'] = element.attrib['toc-title']
    
    # Get the path from topic attribute, removing .md extension
    if 'topic' in element.attrib:
        result['path'] = remove_md_extension(element.attrib['topic'])
    
    # Check if element has children
    children = list(element)
    if children:
        result['children'] = []
        for child in children:
            result['children'].append(convert_element(child))
    
    return result

def convert_xml_to_json(xml_file_path):
    """Convert XML tree file to JSON format"""
    try:
        # Read the file content and wrap it in a root element to handle multiple top-level elements
        with open(xml_file_path, 'r', encoding='utf-8') as f:
            content = f.read().strip()
        
        # Fix common XML formatting issues
        import re
        # Fix missing spaces between attributes (e.g., "title"topic= -> "title" topic=)
        content = re.sub(r'"([a-zA-Z-]+)=', r'" \1=', content)
        
        # Wrap content in a root element to make it valid XML
        wrapped_content = f"<root>\n{content}\n</root>"
        
        # Parse the wrapped XML
        root = ET.fromstring(wrapped_content)
        
        # Get all top-level toc-element children
        top_elements = list(root)
        
        # If there's only one top-level element, return it directly
        # If there are multiple, return them as an array
        if len(top_elements) == 1:
            json_data = convert_element(top_elements[0])
        else:
            json_data = [convert_element(elem) for elem in top_elements]
        
        # Generate output filename
        input_path = Path(xml_file_path)
        output_path = input_path.with_suffix('.json')
        
        # Write JSON to file
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        
        print(f"Successfully converted {xml_file_path} to {output_path}")
        
    except ET.ParseError as e:
        print(f"Error parsing XML file: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: File {xml_file_path} not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) != 2:
        print("Usage: python xml_to_json_converter.py <input_file.tree>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    convert_xml_to_json(input_file)

if __name__ == "__main__":
    main()