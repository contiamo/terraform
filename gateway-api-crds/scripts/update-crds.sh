#!/usr/bin/env bash
#
# Adds a new Gateway API CRD version to the module.
#
# Usage:
#   ./update-crds.sh <version>   # e.g. ./update-crds.sh v1.6.0
#
# What it does:
#   1. Downloads standard-install.yaml from the upstream release
#   2. Updates the default in variables.tf
#   3. Updates the example and inputs table in README.md
#
# Note: this script no longer maintains a list of manifest keys. The module
# parses the YAML in pure HCL at plan time (see main.tf) and derives keys
# from `<kind>/<metadata.name>`. New CRDs in a version bump appear
# automatically as new for_each entries; removed CRDs disappear cleanly.
set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
MODULE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CRD_FILE="${MODULE_DIR}/crds/${VERSION}-standard-install.yaml"
VARIABLES_FILE="${MODULE_DIR}/variables.tf"
README_FILE="${MODULE_DIR}/README.md"

# ── 1. Download ──────────────────────────────────────────────────────────────
if [[ -f "$CRD_FILE" ]]; then
  echo "File already exists: ${CRD_FILE}"
  echo "Version ${VERSION} is already present — nothing to do."
  exit 0
fi

DOWNLOAD_URL="https://github.com/kubernetes-sigs/gateway-api/releases/download/${VERSION}/standard-install.yaml"
echo "Downloading ${DOWNLOAD_URL} …"
curl -fsSL -o "$CRD_FILE" "$DOWNLOAD_URL"

# ── 2. Update variables.tf default ──────────────────────────────────────────
sed -i.bak "s/default *= *\"v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"/default     = \"${VERSION}\"/" "$VARIABLES_FILE"
rm -f "${VARIABLES_FILE}.bak"
echo "Updated ${VARIABLES_FILE}"

# ── 3. Update README.md ─────────────────────────────────────────────────────
# Update the crd_version in the usage example and the inputs table
sed -i.bak "s/crd_version = \"v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"/crd_version = \"${VERSION}\"/" "$README_FILE"
sed -i.bak "s/\`\"v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"\`/\`\"${VERSION}\"\`/" "$README_FILE"
rm -f "${README_FILE}.bak"
echo "Updated ${README_FILE}"

echo ""
echo "Done. Version ${VERSION} has been added to the gateway-api-crds module."
