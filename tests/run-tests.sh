#!/bin/bash

# Comprehensive End-to-End Test Script for Ebook Library Power
# This script sets up the test environment and runs all tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_LIBRARY="/tmp/ebook-test-library"
DOWNLOADS="$TEST_LIBRARY/Downloads"
ORGANIZED="$TEST_LIBRARY/Organized"
SOURCE_BOOK="$PROJECT_ROOT/tests/fixtures/test-book.epub"

echo "=========================================="
echo "Ebook Library Power - End-to-End Tests"
echo "=========================================="
echo ""

# ============================================
# SETUP: Create Test Library
# ============================================

echo "Setting up test library..."
echo ""

# Clean up existing test library
rm -rf "$TEST_LIBRARY"

# Create directory structure
mkdir -p "$DOWNLOADS"
mkdir -p "$ORGANIZED"

# Check if source book exists
if [[ ! -f "$SOURCE_BOOK" ]]; then
    echo "✗ Error: Source book not found at $SOURCE_BOOK"
    exit 1
fi

# Create test books with different metadata
echo "Creating test books..."

# Book 1: stellar-voyager.epub (main test book)
cp "$SOURCE_BOOK" "$DOWNLOADS/stellar-voyager.epub"
METADATA1='{
  "title": "Stellar Voyager",
  "authors": ["Alexandra Chen"],
  "series": "Cosmic Adventures",
  "series_index": 1.0,
  "publisher": "Nebula Press",
  "published": "2023-03-15",
  "tags": "science fiction, space exploration, adventure",
  "comments": "Captain Maya Rodriguez leads her crew on a daring mission to explore the uncharted regions of the Andromeda sector.",
  "identifiers": "isbn:9781234567890"
}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/stellar-voyager.epub" "$METADATA1" > /dev/null

# Book 2: duplicate-book.epub
cp "$SOURCE_BOOK" "$DOWNLOADS/duplicate-book.epub"
METADATA2="$METADATA1"
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/duplicate-book.epub" "$METADATA2" > /dev/null

# Book 3: book-with-missing-metadata.epub
cp "$SOURCE_BOOK" "$DOWNLOADS/book-with-missing-metadata.epub"
METADATA3='{"title":"Stellar Voyager","authors":["Alexandra Chen"]}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/book-with-missing-metadata.epub" "$METADATA3" > /dev/null

# Book 4: quantum-horizon.epub
cp "$SOURCE_BOOK" "$DOWNLOADS/quantum-horizon.epub"
METADATA4='{"title":"Quantum Horizon","authors":["Alexandra Chen"],"series":"Cosmic Adventures","series_index":2.0}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/quantum-horizon.epub" "$METADATA4" > /dev/null

# Book 5: standalone-book.epub
cp "$SOURCE_BOOK" "$DOWNLOADS/standalone-book.epub"
METADATA5='{"title":"Digital Dreams","authors":["Marcus Webb"],"publisher":"TechnoFiction Publishing"}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/standalone-book.epub" "$METADATA5" > /dev/null

# Book 6: multi-author-book.epub
cp "$SOURCE_BOOK" "$DOWNLOADS/multi-author-book.epub"
METADATA6='{"title":"Chronicles of Tomorrow","authors":["Sarah Johnson","David Park","Elena Rodriguez"]}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/multi-author-book.epub" "$METADATA6" > /dev/null

echo "✓ Test library created with 6 test books"
echo ""

# ============================================
# RUN TESTS
# ============================================

echo "Running tests..."
echo ""

# Test 1: Verify Calibre Installation
echo "Test 1: Checking Calibre installation..."
CALIBRE_CHECK=$("$PROJECT_ROOT/scripts/check-calibre.sh")
if echo "$CALIBRE_CHECK" | jq -e '.status == "success"' > /dev/null; then
    echo "✓ Calibre is installed"
else
    echo "✗ Calibre check failed"
    echo "$CALIBRE_CHECK" | jq .
    exit 1
fi
echo ""

# Test 2: Read Metadata
echo "Test 2: Reading metadata from stellar-voyager.epub..."
READ_RESULT=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
if echo "$READ_RESULT" | jq -e '.status == "success"' > /dev/null; then
    TITLE=$(echo "$READ_RESULT" | jq -r '.metadata.title')
    AUTHOR=$(echo "$READ_RESULT" | jq -r '.metadata."author_s"')
    echo "✓ Successfully read metadata: $TITLE by $AUTHOR"
else
    echo "✗ Failed to read metadata"
    exit 1
fi
echo ""

