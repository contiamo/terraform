#!/usr/bin/env bash
#
# Adds a new 1Password Connect CRD version to the onepassword-connect module.
#
# Usage:
#   ./update-onepassword-crds.sh <version>   # e.g. ./update-onepassword-crds.sh 2.4.2
#
# What it does:
#   1. Pulls the 1password/connect chart at the given version
#   2. Copies the CRD to crds/onepassword-crd-<version>.yaml
#   3. Updates the default in variables.tf
#   4. Updates the example and inputs table in README.md
#
# Note: this script no longer maintains a list of manifest keys. The module
# parses the YAML in pure HCL at plan time (see main.tf) and derives keys
# from `<kind>/<metadata.name>`.
#
# Requirements: helm
#
# Unlike the envoy-gateway update script (which uses `helm template`), this
# script uses `helm pull --untar` because the OnePasswordItem CRD lives in
# the chart's `/crds/` directory and is not rendered by `helm template`.

set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
MODULE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CRD_FILE="${MODULE_DIR}/crds/onepassword-crd-${VERSION}.yaml"
VARIABLES_FILE="${MODULE_DIR}/variables.tf"
README_FILE="${MODULE_DIR}/README.md"

mkdir -p "${MODULE_DIR}/crds"

# ── 1. Pull chart ───────────────────────────────────────────────────────────
if [[ -f "$CRD_FILE" ]]; then
  echo "File already exists: ${CRD_FILE}"
  echo "Version ${VERSION} is already present — nothing to do."
  exit 0
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Pulling 1password/connect at ${VERSION} to ${TMPDIR} …"
helm repo add 1password https://1password.github.io/connect-helm-charts >/dev/null 2>&1 || true
helm repo update 1password >/dev/null
helm pull 1password/connect --version "${VERSION}" --untar --untardir "$TMPDIR"

CHART_CRD="${TMPDIR}/connect/crds/onepassworditem-crd.yaml"
if [[ ! -f "$CHART_CRD" ]]; then
  echo "ERROR: CRD not found at ${CHART_CRD}" >&2
  exit 1
fi

cp "$CHART_CRD" "$CRD_FILE"
echo "Saved CRD to ${CRD_FILE}"

# ── 2. Update variables.tf default ──────────────────────────────────────────
sed -i.bak -E "s/default *= *\"[0-9]+\\.[0-9]+\\.[0-9]+\"/default     = \"${VERSION}\"/" "$VARIABLES_FILE"
rm -f "${VARIABLES_FILE}.bak"
echo "Updated ${VARIABLES_FILE}"

# ── 3. Update README.md ─────────────────────────────────────────────────────
sed -i.bak -E "s/(chart_version[[:space:]]*=[[:space:]]*)\"[0-9]+\\.[0-9]+\\.[0-9]+\"/\\1\"${VERSION}\"/" "$README_FILE"
sed -i.bak -E "s/\`\"[0-9]+\\.[0-9]+\\.[0-9]+\"\`/\`\"${VERSION}\"\`/" "$README_FILE"
rm -f "${README_FILE}.bak"
echo "Updated ${README_FILE}"

echo ""
echo "Done. 1Password Connect CRDs version ${VERSION} has been added to the onepassword-connect module."
echo "Don't forget to commit the changes."
