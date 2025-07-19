#!/bin/bash

# ===== Validate input =====
if [ $# -ne 1 ]; then
    echo "Usage: $0 /path/to/logfile.log"
    exit 1
fi

LOGFILE="$1"

if [ ! -f "$LOGFILE" ]; then
    echo "Error: File '$LOGFILE' not found."
    exit 1
fi

echo "Analyzing log file: $LOGFILE"
echo "-------------------------------------"

# ===== Count log levels =====
ERROR_COUNT=$(grep -c -i "ERROR" "$LOGFILE")
WARNING_COUNT=$(grep -c -i "WARNING" "$LOGFILE")
INFO_COUNT=$(grep -c -i "INFO" "$LOGFILE")

echo "Log Level Counts:"
echo "ERROR   : $ERROR_COUNT"
echo "WARNING : $WARNING_COUNT"
echo "INFO    : $INFO_COUNT"
echo "-------------------------------------"

# ===== Top 5 common error messages =====
echo "Top 5 Most Common Error Messages:"
grep -i "ERROR" "$LOGFILE" | awk -F'ERROR' '{print $2}' | sed 's/^[[:space:]]*//' | sort | uniq -c | sort -nr | head -5
echo "-------------------------------------"

# ===== First and Last ERROR timestamps =====
FIRST_ERROR=$(grep -i "ERROR" "$LOGFILE" | head -1)
LAST_ERROR=$(grep -i "ERROR" "$LOGFILE" | tail -1)

echo "Error Timestamp Summary:"
echo "First ERROR: $FIRST_ERROR"
echo "Last ERROR : $LAST_ERROR"
echo "-------------------------------------"

# ===== Optional: Write report to a file =====
REPORT_FILE="log_summary_report.txt"
{
    echo "Log Analysis Report"
    echo "==================="
    echo "File: $LOGFILE"
    echo "Generated: $(date)"
    echo
    echo "Log Level Counts:"
    echo "ERROR   : $ERROR_COUNT"
    echo "WARNING : $WARNING_COUNT"
    echo "INFO    : $INFO_COUNT"
    echo
    echo "Top 5 Most Common Error Messages:"
    grep -i "ERROR" "$LOGFILE" | awk -F'ERROR' '{print $2}' | sed 's/^[[:space:]]*//' | sort | uniq -c | sort -nr | head -5
    echo
    echo "First ERROR: $FIRST_ERROR"
    echo "Last ERROR : $LAST_ERROR"
} > "$REPORT_FILE"

echo "✅ Report saved to: $REPORT_FILE"
