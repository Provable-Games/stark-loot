# Review workflow scripts

Shared by `claude-review.yml` and `codex-review.yml`, which both run the same
prompt (`.github/prompts/review.md`) over the whole PR diff and post one
new comment per completed review. Reruns also create a new comment; previous
reviews remain in the PR timeline. Every comment links to the reviewed head
commit and the workflow run attempt. Clean reviews still say `lgtm`.

- `build-review-prompt.sh` — combines the prompt with the PR's number, title,
  body, changed files, and diff command.
- `extract-claude-review.sh` — pulls the review text out of the Claude action's
  `execution_file` JSON transcript.
- `post-pr-comment.sh` — creates a comment from a body file without looking up
  or modifying earlier comments. Runtime failures still post diagnostics, while
  cancelled runs and runs without credentials do not post.

## Secrets

`claude-review.yml` needs `CLAUDE_CODE_OAUTH_TOKEN`; `codex-review.yml` needs
`CODEX_AUTH_DOT_JSON`. When one is absent — including on every fork PR, which
gets no secrets — that workflow's steps skip with a notice instead of failing.

Claude's review is also skipped by the action itself on any PR that edits a
workflow file, which must match the default branch before the action will run.

## Shared dependency caches

`warm-review-caches.yml` populates the review dependency caches on pushes to
`main`, daily at 05:23 UTC, and manual runs on the default branch. It only
downloads packages; it does not run reviews or require review credentials.
Existing cache entries skip the downloads. Both PR review workflows use
restore-only caches so different PRs reuse default-branch entries without
creating duplicate PR-scoped caches.

Keep the warmer's cache keys, paths, and Node version aligned with the review
workflows. The warmer reads the Codex package spec and pinned Claude action
revision from those workflows, and the Bun version from the pinned action.
A cache miss still allows the review to install dependencies normally. A new
Codex release can cause misses until the next warmer run; use a manual run on
the default branch to populate it sooner.
