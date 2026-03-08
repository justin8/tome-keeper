#!/bin/bash

# Write metadata to an ebook file using Calibre's ebook-meta command
# Usage: ./write-metadata.sh <file_path> <json_metadata>
# Output: JSON with status and success/error message

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Check if file path argument is provided
if [[ -z "$1" ]]; then
  echo "{\"status\":\"error\",\"message\":\"Missing required parameter: file path\",\"usage\":\"./write-metadata.sh <file_path> <json_metadata>\"}"
  exit 1
fi

# Check if metadata JSON argument is provided
if [[ -z "$2" ]]; then
  echo "{\"status\":\"error\",\"message\":\"Missing required parameter: metadata JSON\",\"usage\":\"./write-metadata.sh <file_path> <json_metadata>\"}"
  exit 1
fi

# Validate file and get expanded path
file=$(validate_ebook_file "$1")
if [[ $? -ne 0 ]]; then
  echo "$file"  # Already JSON error from validate_ebook_file
  exit 1
fi

# Check if file is writable
if [[ ! -w "$file" ]]; then
  file_json=$(echo -n "$file" | jq -Rs .)
  echo "{\"status\":\"error\",\"message\":\"File is not writable (permission denied): $file\",\"path\":$file_json}"
  exit 1
fi

# Parse JSON metadata
metadata="$2"

# Validate JSON is valid
json_error=$(echo "$metadata" | jq empty 2>&1)
if [[ $? -ne 0 ]]; then
  json_error_escaped=$(echo "$json_error" | jq -Rs .)
  echo "{\"status\":\"error\",\"message\":\"Invalid JSON metadata provided\",\"json_error\":$json_error_escaped}"
  exit 1
fi

# Validate that metadata is a JSON object (not array or primitive)
metadata_type=$(echo "$metadata" | jq -r 'type')
if [[ "$metadata_type" != "object" ]]; then
  echo "{\"status\":\"error\",\"message\":\"Metadata must be a JSON object, got: $metadata_type\"}"
  exit 1
fi

# Build ebook-meta command with metadata fields
# Note: Using array with proper quoting to handle special characters
cmd=("$EBOOK_META_CMD")

# Extract and add title if present
if title=$(echo "$metadata" | jq -r '.title // empty' 2>/dev/null); then
  if [[ -n "$title" ]]; then
    # Use array element to preserve special characters
    cmd+=(--title "$title")
  fi
fi

# Extract and add authors if present
# Join multiple authors with " & " separator per Calibre conventions
if authors=$(echo "$metadata" | jq -r '.authors // empty' 2>/dev/null); then
  if [[ -n "$authors" ]] && [[ "$authors" != "null" ]]; then
    # Check if authors is an array
    if echo "$metadata" | jq -e '.authors | type == "array"' >/dev/null 2>&1; then
      authors_joined=$(echo "$metadata" | jq -r '.authors | join(" & ")')
      if [[ -n "$authors_joined" ]] && [[ "$authors_joined" != "null" ]]; then
        cmd+=(--authors "$authors_joined")
      fi
    else
      # Single author as string
      cmd+=(--authors "$authors")
    fi
  fi
fi

# Extract and add series if present
if series=$(echo "$metadata" | jq -r '.series // empty' 2>/dev/null); then
  if [[ -n "$series" ]] && [[ "$series" != "null" ]] && [[ "$series" != "None" ]]; then
    cmd+=(--series "$series")
  fi
fi

# Extract and add series_index if present
# Format as decimal (e.g., 1.0, 2.5)
if series_index=$(echo "$metadata" | jq -r '.series_index // empty' 2>/dev/null); then
  if [[ -n "$series_index" ]] && [[ "$series_index" != "null" ]]; then
    # Ensure it's formatted as a decimal
    series_index_formatted=$(echo "$series_index" | awk '{printf "%.1f", $0}')
    cmd+=(--index "$series_index_formatted")
  fi
fi

# Extract and add ISBN if present
if isbn=$(echo "$metadata" | jq -r '.isbn // empty' 2>/dev/null); then
  if [[ -n "$isbn" ]] && [[ "$isbn" != "null" ]]; then
    cmd+=(--isbn "$isbn")
  fi
fi

# Extract and add publisher if present
if publisher=$(echo "$metadata" | jq -r '.publisher // empty' 2>/dev/null); then
  if [[ -n "$publisher" ]] && [[ "$publisher" != "null" ]]; then
    cmd+=(--publisher "$publisher")
  fi
fi

# Extract and add published date if present
if published=$(echo "$metadata" | jq -r '.published // empty' 2>/dev/null); then
  if [[ -n "$published" ]] && [[ "$published" != "null" ]]; then
    cmd+=(--date "$published")
  fi
fi

# Extract and add language if present
if language=$(echo "$metadata" | jq -r '.language // empty' 2>/dev/null); then
  if [[ -n "$language" ]] && [[ "$language" != "null" ]]; then
    cmd+=(--language "$language")
  fi
fi

# Extract and add tags if present
if tags=$(echo "$metadata" | jq -r '.tags // empty' 2>/dev/null); then
  if [[ -n "$tags" ]] && [[ "$tags" != "null" ]]; then
    # Check if tags is an array
    if echo "$metadata" | jq -e '.tags | type == "array"' >/dev/null 2>&1; then
      tags_joined=$(echo "$metadata" | jq -r '.tags | join(",")')
      if [[ -n "$tags_joined" ]] && [[ "$tags_joined" != "null" ]]; then
        cmd+=(--tags "$tags_joined")
      fi
    else
      # Tags as string
      cmd+=(--tags "$tags")
    fi
  fi
fi

# Extract and add comments/description if present
# Note: ebook-meta uses --comments for the description field
if comments=$(echo "$metadata" | jq -r '.comments // empty' 2>/dev/null); then
  if [[ -n "$comments" ]] && [[ "$comments" != "null" ]]; then
    cmd+=(--comments "$comments")
  fi
fi

# Also check for html_description field (alternative name)
if html_description=$(echo "$metadata" | jq -r '.html_description // empty' 2>/dev/null); then
  if [[ -n "$html_description" ]] && [[ "$html_description" != "null" ]]; then
    cmd+=(--comments "$html_description")
  fi
fi

# Add the file path as the last argument
cmd+=("$file")

# Check if we have any metadata fields to update (more than just command and file)
if [[ ${#cmd[@]} -eq 2 ]]; then
  echo "{\"status\":\"error\",\"message\":\"No valid metadata fields provided to update\"}"
  exit 1
fi

# Execute ebook-meta command
output=$("${cmd[@]}" 2>&1)
exit_code=$?

# Check if command succeeded
if [[ $exit_code -ne 0 ]]; then
  # Escape output for JSON
  output_escaped=$(echo "$output" | jq -Rs .)
  file_json=$(echo -n "$file" | jq -Rs .)
  command_json=$(echo -n "${cmd[*]}" | jq -Rs .)
  echo "{\"status\":\"error\",\"message\":\"Failed to write metadata to ebook file\",\"path\":$file_json,\"command\":$command_json,\"command_output\":$output_escaped,\"exit_code\":$exit_code}"
  exit 1
fi

# Escape file path for JSON
file_json=$(echo -n "$file" | jq -Rs .)

echo "{\"status\":\"success\",\"file\":$file_json,\"message\":\"Metadata updated successfully\"}"
