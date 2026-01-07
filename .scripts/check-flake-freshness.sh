#!/usr/bin/env bash
# Check if flake.lock is older than 7 days

LOCK="flake.lock"

if [[ ! -f "$LOCK" ]]; then
    exit 0
fi

if [[ "$(uname)" == "Darwin" ]]; then
    AGE=$(( ($(date +%s) - $(/usr/bin/stat -f "%m" "$LOCK")) / 86400 ))
else
    AGE=$(( ($(date +%s) - $(stat -c %Y "$LOCK")) / 86400 ))
fi

if [[ $AGE -gt 7 ]]; then
    echo "flake.lock is $AGE days old. Run: just update"
fi

exit 0
