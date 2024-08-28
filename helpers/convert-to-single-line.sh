#!/bin/bash

# Read the JSON file and remove all whitespace and newline characters
single_line_string=$(jq -c . ../deploy/parameters-podcast-app.json)

# Print the single-line string
echo "$single_line_string"