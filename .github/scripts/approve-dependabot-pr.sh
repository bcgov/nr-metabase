#!/usr/bin/env bash
set -euo pipefail

pr_url="${1:?pull request url is required}"

if [ "$(gh pr view "$pr_url" --json reviewDecision --jq .reviewDecision)" != "APPROVED" ]; then
  gh pr review --approve "$pr_url"
else
  echo "PR already approved."
fi