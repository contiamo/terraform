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
#   3. Extracts manifest keys from the YAML
#   4. Appends the version block to locals.tf
#   5. Updates the default in variables.tf
#   6. Updates the example and inputs table in README.md
#
# Requirements: helm, yq
#
# Unlike the envoy-gateway update script (which uses `helm template`), this
# script uses `helm pull --untar` because the OnePasswordItem CRD lives in
# the chart's `/crds/` directory and is not rendered by `helm template`.

set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
MODULE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CRD_FILE="${MODULE_DIR}/crds/onepassword-crd-${VERSION}.yaml"
LOCALS_FILE="${MODULE_DIR}/locals.tf"
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

# ── 2. Extract manifest keys ────────────────────────────────────────────────
# Each YAML document produces a key like:
#   /apis/apiextensions.k8s.io/v1/customresourcedefinitions/<name>
echo "Extracting manifest keys …"

KEYS=()
while IFS= read -r line; do
  KEYS+=("$line")
done < <(
  yq eval '.apiVersion + "," + .kind + "," + .metadata.name' "$CRD_FILE" \
  | grep -v '^---$' \
  | while IFS=, read -r apiVersion kind name; do
      [[ -z "$kind" || "$kind" == "null" ]] && continue
      plural="$(echo "$kind" | tr '[:upper:]' '[:lower:]')s"
      echo "/apis/${apiVersion}/${plural}/${name}"
    done | sort
)

if [[ ${#KEYS[@]} -eq 0 ]]; then
  echo "ERROR: No manifests found in ${CRD_FILE}" >&2
  rm -f "$CRD_FILE"
  exit 1
fi

echo "Found ${#KEYS[@]} manifest keys."

# ── 3. Update locals.tf ─────────────────────────────────────────────────────
{
  # Everything up to (but not including) the closing "  }"
  sed '/^  }$/,$d' "$LOCALS_FILE"

  # New version block
  echo "    \"${VERSION}\" = ["
  for key in "${KEYS[@]}"; do
    echo "      \"${key}\","
  done
  echo "    ]"

  # Closing braces
  echo "  }"
  echo "}"
} > "${LOCALS_FILE}.tmp"
mv "${LOCALS_FILE}.tmp" "$LOCALS_FILE"

echo "Updated ${LOCALS_FILE}"

# ── 4. Update variables.tf default ──────────────────────────────────────────
sed -i.bak -E "s/default *= *\"[0-9]+\\.[0-9]+\\.[0-9]+\"/default     = \"${VERSION}\"/" "$VARIABLES_FILE"
rm -f "${VARIABLES_FILE}.bak"

echo "Updated ${VARIABLES_FILE}"

# ── 5. Update README.md ─────────────────────────────────────────────────────
sed -i.bak -E "s/(chart_version[[:space:]]*=[[:space:]]*)\"[0-9]+\\.[0-9]+\\.[0-9]+\"/\\1\"${VERSION}\"/" "$README_FILE"
sed -i.bak -E "s/\`\"[0-9]+\\.[0-9]+\\.[0-9]+\"\`/\`\"${VERSION}\"\`/" "$README_FILE"
rm -f "${README_FILE}.bak"

echo "Updated ${README_FILE}"

echo ""
echo "Done. 1Password Connect CRDs version ${VERSION} has been added to the onepassword-connect module."
echo "Don't forget to commit the changes."
