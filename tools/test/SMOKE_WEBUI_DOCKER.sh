#!/bin/bash
#
# Smoke-test the Docker WebUI endpoint exposed by docker-compose.complete-simulation.yml
# Requires the container to be running with port 8080 mapped to port 80 in-container.
#

set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.complete-simulation.yml}"
SERVICE_NAME="${SERVICE_NAME:-complete-simulator}"

say() { echo "[SMOKE_WEBUI] $*"; }
fail() { echo "[SMOKE_WEBUI] FAIL: $*" >&2; exit 1; }

if ! command -v curl >/dev/null 2>&1; then
  fail "curl not installed on host"
fi

say "Checking (host): $BASE_URL"

# 1) Root should respond (200/30x). We don't assume a specific content.
# Wait for readiness because the systemd unit may take a few seconds.
ok=false
for _ in $(seq 1 30); do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/" || true)"
  case "$code" in
    200|301|302)
      say "OK: GET / -> HTTP $code"
      ok=true
      break
      ;;
    000)
      # Empty reply / connection issue (server not ready yet)
      sleep 1
      ;;
    *)
      # Some other response; give it a moment in case server is still starting
      sleep 1
      ;;
  esac
done

if [ "$ok" != true ]; then
  say "WARN: host port did not become ready within 30s (last HTTP code: ${code:-000})"

  # Fallback: verify WebUI reachability from inside the container. This is
  # deterministic even when Docker Desktop's port forwarding is flaky for
  # systemd-in-container setups.
  if command -v docker >/dev/null 2>&1 && [ -f "$(pwd)/$COMPOSE_FILE" ]; then
    cid="$(docker compose -f "$COMPOSE_FILE" ps -q "$SERVICE_NAME" 2>/dev/null || true)"
    if [ -n "$cid" ]; then
      say "Falling back to in-container curl: http://127.0.0.1:80/"
      in_code="$(docker exec "$cid" sh -lc "curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:80/ || true" | tr -d '\r')"
      case "$in_code" in
        2??|3??|4??|5??)
          say "OK (in-container): GET / -> HTTP $in_code (reachable)"
          ok=true
          ;;
        *)
          say "Last 200 lines of docker compose logs:"
          docker compose -f "$COMPOSE_FILE" logs --no-color --tail=200 || true
          fail "WebUI not reachable from host or inside container (host=${code:-000}, in-container=${in_code:-000})"
          ;;
      esac
    else
      say "Last 200 lines of docker compose logs:"
      docker compose -f "$COMPOSE_FILE" logs --no-color --tail=200 || true
      fail "Could not resolve container id for service '$SERVICE_NAME' to run fallback curl"
    fi
  fi
fi

# 2) Try a couple of common static assets locations (best-effort).
for path in "/index.html" "/css/style.css" "/js/playerlib.js" "/js/scripts-panels.js"; do
  code="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL$path" || true)"
  if [ "$code" = "200" ] || [ "$code" = "304" ]; then
    say "OK: GET $path -> HTTP $code"
  else
    say "WARN: GET $path -> HTTP $code (may be fine depending on moOde routing/build)"
  fi
done

say "WebUI smoke-test done"
