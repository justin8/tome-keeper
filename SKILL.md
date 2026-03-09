---
name: tome-keeper
description: Manage ebook libraries using Calibre's ebook-meta tool. Use this skill when users mention organizing ebooks, fixing book metadata, managing EPUB/MOBI/AZW files, searching their book collection, cleaning up library metadata, or working with Calibre. Also trigger for tasks involving book titles, authors, series information, ISBNs, or organizing digital reading collections.
---

# Tome Keeper Skill

This skill enables you to help users manage their ebook collections through Calibre's metadata tools. You can read and write ebook metadata, organize libraries, clean up missing information, and maintain well-structured book collections.

## Core Capabilities

- Read and write ebook metadata (title, authors, series, ISBN, description, tags, etc.)
- Find ebook files across directory structures using glob patterns
- Organize ebooks by author, series, or custom structures
- Clean up and enrich metadata from online sources
- Move and delete ebook files safely
- Support for EPUB, MOBI, AZW, and AZW3 formats

## When to Use This Skill

Trigger this skill when users ask about:
- Organizing messy ebook collections
- Fixing missing or incorrect metadata
- Searching for books by title, author, or series
- Moving books into structured directory hierarchies
- Finding duplicate ebooks
- Batch updating book information
- Creating author/series folder structures
- Enriching metadata from online book databases

## Getting Started

### 1. Verify Dependencies

Before performing any ebook operations, check that Calibre and jq are installed:

```bash
scripts/check-calibre.sh
jq --version
```

If either is missing, provide installation instructions based on the user's platform.

### 2. Find Ebooks

Use glob patterns or find commands to discover ebook files:

```bash
# Find all ebooks recursively
find ~/Books -type f \( -name "*.epub" -o -name "*.mobi" -o -name "*.azw" -o -name "*.azw3" \)

# Find in specific directory
find ~/Books/Author\ Name -name "*.epub"

# Search by filename pattern
find ~/Books -type f -iname "*keyword*" \( -name "*.epub" -o -name "*.mobi" -o -name "*.azw" -o -name "*.azw3" \)
```

### 3. Read Metadata

Use the read-metadata.sh script to extract metadata from an ebook:

```bash
scripts/read-metadata.sh "/path/to/book.epub"
```

Expected JSON output:
```json
{
  "status": "success",
  "file": "/path/to/book.epub",
  "metadata": {
    "title": "Book Title",
    "author_s": "Author Name",
    "authors": ["Author Name"],
    "series": "Series Name",
    "series_index": "1.0",
    "isbn": "1234567890",
    "publisher": "Publisher Name",
    "published": "2024-01-01",
    "language": "eng",
    "comments": "Book description...",
    "tags": "fiction, fantasy"
  }
}
```

Always check the `status` field before processing metadata.

### 4. Write Metadata

Use the write-metadata.sh script to update metadata:

```bash
scripts/write-metadata.sh "/path/to/book.epub" '{"title": "New Title", "authors": ["Author One", "Author Two"]}'
```

Only specified fields are updated; other metadata is preserved.

## Available Scripts

The skill provides three shell scripts in the `scripts/` directory:

### check-calibre.sh
Verifies Calibre installation and returns version information.

### read-metadata.sh
Reads metadata from an ebook file and outputs structured JSON.

**Parameters:**
- `file_path`: Path to the ebook file (supports ~ expansion)

**Supported formats:** .epub, .mobi, .azw, .azw3

### write-metadata.sh
Writes metadata to an ebook file.

**Parameters:**
- `file_path`: Path to the ebook file
- `json_metadata`: JSON string with metadata fields to update

**Supported metadata fields:**
- `title`: Book title (string)
- `authors`: Author names (array of strings, joined with " & ")
- `series`: Series name (string)
- `series_index`: Position in series (number, formatted as decimal)
- `isbn`: ISBN identifier (string)
- `publisher`: Publisher name (string)
- `published`: Publication date (string, YYYY-MM-DD)
- `language`: Language code (string, e.g., "eng")
- `tags`: Tags (array of strings or comma-separated string)
- `comments`: Book description (string, can contain HTML)

