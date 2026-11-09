#!/usr/bin/env bash
#
# Refresh the vendored Envoy Gateway Grafana dashboards under dashboards/.
#
# Usage:
#   ./update-envoy-dashboards.sh <version>   # e.g. ./update-envoy-dashboards.sh v1.8.0
#
# Pulls the dashboard JSON files from
# envoyproxy/gateway @ <version>:charts/gateway-addons-helm/dashboards
# and writes them under <module>/dashboards/. Run on every chart_version bump
# alongside scripts/update-envoy-crds.sh.
#
set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
MODULE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${MODULE_DIR}/dashboards"

DASHBOARDS=(
  envoy-clusters.json
  envoy-gateway-global.json
  envoy-proxy-global.json
  global-ratelimit.json
  resources-monitor.gen.json
)

mkdir -p "$DEST"

BASE_URL="https://raw.githubusercontent.com/envoyproxy/gateway/${VERSION}/charts/gateway-addons-helm/dashboards"

for f in "${DASHBOARDS[@]}"; do
  echo "Fetching ${f} …"
  curl -sSfL -o "${DEST}/${f}" "${BASE_URL}/${f}"
done

echo ""
echo "Done. Dashboards refreshed at ${VERSION} under ${DEST}."
echo "Don't forget to commit the changes."
