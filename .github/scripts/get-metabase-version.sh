#!/usr/bin/env bash
set -euo pipefail

# Get Metabase version from values.yaml (single source of truth; Chart.yaml is populated by helm package)
values_version="$(yq '.metabase.metabaseImage.tag' charts/nr-metabase/values.yaml)"

if [ "$values_version" = "null" ] || [ -z "$values_version" ]; then
  echo "❌ ERROR: Failed to extract metabase.metabaseImage.tag from values.yaml" >&2
  exit 1
fi

if [[ "$values_version" != v* ]]; then
  echo "❌ ERROR: metabase.metabaseImage.tag ($values_version) must start with 'v'" >&2
  exit 1
fi

printf '%s\n' "$values_version"
