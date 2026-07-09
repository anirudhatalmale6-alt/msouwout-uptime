#!/usr/bin/env bash
# Checks every public MsouWout / MyPlopPlop / 48HoursReady endpoint.
# Exits non-zero if any CRITICAL target is down, which makes the workflow open
# an issue. Written 2026-07-09, after the msouwout-backend outage was found by
# the client instead of by us.
#
# Render free services cold-start slowly, so a target is only "down" after it
# fails RETRIES times with a generous timeout. A single slow response is not an
# outage and must not page anyone.

set -uo pipefail

RETRIES="${RETRIES:-3}"
TIMEOUT="${TIMEOUT:-45}"
SLEEP_BETWEEN="${SLEEP_BETWEEN:-30}"

# name|url|allowed status codes (space-separated)
CRITICAL=(
  "MsouWout website|https://msouwout.com|200"
  "MsouWout backend API|https://msouwout-backend.onrender.com/api/businesses|200"
  "MyPlopPlop website|https://myplopplop.com|200"
  "MyPlopPlop API|https://myplopplop-api.onrender.com/api/products|200 404"
  "48HoursReady website|https://48hoursready.com|200"
  "HaitiBiznis API|https://haitibiznis-api.onrender.com|200"
)

# Not launched yet. Reported for visibility, never fails the run.
PENDING=(
  "Lions Club domain|https://haitianamericanlionsclub.org|200"
  "Lions Club (GitHub Pages)|https://anirudhatalmale6-alt.github.io/haitian-american-lions-club/|200"
)

FAILED=()

# curl -w always prints the code; on connection failure it prints 000 and exits
# non-zero. Swallow the exit code rather than echoing a second "000".
probe() { curl -s -o /dev/null -w '%{http_code}' -m "$TIMEOUT" -L "$1" 2>/dev/null || true; }

check() {  # entry, [critical]
  local entry="$1" critical="${2:-}"
  local name="${entry%%|*}"
  local rest="${entry#*|}"
  local url="${rest%%|*}"
  local allowed="${rest#*|}"
  local code=""

  for attempt in $(seq 1 "$RETRIES"); do
    code="$(probe "$url")"
    code="${code:-000}"
    for want in $allowed; do
      if [ "$code" = "$want" ]; then
        printf '  OK    %-28s %s\n' "$name" "$code"
        return 0
      fi
    done
    [ "$attempt" -lt "$RETRIES" ] && sleep "$SLEEP_BETWEEN"
  done

  printf '  DOWN  %-28s %s (expected: %s)\n' "$name" "$code" "$allowed"
  if [ "$critical" = "critical" ]; then
    FAILED+=("$name -> HTTP $code ($url)")
  fi
  return 1
}

echo "Critical targets:"
for e in "${CRITICAL[@]}"; do check "$e" critical || true; done

echo
echo "Pending launch (not alerting):"
for e in "${PENDING[@]}"; do check "$e" || true; done

echo
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "OUTAGE: ${#FAILED[@]} critical target(s) down"
  printf '%s\n' "${FAILED[@]}" > outage.txt
  exit 1
fi

echo "All critical targets healthy."