**Important notes:**
- Multiple authors are joined with " & " separator per Calibre conventions
- Series index is formatted as decimal (e.g., 1.0, 2.0, 3.0)
- Use decimal values (e.g., 2.5, 3.7) for books between major releases like novellas, short stories, or side stories that fall between main series entries
- Special characters are properly escaped by the script

## Common Workflows

### Workflow 1: Organize Library by Author and Series

When a user wants to organize their ebook collection, follow this pattern:

1. Find all ebooks in the source directory
2. Read metadata from each ebook
3. Determine target path based on author and series
4. Create target directories and move files

**Directory structure:**
```
~/Books/
  ├── Brown, Pierce/
  │   └── Red Rising/
  │       ├── Red Rising/
  │       │   └── Red Rising - Pierce Brown.epub
  │       ├── Golden Son/
  │       │   └── Golden Son - Pierce Brown.epub
  │       └── Morning Star/
  │           └── Morning Star - Pierce Brown.epub
  └── Fitzgerald, F. Scott/
      └── The Great Gatsby/
          └── The Great Gatsby - F. Scott Fitzgerald.epub
```

**Folder structure rules:**
- Top level: `Lastname, Firstname/`
- Series books: `Lastname, Firstname/Series Name/Book Title/Book Title - Author Name.ext`
- Standalone books: `Lastname, Firstname/Book Title/Book Title - Author Name.ext`
- Each book gets its own subfolder for potential companion files (covers, extras)

**Implementation pattern:**
```bash
# Find all ebooks
find ~/Downloads/Ebooks -type f \( -name "*.epub" -o -name "*.mobi" -o -name "*.azw" -o -name "*.azw3" \)

# For each file:
for file in files:
  # Read metadata
  result=$(./scripts/read-metadata.sh "$file")
  
  # Parse JSON and extract author, series, title
  # Format author as "Lastname, Firstname"
  # Determine target path:
  # - If series: ~/Books/{lastname, firstname}/{series}/{title}/{title} - {author}.{ext}
  # - If no series: ~/Books/{lastname, firstname}/{title}/{title} - {author}.{ext}
  
  # Create target directory and move file
  mkdir -p "$(dirname "$target_path")"
  mv "$file" "$target_path"
```

**Handle edge cases:**
- Books without authors → place in "Unknown Author" directory
- Books with multiple authors → use first author as primary
- Author name parsing → convert "Firstname Lastname" to "Lastname, Firstname" format
- Books without series → create book title folder directly under author
- Missing metadata → place in "Needs Review" directory for manual inspection

### Workflow 2: Clean Up Missing Metadata

When users want to fix missing or incorrect metadata:

1. Scan library for books with incomplete metadata
2. Use web_search to find accurate information
3. Extract metadata from search results or book databases
4. Update ebook files with corrected information

**Identify books needing cleanup:**
```bash
# For each ebook, check for:
# - Missing title
# - Missing authors
# - Missing ISBN
# - Missing description
# - Missing series info (if applicable)
```

**Search for book information:**
```bash
# Build search query from available metadata
query="${title} ${author} book"

# Search online
remote_web_search("$query")

# Or search by ISBN for most accurate results
remote_web_search("ISBN ${isbn}")
```

**Extract and apply updates:**
- Look for Open Library, Goodreads, or Google Books results
- Extract ISBN, publisher, publication date, series info
- Use conservative updates (only fill missing fields)
- Verify information matches before applying

**Rate limiting:** Add delays between web searches (2-3 seconds) to avoid being blocked.

### Workflow 3: Find and Handle Duplicates

Help users identify duplicate ebooks:

1. Find all ebooks in library
2. Read metadata from each
3. Group by title and author
4. Identify duplicates (same title/author, different files)
5. Present options: keep best quality, delete duplicates, or move to archive

