#!/usr/bin/env bash
set -euo pipefail

# Get Metabase version from values.yaml (the actual image tag)
values_version="$(yq '.metabase.metabaseImage.tag' charts/nr-metabase/values.yaml)"

if [ "$values_version" = "null" ] || [ -z "$values_version" ]; then
  echo "❌ ERROR: Failed to extract metabase.metabaseImage.tag from values.yaml" >&2
  exit 1
fi

# Get appVersion from Chart.yaml
chart_app_version="$(yq '.appVersion' charts/nr-metabase/Chart.yaml)"

if [ "$chart_app_version" = "null" ] || [ -z "$chart_app_version" ]; then
  echo "❌ ERROR: Failed to extract appVersion from Chart.yaml" >&2
  exit 1
fi

# Normalize versions for comparison (both should have 'v' prefix)
normalized_values="${values_version#v}"  # Remove leading 'v' if present
normalized_chart="${chart_app_version#v}"  # Remove leading 'v' if present

# Check for version mismatch
if [ "$normalized_values" != "$normalized_chart" ]; then
  echo "❌ VERSION MISMATCH DETECTED:" >&2
  echo "   values.yaml (metabase.metabaseImage.tag): $values_version" >&2
  echo "   Chart.yaml (appVersion): $chart_app_version" >&2
  echo "" >&2
  echo "🔧 ACTION REQUIRED:" >&2
  echo "   Update Chart.yaml to match values.yaml:" >&2
  echo "   1. Set 'version' to: $normalized_values" >&2
  echo "   2. Set 'appVersion' to: $values_version" >&2
  exit 1
fi

printf '%s\n' "$values_version"