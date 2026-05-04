#!/usr/bin/env bash
#
# Adds a new Envoy Gateway CRD version to the envoy-gateway module.
#
# Usage:
#   ./update-envoy-crds.sh <version>   # e.g. ./update-envoy-crds.sh v1.8.0
#
# What it does:
#   1. Renders gateway-crds-helm at the given version (envoyGateway CRDs only)
#   2. Saves the rendered YAML to crds/envoy-crds-<version>.yaml
#   3. Updates the default in variables.tf
#   4. Updates the example and inputs table in README.md
#
# Note: this script no longer maintains a list of manifest keys. The module
# parses the YAML in pure HCL at plan time (see main.tf) and derives keys
# from `<kind>/<metadata.name>`. New CRDs in a version bump appear
# automatically as new for_each entries; removed CRDs disappear cleanly.
#
# Requirements: helm
set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
MODULE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CRD_FILE="${MODULE_DIR}/crds/envoy-crds-${VERSION}.yaml"
VARIABLES_FILE="${MODULE_DIR}/variables.tf"
README_FILE="${MODULE_DIR}/README.md"

mkdir -p "${MODULE_DIR}/crds"

# ── 1. Render ────────────────────────────────────────────────────────────────
if [[ -f "$CRD_FILE" ]]; then
  echo "File already exists: ${CRD_FILE}"
  echo "Version ${VERSION} is already present — nothing to do."
  exit 0
fi

CHART="oci://registry-1.docker.io/envoyproxy/gateway-crds-helm"
echo "Rendering ${CHART} version ${VERSION} …"

helm template eg-crds "$CHART" \
  --version "${VERSION}" \
  --set crds.gatewayAPI.enabled=false \
  --set crds.envoyGateway.enabled=true \
  > "$CRD_FILE"

if [[ ! -s "$CRD_FILE" ]]; then
  echo "ERROR: helm template produced no output for ${VERSION}" >&2
  rm -f "$CRD_FILE"
  exit 1
fi

# ── 2. Update variables.tf default ──────────────────────────────────────────
sed -i.bak -E "s/(default[[:space:]]*=[[:space:]]*)\"v[0-9]+\.[0-9]+\.[0-9]+\"/\1\"${VERSION}\"/" "$VARIABLES_FILE"
rm -f "${VARIABLES_FILE}.bak"
echo "Updated ${VARIABLES_FILE}"

# ── 3. Update README.md ─────────────────────────────────────────────────────
# Update the chart_version in the usage example and the inputs table.
# Capture the alignment whitespace via -E and a backreference so we don't
# collapse it.
sed -i.bak -E "s/(chart_version[[:space:]]*=[[:space:]]*)\"v[0-9]+\.[0-9]+\.[0-9]+\"/\1\"${VERSION}\"/" "$README_FILE"
sed -i.bak -E "s/\`\"v[0-9]+\.[0-9]+\.[0-9]+\"\`/\`\"${VERSION}\"\`/" "$README_FILE"
rm -f "${README_FILE}.bak"
echo "Updated ${README_FILE}"

echo ""
echo "Done. Envoy Gateway CRDs version ${VERSION} has been added to the envoy-gateway module."
echo "Don't forget to commit the changes."
