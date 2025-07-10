#!/bin/bash

# How far back to look
SINCE="1 month ago"

# Temporary file to accumulate results
TEMP_FILE=$(mktemp)
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
    git log --merges --since="$SINCE" --pretty="%an" >> "$TEMP_FILE"

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

echo
echo "Summary:"
echo "--------"
echo "Total merge commits:      $TOTAL_MERGES"
echo "Total unique contributors: $TOTAL_PEOPLE"

if [ "$TOTAL_PEOPLE" -gt 0 ]; then
  AVERAGE=$(awk "BEGIN { printf \"%.2f\", $TOTAL_MERGES / $TOTAL_PEOPLE }")
  echo "Average merges per person: $AVERAGE"
else
  echo "Average merges per person: N/A"
fi

# Cleanup
rm "$TEMP_FILE"
