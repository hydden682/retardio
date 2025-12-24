#!/bin/bash

# Rename all files with "bitcoin" in their name to "retardio"

set -e

echo "Renaming bitcoin-named files to retardio..."
echo ""

# Find all files with "bitcoin" in the name and rename them
find . -depth -type f -name '*bitcoin*' ! -path './.git/*' ! -path './build/*' 2>/dev/null | while read file; do
    # Get the directory and filename
    dir=$(dirname "$file")
    filename=$(basename "$file")

    # Replace bitcoin with retardio in filename
    newname=$(echo "$filename" | sed 's/bitcoin/retardio/g')

    # Only rename if the name actually changed
    if [ "$filename" != "$newname" ]; then
        newpath="$dir/$newname"
        echo "Renaming: $file -> $newpath"
        mv "$file" "$newpath"
    fi
done

echo ""
echo "✓ File renaming complete!"