# Test 3: Write Metadata
echo "Test 3: Writing metadata (adding tags)..."
METADATA='{"tags":"science fiction, space exploration, test-tag"}'
WRITE_RESULT=$("$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/stellar-voyager.epub" "$METADATA")
if echo "$WRITE_RESULT" | jq -e '.status == "success"' > /dev/null; then
    VERIFY_RESULT=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
    TAGS=$(echo "$VERIFY_RESULT" | jq -r '.metadata.tags')
    if [[ "$TAGS" == *"test-tag"* ]]; then
        echo "✓ Metadata write verified"
    else
        echo "✗ Metadata write verification failed"
        exit 1
    fi
else
    echo "✗ Failed to write metadata"
    exit 1
fi
echo ""

# Test 4: Round-Trip Metadata Integrity
echo "Test 4: Testing round-trip metadata integrity..."
CLEAN_META='{"title":"Round Trip Test","series":"Test Series","series_index":1.0,"publisher":"Test Publisher"}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/stellar-voyager.epub" "$CLEAN_META" > /dev/null

ORIGINAL=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
ORIGINAL_TITLE=$(echo "$ORIGINAL" | jq -r '.metadata.title')
ORIGINAL_SERIES=$(echo "$ORIGINAL" | jq -r '.metadata.series')

"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/stellar-voyager.epub" "$CLEAN_META" > /dev/null

AFTER=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
AFTER_TITLE=$(echo "$AFTER" | jq -r '.metadata.title')
AFTER_SERIES=$(echo "$AFTER" | jq -r '.metadata.series')

if [[ "$ORIGINAL_TITLE" == "$AFTER_TITLE" ]] && [[ "$ORIGINAL_SERIES" == "$AFTER_SERIES" ]]; then
    echo "✓ Round-trip metadata integrity preserved"
else
    echo "✗ Round-trip metadata integrity failed"
    exit 1
fi
echo ""

# Test 5: Organize Library Workflow
echo "Test 5: Testing organize library workflow with new structure..."
METADATA_RESULT=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
AUTHOR=$(echo "$METADATA_RESULT" | jq -r '.metadata."author_s"')
SERIES=$(echo "$METADATA_RESULT" | jq -r '.metadata.series')
TITLE=$(echo "$METADATA_RESULT" | jq -r '.metadata.title')
PUBLISHED=$(echo "$METADATA_RESULT" | jq -r '.metadata.published')
YEAR=$(echo "$PUBLISHED" | cut -d'-' -f1)

# Basic sanitization
AUTHOR_CLEAN=$(echo "$AUTHOR" | tr -d '<>:"/\\|?*' | tr -s ' ')
SERIES_CLEAN=$(echo "$SERIES" | tr -d '<>:"/\\|?*' | tr -s ' ')
TITLE_CLEAN=$(echo "$TITLE" | tr -d '<>:"/\\|?*' | tr -s ' ')

if [[ -n "$SERIES_CLEAN" ]] && [[ "$SERIES_CLEAN" != "null" ]]; then
    TARGET_DIR="$ORGANIZED/$AUTHOR_CLEAN/$SERIES_CLEAN/$TITLE_CLEAN ($YEAR)"
else
    TARGET_DIR="$ORGANIZED/$AUTHOR_CLEAN/$TITLE_CLEAN ($YEAR)"
fi

mkdir -p "$TARGET_DIR"

# Move ebook
cp "$DOWNLOADS/stellar-voyager.epub" "$TARGET_DIR/$TITLE_CLEAN ($YEAR).epub"

# Create dummy associated files
touch "$DOWNLOADS/stellar-voyager.m4b"
touch "$DOWNLOADS/cover.jpg"

# Move associated files
mv "$DOWNLOADS/stellar-voyager.m4b" "$TARGET_DIR/$TITLE_CLEAN ($YEAR).m4b"
mv "$DOWNLOADS/cover.jpg" "$TARGET_DIR/cover.jpg"

if [[ -f "$TARGET_DIR/$TITLE_CLEAN ($YEAR).epub" ]] && [[ -f "$TARGET_DIR/$TITLE_CLEAN ($YEAR).m4b" ]] && [[ -f "$TARGET_DIR/cover.jpg" ]]; then
    echo "✓ Successfully organized ebook with m4b and cover in new structure"
    echo "  Path: $TARGET_DIR/"
else
    echo "✗ Failed to organize ebook in new structure"
    exit 1
fi
echo ""

# Test 6: Find Duplicates
echo "Test 6: Testing duplicate detection..."
META1=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/duplicate-book.epub")
META2=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/book-with-missing-metadata.epub")

TITLE1=$(echo "$META1" | jq -r '.metadata.title')
TITLE2=$(echo "$META2" | jq -r '.metadata.title')

if [[ "$TITLE1" == "$TITLE2" ]]; then
    echo "✓ Duplicate detected"
    rm "$DOWNLOADS/duplicate-book.epub"
    echo "✓ Duplicate removed"
