#!/usr/bin/env bash
# Smoke checks: bash smoke.sh BASE_URL EXPECTED_ENV
base="${1:-http://127.0.0.1:18080}"; env="${2:-workshop-blue}"; fail=0; id="smoke-$(date -u +%Y%m%dT%H%M%SZ)"
ok() { if [ "$1" = "$2" ]; then echo "PASS $3: $1"; else echo "FAIL $3: got '$1', expected '$2'"; fail=1; fi; }
for i in $(seq 30); do curl -fs "$base/healthz" >/dev/null && break; sleep 1; done
ok "$(curl -s "$base/healthz")" "Healthy" "health"
ok "$(curl -s -o /dev/null -w '%{http_code}' "$base/")" "200" "page"
rm -f /tmp/board.json; h="$(curl -s -D - -o /tmp/board.json -H "X-Request-Id: $id" "$base/api/boards/reference" | tr -d '\r')"
ok "$(echo "$h" | head -1 | cut -d' ' -f2)" "200" "reference status"
ok "$(python3 -c 'import json;b=json.load(open("/tmp/board.json"));print(b["width"],b["height"],b["initialMoves"])' 2>/dev/null)" "3 3 6" "board 3x3, 6 moves"
ok "$(echo "$h" | sed -n 's/^X-Lab-Release: //Ip')" "foundation-observe-a" "release"
ok "$(echo "$h" | sed -n 's/^X-Lab-Environment: //Ip')" "$env" "environment"
ok "$(echo "$h" | sed -n 's/^X-Request-Id: //Ip')" "$id" "request id echoed"
ok "$(curl -s -o /dev/null -w '%{http_code}' "$base/api/boards/missing")" "404" "missing board"
echo "request id: $id"; [ $fail = 0 ] && echo "SMOKE PASSED" || { echo "SMOKE FAILED"; exit 1; }