**Duplicate detection criteria:**
- Exact title and author match
- Similar titles (fuzzy matching)
- Same ISBN
- Same file hash (for identical files)

### Workflow 4: Enrich Metadata from Online Sources

When users want to add missing information:

1. Read current metadata
2. Search for book by title/author or ISBN
3. Fetch detailed information from book databases
4. Update with publisher, publication date, description, tags
5. Optionally download and embed cover images

**Reliable sources:**
- Open Library API: `https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&format=json&jscmd=data`
- Google Books API: `https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}`
- Goodreads (via web scraping)

**Best practices:**
- Prefer ISBN lookups over title/author searches
- Cross-reference multiple sources for accuracy
- Always backup before batch updates
- Log all changes for auditing

### Workflow 5: Process New Ebook and Add to Library

When a user provides a new ebook file that needs metadata updates and organization:

1. Read current metadata from the file
2. Identify missing or incorrect information
3. Search online for accurate metadata (prefer ISBN lookups when available)
4. Update the ebook's metadata with found information
5. Re-read metadata to get updated values
6. Determine correct location in library based on author and series
7. Create target directory and move file

**Example scenario:**
User says: "I just downloaded 'Red Rising.epub' to my Downloads folder. Can you update its metadata and add it to my library?"

1. Read metadata from ~/Downloads/Red Rising.epub
2. Search for "Red Rising Pierce Brown book" online
3. Find it's book 1 of the Red Rising series
4. Update metadata: series="Red Rising", series_index=1.0, plus any missing ISBN/publisher/description
5. Move to ~/Books/Brown, Pierce/Red Rising/Red Rising/Red Rising - Pierce Brown.epub

**Key considerations:**
- Always show the user what metadata will be updated before applying
- Confirm the target location before moving
- Handle cases where the book already exists at target (ask to overwrite or rename)
- If metadata is already complete, skip directly to organizing

## Handling Special Cases

### Anthologies and Collections

Anthologies contain multiple stories by different authors. The "author" field might be the editor.

**Detection:**
- Title contains "anthology" or "collection"
- Comments mention "stories by" or "edited by"

**Handling:**
- Search for "anthology" + title to find editor information
- Update author as "Editor Name (Editor)"
- Consider adding all contributing authors to tags

### Series Information

Many books are part of a series but lack series metadata.

**Detection patterns:**
- Title contains "(Series Name)"
- Title contains "Book 1 of Series"
- Title contains "Series: Book 1"
- Title contains "#1 in Series"

**Enrichment:**
- Search online for "{title} {author} series"
- Extract series name and index from search results
- Update metadata with series and series_index fields

### Books with Incorrect Metadata

Sometimes metadata is present but wrong.

**Verification:**
- Search for "{title} {author} book"
- Check if search results confirm the combination
- If no matches found, metadata might be incorrect
- Flag for manual review

### Multiple Authors

For books with multiple authors:

**Option 1:** Use first author as primary (simplest)
**Option 2:** Create "Multiple Authors" directory
**Option 3:** Create symlinks under each author (advanced)

Choose based on user preference and library size.

## File Operations

### Moving Files

Use standard shell commands to move ebooks:
```bash
# Create target directory if it doesn't exist
mkdir -p "$(dirname "$target_path")"

# Move the file
mv "$source_path" "$target_path"
```

Benefits:
- Works on any Unix-like system
- Automatically overwrites if target exists
- Handles path expansion (~)

### Deleting Files

⚠️ **WARNING:** File deletion is permanent and cannot be undone.

Use rm only when:
- User explicitly confirms deletion
- You've verified the file is a duplicate
- You've shown the user what will be deleted

**Safer alternative:** Move to archive directory instead:
```bash
mkdir -p ~/Books/.archive
mv "$file" ~/Books/.archive/
```

### Sanitizing Filenames

When creating file paths from metadata, sanitize names:
- Remove invalid characters: `< > : " / \ | ? *`
- Normalize whitespace
- Trim leading/trailing spaces
- Handle special characters that cause filesystem issues

## Error Handling

Always check the `status` field in script output:

