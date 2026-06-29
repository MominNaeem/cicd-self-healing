#!/usr/bin/env bash

set -euo pipefail

GIT_SHA="${1:?Usage: $0 <git_sha> [namespace] [duration_seconds]}"
NAMESPACE="${2:-production}"
DURATION="${3:-300}"
APP_URL="${APP_URL:-http://app.example.com}"

INTERVAL=10
ERROR_WINDOW=30
MAX_ERRORS_IN_WINDOW=3

declare -a error_timestamps=()
start_time=$(date +%s)
end_time=$(( start_time + DURATION ))

echo "Starting health watch for SHA ${GIT_SHA} in namespace ${NAMESPACE}"
echo "Watching ${APP_URL}/health for ${DURATION}s (checking every ${INTERVAL}s)"

prune_old_errors() {
  local now
  now=$(date +%s)
  local cutoff=$(( now - ERROR_WINDOW ))
  local fresh=()
  for ts in "${error_timestamps[@]:-}"; do
    if [[ "$ts" -ge "$cutoff" ]]; then
      fresh+=("$ts")
    fi
  done
  error_timestamps=("${fresh[@]:-}")
}

while true; do
  now=$(date +%s)
  if [[ "$now" -ge "$end_time" ]]; then
    echo "HEALTHY: deployment stable after ${DURATION}s with no degradation"
    exit 0
  fi

  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout 5 \
    --max-time 10 \
    "${APP_URL}/health" || echo "000")

  if [[ "$http_code" != "200" ]]; then
    ts=$(date +%s)
    error_timestamps+=("$ts")
    echo "[$(date -u +%FT%TZ)] ERROR: /health returned HTTP ${http_code}"
  else
    echo "[$(date -u +%FT%TZ)] OK: /health returned HTTP 200"
  fi

  prune_old_errors
  window_errors=${#error_timestamps[@]}

  if [[ "$window_errors" -gt "$MAX_ERRORS_IN_WINDOW" ]]; then
    echo "DEGRADED: ${window_errors} errors in the last ${ERROR_WINDOW}s — triggering rollback"
    exit 1
  fi

  sleep "$INTERVAL"
done
