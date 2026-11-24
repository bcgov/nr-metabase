#!/usr/bin/env bash
set -euo pipefail

# Get Metabase version from Chart.yaml (single source of truth)
chart_version="$(yq '.version' charts/nr-metabase/Chart.yaml)"

if [ "$chart_version" = "null" ] || [ -z "$chart_version" ]; then
  echo "❌ ERROR: Failed to extract version from Chart.yaml" >&2
  exit 1
fi

chart_app_version="$(yq '.appVersion' charts/nr-metabase/Chart.yaml)"

if [ "$chart_app_version" = "null" ] || [ -z "$chart_app_version" ]; then
  echo "❌ ERROR: Failed to extract appVersion from Chart.yaml" >&2
  exit 1
fi

if [[ "$chart_app_version" != v* ]]; then
  echo "❌ ERROR: Chart.yaml appVersion ($chart_app_version) must start with 'v'" >&2
  exit 1
fi

# Verify Chart.yaml version and appVersion are aligned
normalized_version="${chart_version#v}"
normalized_app_version="${chart_app_version#v}"

if [ "$normalized_version" != "$normalized_app_version" ]; then
  echo "❌ VERSION MISMATCH DETECTED in Chart.yaml:" >&2
  echo "   version: $chart_version" >&2
  echo "   appVersion: $chart_app_version" >&2
  echo "" >&2
  echo "🔧 ACTION REQUIRED:" >&2
  echo "   Keep Chart.yaml version and appVersion aligned:" >&2
  echo "   1. Set 'version' to: $normalized_app_version" >&2
  echo "   2. Set 'appVersion' to: $chart_app_version" >&2
  exit 1
fi

printf '%s\n' "$chart_app_version"