```json
{
  "status": "error",
  "message": "File not found: /path/to/book.epub"
}
```

**Common errors:**
- File not found → verify path and permissions
- Unsupported format → only EPUB, MOBI, AZW, AZW3 supported
- Calibre not installed → provide installation instructions
- JSON parsing errors → check if jq is installed
- Corrupted ebook file → skip and log for manual review

**Error recovery:**
- Don't stop batch operations on single file errors
- Log errors for user review
- Provide clear error messages with suggested fixes
- Offer to retry failed operations

## Best Practices

1. **Always backup before bulk operations**: Warn users to backup their library before making large-scale changes.

2. **Test on small batches first**: Run workflows on 5-10 books before processing entire libraries.

3. **Verify before writing**: Read metadata first, make changes, then write back. Never blindly overwrite.

4. **Use web sources for accuracy**: Cross-reference metadata with Open Library or Google Books.

5. **Follow Calibre conventions**: 
   - Use " & " for multiple authors
   - Use decimal format for series_index (1.0, 2.0, 3.0 for main entries)
   - Use decimal values between integers (2.5, 3.7) for books between major releases like novellas, short stories, or side stories
   - Use proper language codes (eng, fra, deu, etc.)

6. **Handle errors gracefully**: Check status fields and continue processing on errors.

7. **Log all changes**: Keep a record of metadata changes for auditing:
   ```bash
   echo "$(date): Updated $file" >> ~/Books/changes.log
   ```

8. **Rate limit web requests**: Add 2-3 second delays between searches to avoid being blocked.

9. **Sanitize filenames**: Remove special characters that cause filesystem issues.

10. **Preserve originals**: Consider copying instead of moving if user wants to keep original structure.

## Troubleshooting

### Books organized under wrong author
The metadata might have author in "Last, First" format. Parse and normalize:
```bash
# Convert "Last, First" to "First Last"
```

### Series directories have inconsistent names
Normalize series names by removing parenthetical information or subtitles.

### Some books fail to move
Check file permissions and ensure target directory is writable. Verify source files aren't open in another application.

### Web searches return irrelevant results
Make search queries more specific by including format and publication year:
```bash
remote_web_search("\"${title}\" \"${author}\" book epub")
```

### Metadata updates don't persist
Verify the file isn't read-only and check for file corruption by reading metadata after writing.

### Rate limited by web services
Increase delay between requests and implement exponential backoff retry logic.

## Implementation Tips

When implementing these workflows:

1. **Parse JSON carefully**: Always use `JSON.parse()` or `jq` to parse script output.

2. **Escape shell arguments**: Use proper quoting for file paths and JSON strings:
   ```bash
   scripts/read-metadata.sh "${file_path}"
   scripts/write-metadata.sh "${file_path}" '${json_string}'
   ```

3. **Handle paths with spaces**: Always quote file paths in shell commands.

4. **Check for empty results**: Verify glob returns files before processing.

5. **Provide progress updates**: For batch operations, show progress to the user:
   ```
   Processing book 15 of 127...
   ```

6. **Summarize results**: After batch operations, show summary:
   ```
   Organized: 120 books
   Skipped: 5 books (missing metadata)
   Errors: 2 books (see log for details)
   ```

7. **Ask before destructive operations**: Always confirm before deleting files or overwriting metadata.

## Script Locations

All scripts are in the `scripts/` directory relative to the skill root:
- `scripts/check-calibre.sh`
- `scripts/read-metadata.sh`
- `scripts/write-metadata.sh`

The scripts handle platform detection (macOS vs Linux) and path expansion automatically.

## Summary

This skill empowers you to help users maintain well-organized, properly-tagged ebook libraries. Focus on understanding user intent, verifying operations before execution, and providing clear feedback throughout the process. Always prioritize data safety by backing up, testing on small batches, and confirming destructive operations.

The combination of Calibre's robust metadata tools, file operations, and web search capabilities makes this skill powerful for both simple organization tasks and complex metadata enrichment workflows.
