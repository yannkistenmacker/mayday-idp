#!/usr/bin/env bash
#
# Generates the encrypted SealedSecret for `backstage-secrets` and writes it to
# the Helm chart so Argo CD can apply it. The output is safe to commit: only the
# sealed-secrets controller running in THIS cluster can decrypt it.
#
# Prerequisites:
#   - kubeseal CLI installed        (https://github.com/bitnami-labs/sealed-secrets/releases)
#   - kubectl context pointing at the cluster where sealed-secrets is installed
#   - the sealed-secrets controller running (env-up.sh installs it)
#
# Usage:
#   GITHUB_CLIENT_ID=xxxx GITHUB_CLIENT_SECRET=yyyy ./scripts/seal-backstage-secret.sh
#
# IMPORTANT: use a FRESH (rotated) client secret. The previous credentials were
# committed to a public repo and must be considered compromised.
set -euo pipefail

: "${GITHUB_CLIENT_ID:?set GITHUB_CLIENT_ID to the (rotated) GitHub App/OAuth client id}"
: "${GITHUB_CLIENT_SECRET:?set GITHUB_CLIENT_SECRET to the (rotated) client secret}"

NAMESPACE="${NAMESPACE:-backstage}"
CONTROLLER_NAME="${CONTROLLER_NAME:-sealed-secrets-controller}"
CONTROLLER_NS="${CONTROLLER_NS:-kube-system}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SCRIPT_DIR/../charts/backstage/templates/sealedsecret.yaml"

echo "🔐 Sealing backstage-secrets (namespace: $NAMESPACE) ..."

kubectl create secret generic backstage-secrets \
  --namespace "$NAMESPACE" \
  --from-literal=GITHUB_CLIENT_ID="$GITHUB_CLIENT_ID" \
  --from-literal=GITHUB_CLIENT_SECRET="$GITHUB_CLIENT_SECRET" \
  --dry-run=client -o yaml \
| kubeseal \
    --controller-name "$CONTROLLER_NAME" \
    --controller-namespace "$CONTROLLER_NS" \
    --format yaml \
> "$OUT"

echo "✅ Wrote $OUT"
echo "   This file is ENCRYPTED and safe to commit. Commit + push and Argo will apply it."
