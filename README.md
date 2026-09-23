# Tome Keeper

A skill for managing ebook libraries using Calibre's metadata capabilities.

## Overview

The Tome Keeper skill helps AI agents organize, search, and maintain ebook collections. It wraps Calibre's `ebook-meta` command-line tool through simple shell scripts that output JSON, making it easy for agents to read and write ebook metadata.

**Supported Formats:** EPUB, MOBI, AZW, AZW3, M4B (Organization only)

## Features

- Read and write ebook metadata (title, authors, series, ISBN, description, etc.)
- Query rich metadata, series reading order, tags, and covers from [Hardcover](https://hardcover.app) API
- Find books and audiobooks in your library using glob patterns
- Organize library with the default structure: `{Author}/{Series/}{Title} ({Year})/{Title} ({Year}) - {Author}.{ext}`
- Store `.m4b` audiobooks and covers alongside ebooks in the same folder
- Clean up and enrich metadata using Hardcover or web searches
- Move and delete book files safely
- Platform-aware (macOS and Linux)

## Prerequisites

- **Calibre**: Provides the `ebook-meta` command-line tool for reading and writing ebook metadata.
- **jq**: Command-line JSON processor used by the shell scripts.
- **curl**: Used for querying online book metadata APIs.

## Configuration (Optional)

### Hardcover API Token

Tome Keeper supports searching and enriching metadata from [Hardcover](https://hardcover.app) via their GraphQL API.

1. Get a personal access token at [https://hardcover.app/account/api](https://hardcover.app/account/api).
2. Configure it in any of the following ways (checked in priority order):
   - **Environment Variable**: `export HARDCOVER_API_KEY="your_token"`
   - **User Config**: Save to `~/.config/tome-keeper/credentials`:
     ```bash
     mkdir -p ~/.config/tome-keeper
     echo "HARDCOVER_API_KEY=your_token" > ~/.config/tome-keeper/credentials
     ```
   - **Local `.env`**: Copy `.env.example` to `.env` and fill in `HARDCOVER_API_KEY`.
   - **CLI Flag**: Pass `--api-key "your_token"` to `fetch-hardcover.sh`.

## Installation

### For Antigravity

Install this skill by cloning it into your global skills directory:

```bash
git clone https://github.com/justin8/tome-keeper.git ~/.gemini/config/skills/tome-keeper
```

Or for a specific project/workspace:

```bash
git clone https://github.com/justin8/tome-keeper.git .agents/skills/tome-keeper
```

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
├── .env.example                # Example configuration template
├── scripts/                    # Shell scripts for ebook operations
│   ├── common.sh              # Shared utilities and platform detection
│   ├── check-calibre.sh       # Verify Calibre installation
│   ├── read-metadata.sh       # Read ebook metadata
│   ├── write-metadata.sh      # Write ebook metadata
│   └── fetch-hardcover.sh     # Fetch metadata from Hardcover API
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
