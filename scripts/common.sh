#!/bin/bash

# Common functions for ebook library management scripts
# Provides platform detection and shared utilities for Calibre integration

# Detect platform and return the appropriate ebook-meta command path
get_ebook_meta_cmd() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - Calibre installs to /Applications
    if [[ -f "/Applications/calibre.app/Contents/MacOS/ebook-meta" ]]; then
      echo "/Applications/calibre.app/Contents/MacOS/ebook-meta"
    else
      echo ""
    fi
  else
    # Linux - check if ebook-meta is in PATH
    if command -v ebook-meta &> /dev/null; then
      echo "ebook-meta"
    else
      echo ""
    fi
  fi
}


# Expand file path to handle ~, relative, and absolute paths
# Returns the expanded absolute path using cd for resolution
expand_path() {
  local file="$1"
  local dir
  local base
  
  # Get directory and basename
  dir="$(dirname "$file")"
  base="$(basename "$file")"
  
  # Use cd to resolve the directory path (handles ~, relative, and absolute)
  if dir=$(cd "$dir" 2>/dev/null && pwd); then
    echo "$dir/$base"
  else
    # If cd fails, return the original path (will fail validation later)
    echo "$file"
  fi
}

# Validate file exists and has supported extension
# Returns the expanded file path on success, or JSON error on failure
validate_ebook_file() {
  local file="$1"
  
  # Check if file path is provided
  if [[ -z "$file" ]]; then
    echo "{\"status\":\"error\",\"message\":\"File path is required\"}"
    return 1
  fi
  
  # Expand path (handles ~, relative, and absolute paths)
  file=$(expand_path "$file")
  
  # Check if file exists
  if [[ ! -f "$file" ]]; then
    echo "{\"status\":\"error\",\"message\":\"File not found: $file\",\"path\":\"$file\"}"
    return 1
  fi
  
  # Check if file is readable
  if [[ ! -r "$file" ]]; then
    echo "{\"status\":\"error\",\"message\":\"File is not readable (permission denied): $file\",\"path\":\"$file\"}"
    return 1
  fi
  
  # Check file extension
  local ext="${file##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  
  if [[ ! "$ext" =~ ^(epub|mobi|azw|azw3)$ ]]; then
    echo "{\"status\":\"error\",\"message\":\"Unsupported format: .$ext. Supported formats: .epub, .mobi, .azw, .azw3\",\"path\":\"$file\",\"extension\":\".$ext\"}"
    return 1
  fi
  
  echo "$file"
  return 0
}

# Retrieve Hardcover API key from environment, user config, or .env files
get_hardcover_api_key() {
  local key="${HARDCOVER_API_KEY:-${HARDCOVER_TOKEN:-}}"
  
  if [[ -n "$key" ]]; then
    echo "$key"
    return 0
  fi

  # Check XDG config or ~/.config/tome-keeper/credentials
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tome-keeper"
  if [[ -f "$config_dir/credentials" ]]; then
    local cred
    cred=$(grep -E '^(HARDCOVER_API_KEY|HARDCOVER_TOKEN)=' "$config_dir/credentials" 2>/dev/null | head -n 1 | cut -d '=' -f2- | tr -d '"'\'' ')
    if [[ -z "$cred" ]]; then
      cred=$(head -n 1 "$config_dir/credentials" 2>/dev/null | tr -d '\r\n ')
      if [[ "$cred" =~ ^(HARDCOVER|#) ]]; then cred=""; fi
    fi
    if [[ -n "$cred" ]]; then
      echo "$cred"
      return 0
    fi
  fi

  # Check config.json
  if [[ -f "$config_dir/config.json" ]] && command -v jq &>/dev/null; then
    local cred
    cred=$(jq -r '.hardcover_api_key // .hardcover_token // empty' "$config_dir/config.json" 2>/dev/null)
    if [[ -n "$cred" ]]; then
      echo "$cred"
      return 0
    fi
  fi

  # Check .env in current directory or project root
  local script_root
  script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
  local env_files=(".env" "$script_root/.env")
  for env_file in "${env_files[@]}"; do
    if [[ -f "$env_file" ]]; then
      local cred
      cred=$(grep -E '^(HARDCOVER_API_KEY|HARDCOVER_TOKEN)=' "$env_file" 2>/dev/null | head -n 1 | cut -d '=' -f2- | tr -d '"'\'' ')
      if [[ -n "$cred" ]]; then
        echo "$cred"
        return 0
      fi
    fi
  done

  echo ""
  return 1
}

# Export the ebook-meta command for use in other scripts
export EBOOK_META_CMD=$(get_ebook_meta_cmd)
