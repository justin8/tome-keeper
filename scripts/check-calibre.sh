#!/bin/bash

# Check if Calibre is installed and return installation status
# Outputs JSON with installation status, command path, and version

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions for platform detection
source "$SCRIPT_DIR/common.sh"

# Get installation instructions for current platform
get_install_instructions() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Install Calibre from https://calibre-ebook.com/download_osx"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Install Calibre: sudo apt-get install calibre (Ubuntu/Debian) or sudo dnf install calibre (Fedora)"
  else
    echo "Install Calibre from https://calibre-ebook.com/download"
  fi
}

# Check if Calibre is installed
if [[ -z "$EBOOK_META_CMD" ]]; then
  instructions=$(get_install_instructions)
  # Escape instructions for JSON
  instructions_json=$(echo "$instructions" | jq -Rs .)
  echo "{\"status\":\"error\",\"installed\":false,\"message\":\"Calibre not found. The ebook-meta command is not available on this system.\",\"instructions\":$instructions_json}"
  exit 1
fi

# Verify the command is executable
if [[ ! -x "$EBOOK_META_CMD" ]] && ! command -v "$EBOOK_META_CMD" &> /dev/null; then
  echo "{\"status\":\"error\",\"installed\":false,\"message\":\"ebook-meta command found but not executable: $EBOOK_META_CMD\",\"command\":\"$EBOOK_META_CMD\"}"
  exit 1
fi

# Get Calibre version
version_output=$("$EBOOK_META_CMD" --version 2>&1)
version_exit_code=$?

if [[ $version_exit_code -ne 0 ]]; then
  version_output_json=$(echo "$version_output" | jq -Rs .)
  echo "{\"status\":\"error\",\"installed\":false,\"message\":\"Failed to get Calibre version\",\"command\":\"$EBOOK_META_CMD\",\"command_output\":$version_output_json}"
  exit 1
fi

version=$(echo "$version_output" | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')

if [[ -z "$version" ]]; then
  version="unknown"
fi

# Escape command path for JSON
command_json=$(echo -n "$EBOOK_META_CMD" | jq -Rs .)

# Return success with installation details
echo "{\"status\":\"success\",\"installed\":true,\"command\":$command_json,\"version\":\"$version\"}"
