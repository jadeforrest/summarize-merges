# Git Merge Analysis Tool

This is a bash script that analyzes merge commit activity and commit patterns across multiple Git repositories, providing insights into team productivity and development cycle times.

## Overview

This tool scans all subdirectories for Git repositories, pulls the latest changes, and generates comprehensive statistics about merge commits (PRs), commit-to-merge ratios, and cycle times over a specified time period.

## Prerequisites

### System Requirements
- Unix-like operating system (macOS, Linux, WSL)
- Bash shell (version 4.0 or later recommended)

### Dependencies
The script uses standard Unix tools that should be available on most systems:
- `git` - For repository operations
- `bash` - Shell interpreter
- `sort`, `uniq`, `wc`, `awk` - For data processing and statistics
- `mktemp` - For temporary file creation
- `sed` - For text processing (author aliases)

### Environment Setup

1. **Directory Structure**: Run the script from a parent directory containing multiple Git repository subdirectories:
   ```
   parent-directory/
   ├── repo1/
   │   └── .git/
   ├── repo2/
   │   └── .git/
   ├── repo3/
   │   └── .git/
   └── summarize-merges.sh
   ```

2. **Git Configuration**: Each repository should have:
   - Configured remotes for the `git pull` operation
   - Readable Git history
   - Sufficient permissions for the script to access

3. **Script Permissions**: Make the script executable:
   ```bash
   chmod +x summarize-merges.sh
   ```

## Usage

### Basic Usage
```bash
./summarize-merges.sh
```

### Verbose Mode
```bash
./summarize-merges.sh -v
# or
./summarize-merges.sh --verbose
```

In verbose mode, the script displays:
- Merge commit counts for each repository as it processes them
- Total commit counts per repository
- Detailed author statistics before the final summary

### Command Line Options

| Option | Description |
|--------|-------------|
| `-v`, `--verbose` | Enable verbose output showing per-repository statistics |

## Configuration

### Time Period
Modify the analysis time period by editing the `SINCE` variable at the top of the script:

```bash
SINCE="1 month ago"    # Default
SINCE="2 weeks ago"    # Last 2 weeks
SINCE="3 months ago"   # Last 3 months
SINCE="2023-01-01"     # Since specific date
```

### Author Aliases
Create an optional `git-author-aliases.txt` file in the same directory to normalize author names:

```
jeremy,Jeremy Smith
j.smith,Jeremy Smith
jdoe,John Doe
john.doe@company.com,John Doe
```

Format: `alias,canonical_name` (one per line)

If the file doesn't exist, the script continues without errors.

## Output

The script generates:

1. **Processing Status**: Shows which repositories are being analyzed
2. **Merge Commit Counts**: Ranked list of contributors by merge commits
3. **Summary Statistics**:
   - Total merge commits
   - Total commits
   - Total unique contributors
   - Average merges per person
   - Average commits per merge
   - Average and median cycle times (in days and hours)

### Sample Output
```
Scanning subdirectories and collecting merge commit data...
Processing repo1/
Processing repo2/
Processing repo3/

Merge commit counts by author (past month):
------------------------------------------

Summary:
--------
Total merge commits:        45
Total commits:             180
Total unique contributors:   8
Average merges per person: 5.63
Average commits per merge: 4.00
Average cycle time:        2.3 days (55.2 hours)
Median cycle time:         1.8 days (43.2 hours)
```

## Features

### Cycle Time Analysis
The script calculates development cycle times by measuring the time between:
- The oldest commit in a merged branch
- The merge commit timestamp

This provides insights into how long features typically take from start to merge.

### Multi-Repository Support
Automatically discovers and processes all Git repositories in subdirectories, making it ideal for:
- Monorepo setups with multiple projects
- Development environments with multiple related repositories
- Organization-wide analysis across project portfolios

### Author Normalization
The alias system handles common scenarios:
- Different email addresses for the same person
- Nickname variations
- Corporate email changes
- Contractor vs. employee accounts

## Troubleshooting

### Common Issues

**Script reports "No merge commits found" for repositories with merges**
- Ensure the time period (`SINCE` variable) covers the period you want to analyze
- Check that the repository has merge commits (not just regular commits)
- Verify git log permissions and repository access

**"Permission denied" errors**
- Make the script executable: `chmod +x summarize-merges.sh`
- Check file system permissions for the parent directory and subdirectories

**Git pull failures**
- Ensure each repository has a configured remote
- Check network connectivity and authentication
- Verify you have permission to pull from the remote repositories

**Incomplete or missing data**
- Run in verbose mode (`-v`) to see per-repository processing details
- Check that subdirectories actually contain `.git` directories
- Verify the `SINCE` date format is valid for your version of git

**Author aliases not working**
- Ensure `git-author-aliases.txt` uses the exact format: `alias,canonical_name`
- Check for extra spaces or special characters in the aliases file
- Verify the file is in the same directory as the script

### Debugging Tips

1. **Test with a single repository**: Move the script into a single repository directory temporarily to isolate issues

2. **Check git log output**: Run git commands manually to verify expected data:
   ```bash
   git log --all --merges --since="1 month ago" --pretty="%an"
   ```

3. **Verify date formats**: Test different date formats if the default doesn't work:
   ```bash
   git log --since="2023-01-01"
   git log --since="last week"
   ```

4. **Check permissions**: Ensure read access to all `.git` directories:
   ```bash
   find . -name ".git" -type d -exec ls -la {} \;
   ```

## Contributing

When modifying the script:
- Test with various repository configurations
- Ensure backward compatibility with existing alias files
- Add appropriate error handling for edge cases
- Update this documentation for any new features or options

## License

See the LICENSE file for details.