#!/usr/bin/env bash
#
# Adds a new Gateway API CRD version to the module.
#
# Usage:
#   ./update-crds.sh <version>   # e.g. ./update-crds.sh v1.6.0
#
# What it does:
#   1. Downloads standard-install.yaml from the upstream release
#   2. Extracts manifest keys from the YAML (no tofu/kubectl needed)
#   3. Appends the version block to locals.tf
#   4. Updates the default in variables.tf
#   5. Updates the example and inputs table in README.md
#
set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
MODULE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CRD_FILE="${MODULE_DIR}/crds/${VERSION}-standard-install.yaml"
LOCALS_FILE="${MODULE_DIR}/locals.tf"
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

# ── 2. Extract manifest keys ────────────────────────────────────────────────
# Each YAML document produces a key like:
#   /apis/apiextensions.k8s.io/v1/customresourcedefinitions/name
#
# The plural resource name is the lowercase Kind + "s", which matches what the
# kubectl Terraform provider generates.
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
# Build the new version block and insert it before the closing "  }"
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
sed -i.bak "s/default *= *\"v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"/default     = \"${VERSION}\"/" "$VARIABLES_FILE"
rm -f "${VARIABLES_FILE}.bak"

echo "Updated ${VARIABLES_FILE}"

# ── 5. Update README.md ─────────────────────────────────────────────────────
# Update the crd_version in the usage example and the inputs table
sed -i.bak "s/crd_version = \"v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"/crd_version = \"${VERSION}\"/" "$README_FILE"
sed -i.bak "s/\`\"v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"\`/\`\"${VERSION}\"\`/" "$README_FILE"
rm -f "${README_FILE}.bak"

echo "Updated ${README_FILE}"

echo ""
echo "Done. Version ${VERSION} has been added to the gateway-api-crds module."
