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
#   3. Extracts manifest keys from the YAML
#   4. Appends the version block to locals.tf
#   5. Updates the default in variables.tf
#   6. Updates the example and inputs table in README.md
#
# Requirements: helm, yq
#
set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
MODULE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CRD_FILE="${MODULE_DIR}/crds/envoy-crds-${VERSION}.yaml"
LOCALS_FILE="${MODULE_DIR}/locals.tf"
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
