#!/usr/bin/env bash
set -euo pipefail

app_version="$(yq '.metabase.metabaseImage.tag' charts/nr-metabase/values.yaml)"

if [ "$app_version" = "null" ]; then
  app_version=""
fi

printf '%s\n' "$app_version"