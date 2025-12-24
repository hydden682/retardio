#!/bin/bash

# Retardio Rebranding Script
# This script renames all Retardio references to Retardio throughout the codebase

set -e

echo "╔══════════════════════════════════════════════════════╗"
echo "║       Rebranding Retardio → Retardio                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter
FILES_CHANGED=0

# Function to replace in files
replace_in_files() {
    local pattern=$1
    local replacement=$2
    local file_pattern=$3

    echo -e "${YELLOW}Replacing '$pattern' → '$replacement' in $file_pattern files...${NC}"

    # Find and replace, excluding .git and build directories
    find . -type f \
        -name "$file_pattern" \
        ! -path "./.git/*" \
        ! -path "./build/*" \
        -exec grep -l "$pattern" {} \; 2>/dev/null | while read file; do

        # Use sed to replace (portable across Linux/Mac)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/$pattern/$replacement/g" "$file"
        else
            # Linux
            sed -i "s/$pattern/$replacement/g" "$file"
        fi

        FILES_CHANGED=$((FILES_CHANGED + 1))
        echo "  ✓ $file"
    done
}

# Function to rename files
rename_files() {
    local old_name=$1
    local new_name=$2

    echo -e "${YELLOW}Renaming files: $old_name → $new_name${NC}"

    find . -type f \
        -name "*$old_name*" \
        ! -path "./.git/*" \
        ! -path "./build/*" 2>/dev/null | while read file; do

        new_file=$(echo "$file" | sed "s/$old_name/$new_name/g")
        mv "$file" "$new_file"
        echo "  ✓ $file → $new_file"
    done
}

echo "Step 1: Replacing text in source files (.cpp, .h)..."
echo "=================================================="

# Replace in C++ source files
for ext in "*.cpp" "*.h" "*.c"; do
    # Retardio Core → Retardio
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/Retardio Core/Retardio/g' {} \; 2>/dev/null || true

    # Retardio Knots → Retardio
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/Retardio Knots/Retardio/g' {} \; 2>/dev/null || true

    # retardio (lowercase) → retardio
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<retardio\>/retardio/g' {} \; 2>/dev/null || true

    # Retardio (capitalized) → Retardio
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<Retardio\>/Retardio/g' {} \; 2>/dev/null || true

    # RETARDIO (uppercase) → RETARDIO
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<RETARDIO\>/RETARDIO/g' {} \; 2>/dev/null || true
done

echo "✓ Source files updated"
echo ""

echo "Step 2: Replacing text in CMake files..."
echo "=========================================="

# Replace in CMake files
for ext in "CMakeLists.txt" "*.cmake"; do
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/BitcoinCore/RetardioCore/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/Retardio Knots/Retardio/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/Retardio Core/Retardio/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<retardio\>/retardio/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<Retardio\>/Retardio/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/RETARDIO/RETARDIO/g' {} \; 2>/dev/null || true
done

echo "✓ CMake files updated"
echo ""

echo "Step 3: Replacing text in scripts (.sh, .bat)..."
echo "=================================================="

# Replace in shell scripts
for ext in "*.sh" "*.bat"; do
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<retardio\>/retardio/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<Retardio\>/Retardio/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/RETARDIO/RETARDIO/g' {} \; 2>/dev/null || true
done

echo "✓ Script files updated"
echo ""

echo "Step 4: Replacing text in documentation (.md)..."
echo "=================================================="

# Replace in markdown files (but preserve some Retardio references in historical context)
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/Retardio Knots/Retardio/g' {} \; 2>/dev/null || true
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/Retardio Core/Retardio/g' {} \; 2>/dev/null || true
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/retardio-cli/retardio-cli/g' {} \; 2>/dev/null || true
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/retardiod/retardiod/g' {} \; 2>/dev/null || true
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/retardio-qt/retardio-qt/g' {} \; 2>/dev/null || true
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/retardio-tx/retardio-tx/g' {} \; 2>/dev/null || true
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/retardio-util/retardio-util/g' {} \; 2>/dev/null || true
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/retardio-wallet/retardio-wallet/g' {} \; 2>/dev/null || true
find . -type f -name "*.md" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\.retardio/\.retardio/g' {} \; 2>/dev/null || true

echo "✓ Documentation updated"
echo ""

echo "Step 5: Replacing text in config files (.conf, .service, .in)..."
echo "=================================================================="

# Replace in config files
for ext in "*.conf" "*.service" "*.in"; do
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<retardio\>/retardio/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/\<Retardio\>/Retardio/g' {} \; 2>/dev/null || true
    find . -type f -name "$ext" ! -path "./.git/*" ! -path "./build/*" -exec sed -i 's/RETARDIO/RETARDIO/g' {} \; 2>/dev/null || true
done

echo "✓ Config files updated"
echo ""

echo "Step 6: Special replacements for binary and directory names..."
echo "================================================================"

# Replace specific patterns that might have been missed
find . -type f \
    \( -name "*.cpp" -o -name "*.h" -o -name "*.sh" -o -name "*.bat" -o -name "CMakeLists.txt" -o -name "*.cmake" \) \
    ! -path "./.git/*" ! -path "./build/*" \
    -exec sed -i 's/retardiod/retardiod/g' {} \; 2>/dev/null || true

find . -type f \
    \( -name "*.cpp" -o -name "*.h" -o -name "*.sh" -o -name "*.bat" -o -name "CMakeLists.txt" -o -name "*.cmake" \) \
    ! -path "./.git/*" ! -path "./build/*" \
    -exec sed -i 's/retardio-cli/retardio-cli/g' {} \; 2>/dev/null || true

find . -type f \
    \( -name "*.cpp" -o -name "*.h" -o -name "*.sh" -o -name "*.bat" -o -name "CMakeLists.txt" -o -name "*.cmake" \) \
    ! -path "./.git/*" ! -path "./build/*" \
    -exec sed -i 's/retardio-qt/retardio-qt/g' {} \; 2>/dev/null || true

# Config directory
find . -type f \
    \( -name "*.cpp" -o -name "*.h" -o -name "*.sh" -o -name "*.bat" -o -name "*.md" \) \
    ! -path "./.git/*" ! -path "./build/*" \
    -exec sed -i 's/\.retardio/\.retardio/g' {} \; 2>/dev/null || true

echo "✓ Binary and directory names updated"
echo ""

echo "╔══════════════════════════════════════════════════════╗"
echo "║           ✓ REBRANDING COMPLETE! ✓                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Test build: cmake -B build && cmake --build build"
echo "3. Run tests to ensure everything works"
echo ""
echo "Note: Some references to Retardio may remain in:"
echo "  - Copyright notices (intentional - shows origin)"
echo "  - Historical documentation"
echo "  - External library names"
echo ""
