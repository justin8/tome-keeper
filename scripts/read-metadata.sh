#!/bin/bash

# Read metadata from an ebook file using Calibre's ebook-meta command
# Usage: ./read-metadata.sh <file_path>
# Output: JSON with status, file path, and metadata object

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Check if file path argument is provided
if [[ -z "$1" ]]; then
  echo "{\"status\":\"error\",\"message\":\"Missing required parameter: file path\",\"usage\":\"./read-metadata.sh <file_path>\"}"
  exit 1
fi

# Validate file and get expanded path
file=$(validate_ebook_file "$1")
if [[ $? -ne 0 ]]; then
  echo "$file"  # Already JSON error from validate_ebook_file
  exit 1
fi

# Execute ebook-meta command and capture output
output=$("$EBOOK_META_CMD" "$file" 2>&1)
exit_code=$?

# Check if command succeeded
if [[ $exit_code -ne 0 ]]; then
  # Escape output for JSON
  output_escaped=$(echo "$output" | jq -Rs .)
  file_json=$(echo -n "$file" | jq -Rs .)
  command_json=$(echo -n "$EBOOK_META_CMD $file" | jq -Rs .)
  echo "{\"status\":\"error\",\"message\":\"Failed to read metadata from ebook file\",\"path\":$file_json,\"command\":$command_json,\"command_output\":$output_escaped,\"exit_code\":$exit_code}"
  exit 1
fi

# Check if output is empty
if [[ -z "$output" ]]; then
  file_json=$(echo -n "$file" | jq -Rs .)
  echo "{\"status\":\"error\",\"message\":\"ebook-meta returned no output. The file may be corrupted or empty.\",\"path\":$file_json}"
  exit 1
fi

# Parse ebook-meta output into JSON using jq
# The output format is key-value pairs like "Title               : Book Title"
# Multi-line fields have continuation lines without colons
parse_metadata() {
  local output="$1"
  local current_key=""
  local current_value=""
  local jq_args=()
  
  while IFS= read -r line; do
    # Check if line starts a new field (has colon with spaces before it)
    if [[ "$line" =~ ^[A-Za-z][^:]*[[:space:]]+:[[:space:]]*(.*) ]]; then
      # Save previous field if exists
      if [[ -n "$current_key" ]]; then
        jq_args+=(--arg "$current_key" "$current_value")
      fi
      
      # Extract key and value
      local key="${line%%:*}"
      local value="${BASH_REMATCH[1]}"
      
      # Normalize key: trim, lowercase, replace non-alphanumeric with underscore
      key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\+/_/g;s/^_//;s/_$//')
      
      current_key="$key"
      current_value="$value"
    else
      # Continuation line
      if [[ -n "$current_key" ]]; then
        if [[ "$current_key" == "comments" ]]; then
          # Preserve newlines for comments
          current_value="${current_value}"$'\n'"${line}"
        else
          # Join with space for other fields
          local trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          if [[ -n "$trimmed_line" ]]; then
            current_value="${current_value} ${trimmed_line}"
          fi
        fi
      fi
    fi
  done <<< "$output"
  
  # Save last field
  if [[ -n "$current_key" ]]; then
    jq_args+=(--arg "$current_key" "$current_value")
  fi
  
  # Build JSON object using jq with all collected args
  jq -n '$ARGS.named' "${jq_args[@]}"
}

# Parse the metadata
metadata=$(parse_metadata "$output")

# Build final JSON response - escape file path for JSON
file_json=$(echo -n "$file" | jq -Rs .)

echo "{\"status\":\"success\",\"file\":$file_json,\"metadata\":$metadata}"
