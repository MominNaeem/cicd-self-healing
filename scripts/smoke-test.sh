#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${1:?Usage: $0 <base_url>}"
BASE_URL="${BASE_URL%/}"

PASS=0
FAIL=0

check() {
  local label="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "PASS: ${label}"
    PASS=$(( PASS + 1 ))
  else
    echo "FAIL: ${label} — ${result}"
    FAIL=$(( FAIL + 1 ))
  fi
}

echo "Running smoke tests against ${BASE_URL}"
echo "---"

if curl -sf "${BASE_URL}/health" -o /dev/null; then
  check "/health returns 2xx" "ok"
else
  check "/health returns 2xx" "non-2xx or connection error"
fi

if curl -sf "${BASE_URL}/ready" -o /dev/null; then
  check "/ready returns 2xx" "ok"
else
  check "/ready returns 2xx" "non-2xx or connection error"
fi

root_body=$(curl -sf "${BASE_URL}/" || true)
if echo "$root_body" | grep -q '"status"'; then
  check "/ response contains \"status\"" "ok"
else
  check "/ response contains \"status\"" "key not found in response: ${root_body}"
fi

echo "---"
echo "Results: ${PASS} passed, ${FAIL} failed"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
