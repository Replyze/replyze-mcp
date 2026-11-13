#!/usr/bin/env bash
# Asks the live Replyze MCP server what the README says it answers without a
# valid API key: 401 with a JSON-RPC error whose data.code a client can act on.
# Sends no real key and changes nothing.
#   bash scripts/live-check.sh
set -euo pipefail

URL="${REPLYZE_MCP_URL:-https://client.replyze.chat/api/mcp}"
BODY='{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
failed=0

# expect <what> <status> <text the body must contain> <curl arguments...>
expect() {
  local what=$1 status=$2 text=$3
  shift 3
  local out code
  out=$(curl -sS --retry 3 --max-time 20 -w '\n%{http_code}' "$@")
  code=${out##*$'\n'}
  out=${out%$'\n'*}
  if [ "$code" = "$status" ] && [[ "$out" == *"$text"* ]]; then
    echo "ok   $what: $code"
  else
    echo "FAIL $what: expected $status with $text, got $code $out"
    failed=1
  fi
}

expect "no key" 401 '"code":"missing_api_key"' \
  -X POST "$URL" -H 'Content-Type: application/json' -d "$BODY"
expect "unknown key as a Bearer token" 401 '"code":"invalid_api_key"' \
  -X POST "$URL" -H 'Content-Type: application/json' -H 'Authorization: Bearer rpz_live_not_a_real_key' -d "$BODY"
expect "unknown key in X-Api-Key" 401 '"code":"invalid_api_key"' \
  -X POST "$URL" -H 'Content-Type: application/json' -H 'X-Api-Key: rpz_live_not_a_real_key' -d "$BODY"
expect "JSON-RPC error shape" 401 '"jsonrpc":"2.0","id":null,"error":{"code":-32600' \
  -X POST "$URL" -H 'Content-Type: application/json' -d "$BODY"

exit "$failed"
