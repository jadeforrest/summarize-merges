# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a single bash script (`summarize-merges.sh`) that analyzes merge commit activity and overall commit patterns across multiple Git repositories in subdirectories. The script scans all subdirectories for Git repositories, pulls the latest changes, and generates statistics about merge commits by author and commit-to-merge ratios over a specified time period.

## Usage

### Running the Script
```bash
./summarize-merges.sh           # Basic usage
./summarize-merges.sh -v        # Verbose mode
./summarize-merges.sh --verbose # Verbose mode (alternative)
```

The script is executable and supports an optional verbose flag. It will:
1. Scan all subdirectories for Git repositories
2. Pull latest changes from each repository
3. Collect merge commit and total commit data from the past month
4. Generate summary statistics by author and commit-to-merge ratios

In verbose mode (`-v` or `--verbose`), the script displays merge commit counts and total commit counts for each directory as it processes them, helping verify that data is being collected correctly.

### Configuration
The time period can be modified by changing the `SINCE` variable at the top of the script:
```bash
SINCE="1 month ago"  # Can be changed to "2 weeks ago", "3 months ago", etc.
```

### Author Aliases
The script supports author name normalization through an optional `git-author-aliases.txt` file. This file should contain comma-separated pairs of alias and canonical names, one per line:
```
jeremy,Jeremy Smith
j.smith,Jeremy Smith
jdoe,John Doe
```

If the file exists, the script will replace all occurrences of the alias names with their canonical equivalents before generating statistics. If the file doesn't exist, the script continues without errors.

## Architecture

The script operates in a simple linear fashion:
1. **Discovery Phase**: Loops through all subdirectories looking for `.git` directories
2. **Data Collection Phase**: For each Git repository, pulls updates and extracts merge commit author names and total commit counts
3. **Analysis Phase**: Aggregates data using standard Unix tools (sort, uniq, wc, awk) to generate statistics
4. **Output Phase**: Displays ranked list of contributors, summary statistics, and commit-to-merge ratios

## Dependencies

The script relies on standard Unix tools that should be available on most systems:
- `git` (for repository operations)
- `bash` (shell interpreter)
- `sort`, `uniq`, `wc`, `awk` (for data processing)
- `mktemp` (for temporary file creation)

## Expected Environment

The script is designed to be run from a parent directory containing multiple Git repository subdirectories. It expects:
- Each subdirectory to contain a `.git` directory if it's a Git repository
- Git repositories to have configured remotes for the `git pull` operation
- Sufficient permissions to read Git history and create temporary files