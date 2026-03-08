This directory contains comprehensive end-to-end tests for the Ebook Library Power.

## Running Tests

Run the complete test suite:

```bash
./tests/run-tests.sh
```

This script will:

1. Clean up any existing test library
2. Create a fresh test library in `/tmp/ebook-test-library/`
3. Generate 6 test books with different metadata configurations
4. Run all 13 end-to-end tests
5. Display results

## Test Library Structure

The test script creates the following test library in `/tmp/ebook-test-library/`:

```
/tmp/ebook-test-library/
├── Downloads/
│   ├── stellar-voyager.epub               # Full metadata, series book 1
│   ├── duplicate-book.epub                # Duplicate of stellar-voyager
│   ├── book-with-missing-metadata.epub    # Minimal metadata
│   ├── quantum-horizon.epub               # Series book 2
│   ├── standalone-book.epub               # No series
│   └── multi-author-book.epub             # Multiple authors
└── Organized/                             # Target for organization tests
```

## Test Coverage

### Core Functionality (Tests 1-4)

- Calibre installation check
- Read metadata from EPUB files
- Write metadata to EPUB files
- Round-trip metadata integrity

### Workflows (Tests 5-7)

- Organize library by author/series
- Duplicate detection and removal
- Metadata cleanup workflow

### Platform & Paths (Test 8)

- Path handling and expansion

### Error Handling (Tests 9-10)

- Non-existent file errors
- Unsupported format errors

### Special Cases (Tests 11-13)

- Special characters (quotes, ampersands, HTML, Unicode)
- Multiple authors handling
- Series index decimal formatting

## Test Books Metadata

### 1. stellar-voyager.epub

- **Title:** Stellar Voyager
- **Author:** Alexandra Chen
- **Series:** Cosmic Adventures #1
- **Publisher:** Nebula Press
- **Tags:** science fiction, space exploration, adventure
- **ISBN:** 9781234567890

### 2. duplicate-book.epub

- Same title and author as stellar-voyager.epub
- Used for duplicate detection testing

### 3. book-with-missing-metadata.epub

- **Title:** Stellar Voyager
- **Author:** Alexandra Chen
- Minimal metadata (no series, publisher, tags)
- Used for metadata cleanup testing

### 4. quantum-horizon.epub

- **Title:** Quantum Horizon
- **Author:** Alexandra Chen
- **Series:** Cosmic Adventures #2
- Used for series organization testing

### 5. standalone-book.epub

- **Title:** Digital Dreams
- **Author:** Marcus Webb
- No series information
- Used for non-series organization testing

### 6. multi-author-book.epub

- **Title:** Chronicles of Tomorrow
- **Authors:** Sarah Johnson, David Park, Elena Rodriguez
- Used for multiple authors testing
