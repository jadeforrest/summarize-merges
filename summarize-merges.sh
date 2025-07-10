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
    git log --merges --since="$SINCE" --pretty="%an" > "$DIR_TEMP"
    
    # Count total commits (not just merges) in the same time period
    TOTAL_COMMITS=$(git log --since="$SINCE" --oneline | wc -l)
    echo "$TOTAL_COMMITS" >> "$COMMITS_FILE"
    
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
echo "Total merge commits:      $TOTAL_MERGES"
echo "Total commits:            $TOTAL_COMMITS"
echo "Total unique contributors: $TOTAL_PEOPLE"

if [ "$TOTAL_PEOPLE" -gt 0 ]; then
  AVERAGE_MERGES=$(awk "BEGIN { printf \"%.2f\", $TOTAL_MERGES / $TOTAL_PEOPLE }")
  echo "Average merges per person: $AVERAGE_MERGES"
else
  echo "Average merges per person: N/A"
fi

if [ "$TOTAL_MERGES" -gt 0 ]; then
  COMMITS_PER_MERGE=$(awk "BEGIN { printf \"%.2f\", $TOTAL_COMMITS / $TOTAL_MERGES }")
  echo "Average commits per merge: $COMMITS_PER_MERGE"
else
  echo "Average commits per merge: N/A"
fi

# Cleanup
rm "$TEMP_FILE" "$COMMITS_FILE"
