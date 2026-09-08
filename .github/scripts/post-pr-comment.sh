#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-}"
PR_NUMBER="${2:-}"
BODY_FILE="${3:-}"

if [ -z "$REPO" ] || [ -z "$PR_NUMBER" ] || [ -z "$BODY_FILE" ]; then
  echo "usage: $0 <repo> <pr-number> <body-file>" >&2
  exit 1
fi

if [ ! -f "$BODY_FILE" ]; then
  echo "body file not found: $BODY_FILE" >&2
  exit 1
fi

# Keep each review in the PR timeline, including reruns of the same commit.
gh pr comment "$PR_NUMBER" --repo "$REPO" --body-file "$BODY_FILE" > /dev/null
