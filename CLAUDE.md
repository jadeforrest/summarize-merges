# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a single bash script (`summarize-merges.sh`) that analyzes merge commit activity across multiple Git repositories in subdirectories. The script scans all subdirectories for Git repositories, pulls the latest changes, and generates statistics about merge commits by author over a specified time period.

## Usage

### Running the Script
```bash
./summarize-merges.sh
```

The script is executable and requires no arguments. It will:
1. Scan all subdirectories for Git repositories
2. Pull latest changes from each repository
3. Collect merge commit data from the past month
4. Generate summary statistics by author

### Configuration
The time period can be modified by changing the `SINCE` variable at the top of the script:
```bash
SINCE="1 month ago"  # Can be changed to "2 weeks ago", "3 months ago", etc.
```

## Architecture

The script operates in a simple linear fashion:
1. **Discovery Phase**: Loops through all subdirectories looking for `.git` directories
2. **Data Collection Phase**: For each Git repository, pulls updates and extracts merge commit author names
3. **Analysis Phase**: Aggregates data using standard Unix tools (sort, uniq, wc) to generate statistics
4. **Output Phase**: Displays ranked list of contributors and summary statistics

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