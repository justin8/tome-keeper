#!/bin/bash

# Fetch book metadata from Hardcover GraphQL API
# Outputs standardized JSON formatted for use with Tome Keeper workflows and write-metadata.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Ensure jq and curl are installed
if ! command -v jq &> /dev/null; then
  echo '{"status":"error","message":"jq is required but not installed."}'
  exit 1
fi

if ! command -v curl &> /dev/null; then
  echo '{"status":"error","message":"curl is required but not installed."}'
  exit 1
fi

# Default parameters
QUERY=""
ISBN=""
TITLE=""
AUTHOR=""
LIMIT=5
API_KEY=""
RAW_OUTPUT=false

# Print usage help
usage() {
  cat << 'EOF'
Usage: scripts/fetch-hardcover.sh [OPTIONS] [QUERY]

Search Hardcover for book metadata and output structured JSON.

Options:
  --query, -q <string>     Search query (title, author, or keywords)
  --isbn, -i <string>      Search specifically by ISBN-10 or ISBN-13
  --title, -t <string>     Book title
  --author, -a <string>    Author name
  --limit, -l <number>     Maximum results to return (default: 5)
  --api-key, -k <token>    Hardcover API personal access token
  --raw                    Output raw Hardcover GraphQL response
  --help, -h               Show this help message

Authentication:
  The Hardcover API token is resolved in this priority:
  1. --api-key CLI option
  2. $HARDCOVER_API_KEY or $HARDCOVER_TOKEN environment variable
  3. ~/.config/tome-keeper/credentials (or $XDG_CONFIG_HOME/tome-keeper/credentials)
  4. .env file in the current directory or repository root

Get your token at: https://hardcover.app/account/api
EOF
  exit 0
}

# Parse command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --query|-q)
      QUERY="$2"
      shift 2
      ;;
    --isbn|-i)
      ISBN="$2"
      shift 2
      ;;
    --title|-t)
      TITLE="$2"
      shift 2
      ;;
    --author|-a)
      AUTHOR="$2"
      shift 2
      ;;
    --limit|-l)
      LIMIT="$2"
      shift 2
      ;;
    --api-key|-k)
      API_KEY="$2"
      shift 2
      ;;
    --raw)
      RAW_OUTPUT=true
      shift
      ;;
    --help|-h)
      usage
      ;;
    -*)
      echo "{\"status\":\"error\",\"message\":\"Unknown option: $1\"}"
      exit 1
      ;;
    *)
      if [[ -z "$QUERY" ]]; then
        QUERY="$1"
      else
        QUERY="$QUERY $1"
      fi
      shift
      ;;
  esac
done

# Resolve API Key
if [[ -z "$API_KEY" ]]; then
  API_KEY=$(get_hardcover_api_key || true)
fi

if [[ -z "$API_KEY" ]]; then
  cat << 'EOF'
{
  "status": "error",
  "error_code": "MISSING_API_KEY",
  "message": "Hardcover API token not configured.",
  "help": "Set the HARDCOVER_API_KEY environment variable, create ~/.config/tome-keeper/credentials, or pass --api-key. Obtain an API key at https://hardcover.app/account/api"
}
EOF
  exit 1
fi

# Determine effective query string
EFFECTIVE_QUERY=""
if [[ -n "$ISBN" ]]; then
  # Clean ISBN of dashes and spaces
  EFFECTIVE_QUERY=$(echo "$ISBN" | tr -d ' -')
elif [[ -n "$QUERY" ]]; then
  EFFECTIVE_QUERY="$QUERY"
elif [[ -n "$TITLE" ]]; then
  if [[ -n "$AUTHOR" ]]; then
    EFFECTIVE_QUERY="$TITLE $AUTHOR"
  else
    EFFECTIVE_QUERY="$TITLE"
  fi
else
  cat << 'EOF'
{
  "status": "error",
  "message": "No search terms provided. Specify --query, --isbn, or --title."
}
EOF
  exit 1
fi

# Hardcover GraphQL endpoint
API_ENDPOINT="https://api.hardcover.app/v1/graphql"