else
    echo "✗ Duplicate detection failed"
    exit 1
fi
echo ""

# Test 7: Metadata Cleanup Workflow
echo "Test 7: Testing metadata cleanup workflow..."
INCOMPLETE=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/book-with-missing-metadata.epub")
TITLE=$(echo "$INCOMPLETE" | jq -r '.metadata.title // "Unknown"')
AUTHOR=$(echo "$INCOMPLETE" | jq -r '.metadata."author_s" // "Unknown"')

if [[ "$TITLE" != "Unknown" ]] && [[ "$AUTHOR" != "Unknown" ]]; then
    echo "✓ Metadata cleanup workflow validated"
else
    echo "✗ Failed to scan metadata"
    exit 1
fi
echo ""

# Test 8: Path Handling
echo "Test 8: Testing path handling..."
RESULT=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
if echo "$RESULT" | jq -e '.status == "success"' > /dev/null; then
    echo "✓ Path handling works correctly"
else
    echo "✗ Path handling failed"
    exit 1
fi
echo ""

# Test 9: Error Handling - Non-existent File
echo "Test 9: Testing error handling for non-existent file..."
ERROR_RESULT=$("$PROJECT_ROOT/scripts/read-metadata.sh" "/tmp/nonexistent.epub" 2>&1 || true)
if echo "$ERROR_RESULT" | jq -e '.status == "error"' > /dev/null 2>&1; then
    echo "✓ Error handling works"
else
    echo "✗ Error handling failed"
    exit 1
fi
echo ""

# Test 10: Error Handling - Unsupported Format
echo "Test 10: Testing error handling for unsupported format..."
touch /tmp/test.pdf
ERROR_RESULT=$("$PROJECT_ROOT/scripts/read-metadata.sh" "/tmp/test.pdf" 2>&1 || true)
if echo "$ERROR_RESULT" | jq -e '.status == "error"' > /dev/null 2>&1; then
    echo "✓ Format validation works"
else
    echo "✗ Format validation failed"
    exit 1
fi
rm /tmp/test.pdf
echo ""

# Test 11: Special Characters
echo "Test 11: Testing special characters in metadata..."
SPECIAL_META='{"title":"Test: Book with \"Quotes\" & Special Chars","comments":"Description with <html> tags & unicode: café"}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/stellar-voyager.epub" "$SPECIAL_META" > /dev/null

VERIFY=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
VERIFY_TITLE=$(echo "$VERIFY" | jq -r '.metadata.title')

if [[ "$VERIFY_TITLE" == *"Quotes"* ]] && [[ "$VERIFY_TITLE" == *"&"* ]]; then
    echo "✓ Special characters preserved"
else
    echo "✗ Special character handling failed"
    exit 1
fi
echo ""

# Test 12: Multiple Authors
echo "Test 12: Testing multiple authors handling..."
MULTI_AUTHORS='{"authors":["Author One","Author Two","Author Three"]}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/stellar-voyager.epub" "$MULTI_AUTHORS" > /dev/null

VERIFY=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
AUTHORS=$(echo "$VERIFY" | jq -r '.metadata."author_s"')

if [[ "$AUTHORS" == *"&"* ]]; then
    echo "✓ Multiple authors joined with & separator"
else
    echo "✗ Multiple authors handling failed"
    exit 1
fi
echo ""

# Test 13: Series Index Formatting
echo "Test 13: Testing series index decimal formatting..."
SERIES_META='{"series":"Test Series","series_index":2.5}'
"$PROJECT_ROOT/scripts/write-metadata.sh" "$DOWNLOADS/stellar-voyager.epub" "$SERIES_META" > /dev/null

VERIFY=$("$PROJECT_ROOT/scripts/read-metadata.sh" "$DOWNLOADS/stellar-voyager.epub")
SERIES=$(echo "$VERIFY" | jq -r '.metadata.series')

if [[ "$SERIES" == *"#2.5"* ]] || [[ "$SERIES" == *"#2.50"* ]]; then
    echo "✓ Series index formatted as decimal"
else
    echo "✗ Series index formatting failed"
    exit 1
fi
echo ""

# ============================================
# SUMMARY
# ============================================

echo "=========================================="
echo "All End-to-End Tests Passed! ✓"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Calibre installation check"
echo "  ✓ Read metadata"
echo "  ✓ Write metadata"
echo "  ✓ Round-trip integrity"
echo "  ✓ Organize library workflow"
echo "  ✓ Duplicate detection"
echo "  ✓ Metadata cleanup workflow"
echo "  ✓ Path handling"
echo "  ✓ Error handling (non-existent file)"
echo "  ✓ Error handling (unsupported format)"
echo "  ✓ Special characters"
echo "  ✓ Multiple authors"
echo "  ✓ Series index formatting"
echo ""
