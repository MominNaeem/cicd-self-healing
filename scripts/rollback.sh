#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${1:-production}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

echo "Initiating rollback in namespace ${NAMESPACE}"

kubectl rollout undo deployment/app --namespace="${NAMESPACE}"

kubectl rollout status deployment/app --namespace="${NAMESPACE}" --timeout=120s

previous_image=$(kubectl rollout history deployment/app \
  --namespace="${NAMESPACE}" \
  --revision=1 \
  -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "unknown")

echo "Rollback complete. Previous image: ${previous_image}"

if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
  curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"🔴 Rollback triggered in ${NAMESPACE}. Reverted to previous image.\"}"
  echo ""
  echo "Slack notification sent"
else
  echo "SLACK_WEBHOOK_URL not set — skipping Slack notification"
fi
