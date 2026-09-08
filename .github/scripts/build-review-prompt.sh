#!/usr/bin/env bash
set -euo pipefail

OUTPUT_FILE="${1:-/tmp/prompt.txt}"

: "${PROMPT_FILE:?PROMPT_FILE is required}"
: "${BASE_SHA:?BASE_SHA is required}"
: "${HEAD_SHA:?HEAD_SHA is required}"
: "${PR_NUMBER:?PR_NUMBER is required}"
: "${REPOSITORY:?REPOSITORY is required}"

PR_TITLE="${PR_TITLE:-}"
PR_BODY="${PR_BODY:-}"

{
  cat "$PROMPT_FILE"
  echo ""
  echo "---"
  echo ""
  echo "Review pull request #$PR_NUMBER in $REPOSITORY."
  echo ""
  echo "Read the diff with:"
  echo "  git diff $BASE_SHA...$HEAD_SHA"
  echo ""
  echo "Files changed:"
  git diff --name-only "$BASE_SHA...$HEAD_SHA" | sed 's/^/- /'
  echo ""
  echo "Pull request title: $PR_TITLE"
  echo "Pull request body:"
  echo "$PR_BODY"
} > "$OUTPUT_FILE"
