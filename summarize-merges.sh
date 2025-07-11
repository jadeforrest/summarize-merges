#!/bin/bash

# How far back to look
SINCE="1 month ago"

# Parse command line arguments
VERBOSE=false
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
  VERBOSE=true
fi

# Temporary files to accumulate results
TEMP_FILE=$(mktemp)
COMMITS_FILE=$(mktemp)
CYCLE_TIMES_FILE=$(mktemp)
ALIASES_FILE="git-author-aliases.txt"

echo "Scanning subdirectories and collecting merge commit data..."

# Loop over all subdirectories
for dir in */; do
  if [ -d "$dir/.git" ]; then
    echo "Processing $dir"
    cd "$dir" || continue

    # Pull the latest changes
    git pull > /dev/null

    # Collect author names for merge commits since given date
    DIR_TEMP=$(mktemp)
    git log --all --merges --since="$SINCE" --pretty="%an" > "$DIR_TEMP"
    
    # Count total commits (not just merges) in the same time period
    TOTAL_COMMITS=$(git log --all --since="$SINCE" --oneline | wc -l)
    echo "$TOTAL_COMMITS" >> "$COMMITS_FILE"
    
    # Collect cycle times for merge commits
    git log --all --merges --since="$SINCE" --pretty="%H %ct" | while read -r merge_hash merge_time; do
      if [ -n "$merge_hash" ]; then
        # Get the oldest commit in the merged branch
        oldest_commit_time=$(git log --reverse --pretty="%ct" "${merge_hash}^1..${merge_hash}^2" 2>/dev/null | head -1)
        if [ -n "$oldest_commit_time" ] && [ "$oldest_commit_time" -lt "$merge_time" ]; then
          cycle_time=$((merge_time - oldest_commit_time))
          echo "$cycle_time" >> "$CYCLE_TIMES_FILE"
        fi
      fi
    done
    
    if [ "$VERBOSE" = true ]; then
      MERGE_COUNT=$(wc -l < "$DIR_TEMP")
      if [ "$MERGE_COUNT" -gt 0 ]; then
        echo "  Found $MERGE_COUNT merge commits, $TOTAL_COMMITS total commits:"
        sort "$DIR_TEMP" | uniq -c | sort -nr | sed 's/^/    /'
      else
        echo "  No merge commits found, $TOTAL_COMMITS total commits"
      fi
    fi
    
    # Add to main temp file
    cat "$DIR_TEMP" >> "$TEMP_FILE"
    rm "$DIR_TEMP"

    cd - > /dev/null
  fi
done

echo
echo "Merge commit counts by author (past month):"
echo "------------------------------------------"

# Apply aliases if file exists
if [ -f "$ALIASES_FILE" ]; then
  echo "Applying author aliases from $ALIASES_FILE..."
  
  # Process each line in the aliases file
  while IFS=',' read -r alias canonical; do
    # Skip empty lines and lines without comma
    if [ -z "$alias" ] || [ -z "$canonical" ]; then
      continue
    fi
    # Replace alias with canonical name in temp file
    sed -i.bak "s/^$alias$/$canonical/g" "$TEMP_FILE"
  done < "$ALIASES_FILE"
  
  # Clean up backup file created by sed
  rm -f "$TEMP_FILE.bak"
fi

# Summarize and print
sort "$TEMP_FILE" | uniq -c | sort -nr

# Compute totals
TOTAL_MERGES=$(wc -l < "$TEMP_FILE")
TOTAL_PEOPLE=$(sort "$TEMP_FILE" | uniq | wc -l)
TOTAL_COMMITS=$(awk '{sum += $1} END {print sum}' "$COMMITS_FILE")

echo
echo "Summary:"
echo "--------"
printf "Total merge commits:      %3d\n" "$TOTAL_MERGES"
printf "Total commits:            %3d\n" "$TOTAL_COMMITS"
printf "Total unique contributors: %3d\n" "$TOTAL_PEOPLE"

if [ "$TOTAL_PEOPLE" -gt 0 ]; then
  AVERAGE_MERGES=$(awk "BEGIN { printf \"%.2f\", $TOTAL_MERGES / $TOTAL_PEOPLE }")
  printf "Average merges per person: %4.2f\n" "$AVERAGE_MERGES"
else
  printf "Average merges per person: %4s\n" "N/A"
fi

if [ "$TOTAL_MERGES" -gt 0 ]; then
  COMMITS_PER_MERGE=$(awk "BEGIN { printf \"%.2f\", $TOTAL_COMMITS / $TOTAL_MERGES }")
  printf "Average commits per merge: %4.2f\n" "$COMMITS_PER_MERGE"
else
  printf "Average commits per merge: %4s\n" "N/A"
fi

# Calculate cycle time statistics
if [ -s "$CYCLE_TIMES_FILE" ]; then
  CYCLE_COUNT=$(wc -l < "$CYCLE_TIMES_FILE")
  if [ "$CYCLE_COUNT" -gt 0 ]; then
    # Average cycle time in seconds
    AVERAGE_CYCLE_SECONDS=$(awk '{sum += $1} END {print sum / NR}' "$CYCLE_TIMES_FILE")
    
    # Convert to days and hours
    AVERAGE_CYCLE_DAYS=$(awk "BEGIN { printf \"%.1f\", $AVERAGE_CYCLE_SECONDS / 86400 }")
    AVERAGE_CYCLE_HOURS=$(awk "BEGIN { printf \"%.1f\", $AVERAGE_CYCLE_SECONDS / 3600 }")
    
    # Median cycle time
    MEDIAN_CYCLE_SECONDS=$(sort -n "$CYCLE_TIMES_FILE" | awk '{a[NR]=$1} END {print (NR%2==1)?a[int(NR/2)+1]:(a[NR/2]+a[NR/2+1])/2}')
    MEDIAN_CYCLE_DAYS=$(awk "BEGIN { printf \"%.1f\", $MEDIAN_CYCLE_SECONDS / 86400 }")
    MEDIAN_CYCLE_HOURS=$(awk "BEGIN { printf \"%.1f\", $MEDIAN_CYCLE_SECONDS / 3600 }")
    
    printf "Average cycle time:       %4.1f days (%5.1f hours)\n" "$AVERAGE_CYCLE_DAYS" "$AVERAGE_CYCLE_HOURS"
    printf "Median cycle time:        %4.1f days (%5.1f hours)\n" "$MEDIAN_CYCLE_DAYS" "$MEDIAN_CYCLE_HOURS"
  else
    printf "Average cycle time:       %s\n" "N/A"
  fi
else
  printf "Average cycle time:       %s\n" "N/A (no cycle time data collected)"
fi

# Cleanup
rm "$TEMP_FILE" "$COMMITS_FILE" "$CYCLE_TIMES_FILE"
