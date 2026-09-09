#!/usr/bin/env bash
set -euo pipefail

# Lightweight technology, monorepo & IaC inventory helper.
declare -a stacks=()

# Multi-level manifest scanner (root + up to 3 levels deep for monorepos)
has_file() {
  local pattern="$1"
  [[ -f "$pattern" ]] || [[ -n "$(find . -maxdepth 3 -name "$pattern" -print -quit 2>/dev/null)" ]]
}

# Monorepo workspace detection
is_monorepo="false"
if [[ -f pnpm-workspace.yaml || -f lerna.json || -f nx.json || -f turbo.json ]]; then
  is_monorepo="true"
  stacks+=("monorepo")
elif has_file "package.json"; then
  if find . -maxdepth 3 -name 'package.json' -exec grep -q '"workspaces"' {} + 2>/dev/null; then
    is_monorepo="true"
    stacks+=("monorepo")
  fi
fi

has_file "package.json" && stacks+=("node")
has_file "tsconfig.json" && stacks+=("typescript")
(has_file "requirements.txt" || has_file "pyproject.toml" || has_file "Pipfile") && stacks+=("python")
(has_file "pom.xml" || has_file "build.gradle" || has_file "build.gradle.kts") && stacks+=("java")
has_file "go.mod" && stacks+=("go")
has_file "Cargo.toml" && stacks+=("rust")
has_file "pubspec.yaml" && stacks+=("flutter")
(has_file "Podfile" || [[ -n "$(find . -maxdepth 3 -name '*.xcodeproj' -print -quit 2>/dev/null)" ]]) && stacks+=("ios")
has_file "AndroidManifest.xml" && stacks+=("android")
[[ -n "$(find . -maxdepth 3 -name '*.csproj' -print -quit 2>/dev/null)" ]] && stacks+=("csharp")

# Check for popular frontend / backend / hybrid frameworks only if package.json exists
check_in_package_json() {
  local search_term="$1"
  local files
  files="$(find . -maxdepth 3 -name 'package.json' 2>/dev/null || true)"
  if [[ -n "$files" ]]; then
    printf '%s\n' "$files" | xargs grep -q "$search_term" 2>/dev/null
  else
    return 1
  fi
}

if check_in_package_json '"next"'; then stacks+=("nextjs"); fi
if check_in_package_json '"react"'; then stacks+=("react"); fi
if check_in_package_json '"vue"'; then stacks+=("vue"); fi
if check_in_package_json '"express"'; then stacks+=("express"); fi
if check_in_package_json '"prisma"'; then stacks+=("prisma"); fi

# Deduplicate stacks array
unique_stacks=()
if [[ ${#stacks[@]} -gt 0 ]]; then
  while IFS= read -r item; do
    unique_stacks+=("$item")
  done < <(printf '%s\n' "${stacks[@]}" | sort -u)
fi

key_files="$(find . -type f \( \
  -name 'serverless.yml' -o -name 'serverless.yaml' -o \
  -name 'template.yml' -o -name 'template.yaml' -o \
  -name '*.tf' -o -name 'cdk.json' -o \
  -name '*.graphql' -o -name 'openapi*.yaml' -o -name 'openapi*.yml' -o -name 'openapi*.json' -o \
  -name '*.asl.json' -o -name '*.state.json' -o \
  -name 'Dockerfile' -o -name 'docker-compose*.yml' \
\) 2>/dev/null | head -50 | jq -R . | jq -s . || echo '[]')"

# Safely format stacks array as JSON
if [[ ${#unique_stacks[@]} -eq 0 ]]; then
  stacks_json="[]"
else
  stacks_json="$(printf '%s\n' "${unique_stacks[@]}" | jq -R . | jq -s .)"
fi

jq -n \
  --arg isMonorepo "$is_monorepo" \
  --argjson techStack "$stacks_json" \
  --argjson keyFiles "$key_files" \
  '{isMonorepo: ($isMonorepo == "true"), techStack: $techStack, keyFiles: $keyFiles}'
