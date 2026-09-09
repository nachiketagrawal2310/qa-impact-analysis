#!/usr/bin/env bash
set -euo pipefail

# Check if inside a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  jq -n '{
    error: "Not a git repository",
    baseBranch: null,
    currentBranch: null,
    mergeBase: null,
    diffStat: "",
    branchDiff: "",
    stagedDiff: "",
    unstagedDiff: "",
    branchChangedFiles: [],
    stagedFiles: [],
    unstagedFiles: [],
    untrackedFiles: []
  }'
  exit 0
fi

# Dynamic base branch resolution
BASE="${1:-}"
if [[ -z "$BASE" ]]; then
  # 1. Try remote origin HEAD
  BASE="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)"
  # 2. Try local or remote main/master
  if [[ -z "$BASE" ]]; then
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
      BASE="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
      BASE="master"
    elif git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
      BASE="origin/main"
    elif git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
      BASE="origin/master"
    else
      BASE="HEAD"
    fi
  fi
fi

MERGE_BASE=""
if [[ "$BASE" != "HEAD" ]]; then
  MERGE_BASE="$(git merge-base HEAD "$BASE" 2>/dev/null || true)"
fi
BRANCH="$(git branch --show-current 2>/dev/null || true)"

# Safely convert newline-separated list to JSON array
lines_to_json_array() {
  local input
  input="$(cat)"
  if [[ -z "${input//[$'\t\r\n ']/}" ]]; then
    echo "[]"
  else
    printf '%s\n' "$input" | sed '/^[[:space:]]*$/d' | jq -R . | jq -s .
  fi
}

# Limit large diffs to avoid memory / arg-length blowups (12,000 characters max per diff field)
truncate_diff() {
  local content="$1"
  local max_chars=12000
  if (( ${#content} > max_chars )); then
    echo "${content:0:max_chars}"$'\n\n[... Diff truncated: exceeds 12KB. Use targeted file diffs for details ...]'
  else
    echo "$content"
  fi
}

raw_branch_diff=""
diff_stat=""
changed_branch="[]"
if [[ -n "$MERGE_BASE" ]]; then
  raw_branch_diff="$(git diff "$MERGE_BASE"...HEAD 2>/dev/null || true)"
  diff_stat="$(git diff --stat "$MERGE_BASE"...HEAD 2>/dev/null || true)"
  changed_branch="$( (git diff --name-only "$MERGE_BASE"...HEAD 2>/dev/null || true) | lines_to_json_array)"
fi

raw_staged="$(git diff --cached -- 2>/dev/null || true)"
raw_unstaged="$(git diff -- 2>/dev/null || true)"

staged_files="$( (git diff --cached --name-only 2>/dev/null || true) | lines_to_json_array)"
unstaged_files="$( (git diff --name-only 2>/dev/null || true) | lines_to_json_array)"
untracked="$( (git ls-files --others --exclude-standard 2>/dev/null || true) | lines_to_json_array)"

branch_diff="$(truncate_diff "$raw_branch_diff")"
staged_diff="$(truncate_diff "$raw_staged")"
unstaged_diff="$(truncate_diff "$raw_unstaged")"

jq -n \
  --arg base "$BASE" \
  --arg branch "$BRANCH" \
  --arg mergeBase "$MERGE_BASE" \
  --arg diffStat "$diff_stat" \
  --arg branchDiff "$branch_diff" \
  --arg stagedDiff "$staged_diff" \
  --arg unstagedDiff "$unstaged_diff" \
  --argjson branchChangedFiles "$changed_branch" \
  --argjson stagedFiles "$staged_files" \
  --argjson unstagedFiles "$unstaged_files" \
  --argjson untrackedFiles "$untracked" \
  '{
    baseBranch: $base,
    currentBranch: $branch,
    mergeBase: $mergeBase,
    diffStat: $diffStat,
    branchDiff: $branchDiff,
    stagedDiff: $stagedDiff,
    unstagedDiff: $unstagedDiff,
    branchChangedFiles: $branchChangedFiles,
    stagedFiles: $stagedFiles,
    unstagedFiles: $unstagedFiles,
    untrackedFiles: $untrackedFiles
  }'
