#!/usr/bin/env bash
# compare-translation.bash - Compare Chinese markdown files with English translations
# Usage: compare-translation.bash <original_dir> <translated_dir>

set -euo pipefail

ORIGINAL_DIR="${1:-}"
TRANSLATED_DIR="${2:-}"

if [[ -z "$ORIGINAL_DIR" ]] || [[ -z "$TRANSLATED_DIR" ]]; then
    echo "Usage: $0 <original_dir> <translated_dir>" >&2
    exit 1
fi

if [[ ! -d "$ORIGINAL_DIR" ]] || [[ ! -d "$TRANSLATED_DIR" ]]; then
    echo "Error: Both directories must exist" >&2
    exit 1
fi

# Output file
REPORT_FILE="$(mktemp -d)/translation-comparison-$(date +%Y%m%d-%H%M%S).md"

echo "# Translation Comparison Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Generated: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- Original: $ORIGINAL_DIR" >> "$REPORT_FILE"
echo "- Translation: $TRANSLATED_DIR" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Find all markdown files in original
while IFS= read -r -d '' original_file; do
    # Get relative path
    rel_path="${original_file#$ORIGINAL_DIR/}"
    translated_file="$TRANSLATED_DIR/$rel_path"

    echo "## File: $rel_path" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [[ ! -f "$translated_file" ]]; then
        echo "**STATUS: MISSING TRANSLATION**" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        continue
    fi

    # Compare file sizes
    orig_lines=$(wc -l < "$original_file")
    trans_lines=$(wc -l < "$translated_file")

    echo "- Original lines: $orig_lines" >> "$REPORT_FILE"
    echo "- Translated lines: $trans_lines" >> "$REPORT_FILE"

    # Calculate difference percentage
    if [[ $orig_lines -gt 0 ]]; then
        diff_pct=$(awk "BEGIN {printf \"%.1f\", (($trans_lines - $orig_lines) / $orig_lines) * 100}")
        echo "- Difference: ${diff_pct}%" >> "$REPORT_FILE"
    fi

    # Check for structural elements
    orig_headers=$(grep -c '^#' "$original_file" || true)
    trans_headers=$(grep -c '^#' "$translated_file" || true)

    echo "- Headers (original/translated): $orig_headers / $trans_headers" >> "$REPORT_FILE"

    # Check for code blocks
    orig_code=$(grep -c '^```' "$original_file" || true)
    trans_code=$(grep -c '^```' "$translated_file" || true)

    echo "- Code blocks (original/translated): $orig_code / $trans_code" >> "$REPORT_FILE"

    # Flag significant differences
    if [[ $orig_headers -ne $trans_headers ]] || [[ $orig_code -ne $trans_code ]]; then
        echo "" >> "$REPORT_FILE"
        echo "**WARNING: Structural differences detected**" >> "$REPORT_FILE"
    fi

    # Check line length difference (might indicate missing content)
    if [[ $orig_lines -gt 0 ]]; then
        line_diff=$(awk "BEGIN {print ($orig_lines - $trans_lines)}")
        if [[ ${line_diff#-} -gt 50 ]]; then
            echo "" >> "$REPORT_FILE"
            echo "**WARNING: Significant line count difference (${line_diff} lines)**" >> "$REPORT_FILE"
        fi
    fi

    echo "" >> "$REPORT_FILE"

done < <(find "$ORIGINAL_DIR" -name "*.md" -type f -print0 | sort -z)

# Check for extra files in translation
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Files only in translation directory" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

extra_found=false
while IFS= read -r -d '' translated_file; do
    rel_path="${translated_file#$TRANSLATED_DIR/}"
    original_file="$ORIGINAL_DIR/$rel_path"

    if [[ ! -f "$original_file" ]]; then
        echo "- $rel_path" >> "$REPORT_FILE"
        extra_found=true
    fi
done < <(find "$TRANSLATED_DIR" -name "*.md" -type f -print0 | sort -z)

if ! $extra_found; then
    echo "*None found*" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Report saved to: $REPORT_FILE" >> "$REPORT_FILE"

# Output the report location
echo ""
echo "Comparison complete!"
echo "Report saved to: $REPORT_FILE"
echo ""
cat "$REPORT_FILE"