# Prepare GraphQL payload using jq for safe JSON escaping
GRAPHQL_PAYLOAD=$(jq -n \
  --arg q "$EFFECTIVE_QUERY" \
  --argjson per_page "$LIMIT" \
  '{
    query: "query SearchBooks($q: String!, $per_page: Int!) { search(query: $q, per_page: $per_page) { results } }",
    variables: { q: $q, per_page: $per_page }
  }')

# Execute HTTP request
HTTP_RESPONSE=$(curl -s -S -w "\n%{http_code}" -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "$GRAPHQL_PAYLOAD" 2>&1) || {
    echo "{\"status\":\"error\",\"message\":\"Network error connecting to Hardcover API: $HTTP_RESPONSE\"}"
    exit 1
  }

# Split body and HTTP status code
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n 1)
HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

if [[ "$HTTP_STATUS" != "200" ]]; then
  ERROR_MSG=$(echo "$HTTP_BODY" | jq -r '.message // .error // "HTTP Error \('$HTTP_STATUS'\)"' 2>/dev/null || echo "HTTP $HTTP_STATUS")
  echo "{\"status\":\"error\",\"http_status\":$HTTP_STATUS,\"message\":\"$ERROR_MSG\"}"
  exit 1
fi

# Check for GraphQL errors
if echo "$HTTP_BODY" | jq -e '.errors' > /dev/null 2>&1; then
  GRAPHQL_ERR=$(echo "$HTTP_BODY" | jq -r '.errors[0].message // "Unknown GraphQL error"')
  echo "{\"status\":\"error\",\"message\":\"GraphQL error: $GRAPHQL_ERR\"}"
  exit 1
fi

# Return raw response if requested
if [[ "$RAW_OUTPUT" == "true" ]]; then
  echo "$HTTP_BODY"
  exit 0
fi

# Parse and normalize search results
FORMATTED_OUTPUT=$(echo "$HTTP_BODY" | jq \
  --arg query "$EFFECTIVE_QUERY" \
  '
  def clean_string:
    if . == null then null
    elif type == "string" then (if length == 0 then null else . end)
    else . end;

  (.data.search.results.hits // []) as $hits |
  [
    $hits[] | .document |
    (.featured_series.series.name // .series_names[0] // null | clean_string) as $series_name |
    ((.featured_series.position // .featured_series_position // null) | (if . != null then (. | tonumber) else null end)) as $series_idx |
    (.author_names // []) as $authors |
    ($authors | join(" & ") | clean_string) as $author_s |
    (.isbns // []) as $isbns |
    ($isbns[0] // null | clean_string) as $isbn |
    (.release_date // (if .release_year then "\(.release_year)-01-01" else null end) | clean_string) as $published |
    ((.genres // []) + (.tags // []) | unique) as $all_tags |
    (.image.url // null | clean_string) as $cover_url |
    (.slug // null | clean_string) as $slug |
    (if $slug != null then "https://hardcover.app/books/\($slug)" else null end) as $book_url |
    
    # Pre-built metadata payload ready to pass to write-metadata.sh
    {
      title: (.title | clean_string),
      authors: (if ($authors | length) > 0 then $authors else null end),
      series: $series_name,
      series_index: $series_idx,
      isbn: $isbn,
      published: $published,
      comments: (.description | clean_string),
      tags: (if ($all_tags | length) > 0 then $all_tags else null end)
    } as $calibre_meta |

    {
      hardcover_id: (.id | tostring),
      title: (.title | clean_string),
      subtitle: (.subtitle // null | clean_string),
      authors: $authors,
      author_s: $author_s,
      series: $series_name,
      series_index: $series_idx,
      published: $published,
      release_year: (.release_year // null),
      isbn: $isbn,
      isbns: $isbns,
      description: (.description | clean_string),
      genres: (.genres // []),
      tags: $all_tags,
      pages: (.pages // null),
      rating: (.rating // null),
      cover_url: $cover_url,
      hardcover_url: $book_url,
      calibre_metadata: ($calibre_meta | with_entries(select(.value != null)))
    }
  ] as $results |
  {
    status: "success",
    source: "hardcover",
    query: $query,
    count: ($results | length),
    results: $results
  }
')

echo "$FORMATTED_OUTPUT"
