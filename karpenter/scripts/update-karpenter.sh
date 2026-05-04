#!/usr/bin/env bash
#
# Adds a new Karpenter version to the karpenter module.
#
# Usage:
#   ./update-karpenter.sh <version>   # e.g. ./update-karpenter.sh 1.13.0
#
# What it does:
#   1. Pulls the helm chart .tgz from oci://public.ecr.aws/karpenter at the
#      given version, captures the OCI manifest digest as a sidecar.
#   2. Downloads the four v1 CRD YAMLs from
#      https://raw.githubusercontent.com/aws/karpenter-provider-aws/v<version>/pkg/apis/crds
#   3. Appends the version to locals.tf `supported_versions`.
#   4. Updates the default in variables.tf.
#   5. Updates the example and inputs table in README.md.
#
# Requirements: helm
set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
MODULE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CHART_FILE="${MODULE_DIR}/charts/karpenter-${VERSION}.tgz"
CHART_DIGEST_FILE="${CHART_FILE}.sha256"
CRD_DIR="${MODULE_DIR}/crds/${VERSION}"
LOCALS_FILE="${MODULE_DIR}/locals.tf"
VARIABLES_FILE="${MODULE_DIR}/variables.tf"
README_FILE="${MODULE_DIR}/README.md"

CRDS=(
  "karpenter.k8s.aws_ec2nodeclasses"
  "karpenter.sh_nodeclaims"
  "karpenter.sh_nodeoverlays"
  "karpenter.sh_nodepools"
)

mkdir -p "${MODULE_DIR}/charts" "${CRD_DIR}"

# ── 1. Pull chart .tgz + capture OCI manifest digest ────────────────────────
if [[ -f "$CHART_FILE" ]]; then
  echo "Chart already exists: ${CHART_FILE}"
  echo "Version ${VERSION} is already present — nothing to do."
  exit 0
fi

echo "Pulling karpenter chart ${VERSION} from oci://public.ecr.aws/karpenter …"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PULL_OUTPUT=$(helm pull "oci://public.ecr.aws/karpenter/karpenter" \
  --version "${VERSION}" \
  --destination "$TMPDIR" 2>&1)
echo "$PULL_OUTPUT"

# Extract digest from helm pull output: "Digest: sha256:..."
DIGEST=$(echo "$PULL_OUTPUT" | grep -E "^Digest: " | awk '{print $2}')
if [[ -z "$DIGEST" ]]; then
  echo "ERROR: could not extract OCI digest from helm pull output" >&2
  exit 1
fi

cp "${TMPDIR}/karpenter-${VERSION}.tgz" "$CHART_FILE"
echo "$DIGEST" > "$CHART_DIGEST_FILE"
echo "Chart saved to ${CHART_FILE}"
echo "Digest sidecar saved to ${CHART_DIGEST_FILE}"

# ── 2. Download CRD YAMLs ───────────────────────────────────────────────────
for crd in "${CRDS[@]}"; do
  url="https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${VERSION}/pkg/apis/crds/${crd}.yaml"
  echo "Downloading ${crd}.yaml …"
  curl -fsSL -o "${CRD_DIR}/${crd}.yaml" "$url"
done

# ── 3. Update locals.tf supported_versions ──────────────────────────────────
# Insert the new version into the supported_versions list, keeping the file
# sorted descending by version so the most recent entry is first.
echo "Updating ${LOCALS_FILE} …"
python3 <<PY
import re, pathlib
p = pathlib.Path("${LOCALS_FILE}")
s = p.read_text()
# Capture existing versions
m = re.search(r'supported_versions\s*=\s*\[(.*?)\]', s, re.DOTALL)
if not m:
    raise SystemExit("Could not find supported_versions in locals.tf")
items = [v.strip().strip('"') for v in m.group(1).split(',') if v.strip().strip('",')]
items.append("${VERSION}")
items = sorted(set(items), key=lambda v: tuple(int(x) for x in v.split('.')), reverse=True)
new_block = ',\n    '.join(f'"{v}"' for v in items)
s = re.sub(r'(supported_versions\s*=\s*\[)(.*?)(\])', r'\1\n    ' + new_block + ',\n  \3', s, flags=re.DOTALL)
p.write_text(s)
PY

# ── 4. Update variables.tf default ──────────────────────────────────────────
echo "Updating ${VARIABLES_FILE} …"
sed -i.bak -E "/variable \"chart_version\"/,/^}/ s/(default[[:space:]]*=[[:space:]]*)\"[0-9]+\.[0-9]+\.[0-9]+\"/\1\"${VERSION}\"/" "$VARIABLES_FILE"
rm -f "${VARIABLES_FILE}.bak"

# ── 5. Update README.md ─────────────────────────────────────────────────────
if [[ -f "$README_FILE" ]]; then
  echo "Updating ${README_FILE} …"
  sed -i.bak -E "s/(version[[:space:]]*=[[:space:]]*)\"[0-9]+\.[0-9]+\.[0-9]+\"/\1\"${VERSION}\"/" "$README_FILE"
  sed -i.bak -E "s/karpenter-[0-9]+\.[0-9]+\.[0-9]+\.tgz/karpenter-${VERSION}.tgz/g" "$README_FILE"
  rm -f "${README_FILE}.bak"
fi

echo ""
echo "Done. Karpenter version ${VERSION} has been added."
echo "Don't forget to commit:"
echo "  - charts/karpenter-${VERSION}.tgz"
echo "  - charts/karpenter-${VERSION}.tgz.sha256"
echo "  - crds/${VERSION}/*.yaml"
echo "  - locals.tf, variables.tf, README.md"
