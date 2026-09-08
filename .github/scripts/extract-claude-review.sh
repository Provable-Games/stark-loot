#!/usr/bin/env bash
set -euo pipefail

EXECUTION_FILE="${1:-}"
OUTPUT_FILE="${2:-/tmp/review.txt}"

if [ -n "$EXECUTION_FILE" ] && [ -f "$EXECUTION_FILE" ] && [ -s "$EXECUTION_FILE" ]; then
  # execution_file is a JSON transcript; extract the latest assistant-like text payload.
  jq -rs '
    def gather_text:
      if type == "string" then .
      elif type == "array" then (map(gather_text) | join("\n"))
      elif type == "object" then
        if has("text") and (.text | type == "string") then .text
        elif has("content") then (.content | gather_text)
        elif has("message") then (.message | gather_text)
        elif has("result") then (.result | gather_text)
        elif has("summary") then (.summary | gather_text)
        else "" end
      else "" end;
    [
      .. | objects
      | select(
          (.role? == "assistant")
          or (.type? == "assistant")
          or (.type? == "message")
          or (.type? == "result")
        )
      | gather_text
    ]
    | map(gsub("^\\s+|\\s+$"; ""))
    | map(select(length > 0))
    | last // empty
  ' "$EXECUTION_FILE" > "$OUTPUT_FILE" || true
fi

if [ ! -s "$OUTPUT_FILE" ]; then
  if [ -z "$EXECUTION_FILE" ]; then
    {
      echo "No review output was captured from Claude."
      echo ""
      echo "This is expected on a PR that changes the review workflow itself: the"
      echo "action requires the workflow file to match the version on the default"
      echo "branch, and skips otherwise. It runs normally once merged."
    } > "$OUTPUT_FILE"
  elif [ ! -f "$EXECUTION_FILE" ]; then
    echo "No review output was captured from Claude (execution_file path was not found)." > "$OUTPUT_FILE"
  elif [ ! -s "$EXECUTION_FILE" ]; then
    echo "No review output was captured from Claude (execution_file was empty)." > "$OUTPUT_FILE"
  else
    echo "No review output was captured from Claude (unable to parse execution_file)." > "$OUTPUT_FILE"
  fi
fi
