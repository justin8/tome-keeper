# Tome Keeper

A skill for managing ebook libraries using Calibre's metadata capabilities.

## Overview

The Tome Keeper skill helps AI agents organize, search, and maintain ebook collections. It wraps Calibre's `ebook-meta` command-line tool through simple shell scripts that output JSON, making it easy for agents to read and write ebook metadata.

**Supported Formats:** EPUB, MOBI, AZW, AZW3, M4B (Organization only)

## Features

- Read and write ebook metadata (title, authors, series, ISBN, description, etc.)
- Find books and audiobooks in your library using glob patterns
- Organize library with the default structure: `{Author}/{Series/}{Title} ({Year})/{Title} ({Year}).{ext}`
- Store `.m4b` audiobooks and covers alongside ebooks in the same folder
- Clean up and enrich metadata using web searches
- Move and delete book files safely
- Platform-aware (macOS and Linux)

## Prerequisites

Before using this power, you need to install two external dependencies:

### 1. Calibre

Calibre provides the `ebook-meta` command-line tool for reading and writing ebook metadata.

### 2. jq

jq is a command-line JSON processor used by the shell scripts.

## Installation

### For Kiro

Install this skill by cloning it into your skills directory:

```bash
git clone https://github.com/justin8/tome-keeper.git ~/.kiro/skills/tome-keeper
```

### For Claude Code

Install this skill by cloning it into your skills directory:

```bash
git clone https://github.com/justin8/tome-keeper.git ~/.claude/skills/tome-keeper
```

Then install the prerequisites (Calibre and jq) as described above. The skill will be automatically available.

## Documentation

For complete documentation on available tools, workflows, and best practices, see [SKILL.md](SKILL.md).

## Project Structure

```
tome-keeper/
├── SKILL.md                    # Complete skill documentation
├── README.md                   # This file
├── scripts/                    # Shell scripts for ebook operations
│   ├── common.sh              # Shared utilities and platform detection
│   ├── check-calibre.sh       # Verify Calibre installation
│   ├── read-metadata.sh       # Read ebook metadata
│   └── write-metadata.sh      # Write ebook metadata
└── tests/                      # Comprehensive test suite
```

## Testing

This skill includes a comprehensive test suite to verify all functionality works correctly. Run them with:

```bash
./tests/run-tests.sh
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See package.json for details.
