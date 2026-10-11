#!/bin/bash

# Without jq the command cannot be read, and an empty command would match no
# pattern and be allowed. Block instead (exit 2) and name the missing need.
if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: git-guardrails needs jq to read the command and jq is not installed. Install jq (apt-get install jq, brew install jq), then retry." >&2
  exit 2
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
