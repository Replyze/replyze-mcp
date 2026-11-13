#!/usr/bin/env bash
# Talks to the Replyze MCP server with cURL: initialize, list the tools your
# key can use, and search the knowledge base.
#   REPLYZE_API_KEY=rpz_live_... ./curl.sh "How long does shipping take?"
set -euo pipefail

URL="${REPLYZE_MCP_URL:-https://client.replyze.chat/api/mcp}"
KEY="${REPLYZE_API_KEY:?Set REPLYZE_API_KEY to an API key from Settings, Integrations, Developer}"
QUESTION="${1:-How long does shipping take?}"

call() {
  curl -sS "$URL" \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -H "MCP-Protocol-Version: 2025-06-18" \
    -d "$1"
  echo
}

echo "== initialize"
call '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"curl","version":"1.0"}}}'

echo "== tools/list"
call '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

echo "== tools/call search_knowledge"
# The question goes into JSON: escape backslashes and double quotes.
q=${QUESTION//\\/\\\\}
q=${q//\"/\\\"}
call "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"search_knowledge\",\"arguments\":{\"query\":\"$q\"}}}"
