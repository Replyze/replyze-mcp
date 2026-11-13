#!/usr/bin/env bash
# Talks to the Replyze MCP server with cURL: initialize, list the tools your
# key can use and search the knowledge base (protocol 2025-11-25), then the
# same search in protocol 2026-07-28, which has no initialize.
#   REPLYZE_API_KEY=rpz_live_... ./curl.sh "How long does shipping take?"
set -euo pipefail

URL="${REPLYZE_MCP_URL:-https://client.replyze.chat/api/mcp}"
KEY="${REPLYZE_API_KEY:?Set REPLYZE_API_KEY to an API key from Settings, Integrations, Developer}"
QUESTION="${1:-How long does shipping take?}"

# The question goes into JSON: escape backslashes and double quotes.
q=${QUESTION//\\/\\\\}
q=${q//\"/\\\"}

# call <body> [extra curl arguments...]
call() {
  local body=$1
  shift
  curl -sS "$URL" \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    "$@" \
    -d "$body"
  echo
}

echo "== initialize (2025-11-25)"
call '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"curl","version":"1.0"}}}'

echo "== tools/list"
call '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' -H "MCP-Protocol-Version: 2025-11-25"

echo "== tools/call search_knowledge"
call "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"search_knowledge\",\"arguments\":{\"query\":\"$q\"}}}" \
  -H "MCP-Protocol-Version: 2025-11-25"

# 2026-07-28: every request carries the version and the client's capabilities
# in _meta and repeats the version, the method and the tool name in headers.
META='"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{},"io.modelcontextprotocol/clientInfo":{"name":"curl","version":"1.0"}}'

echo "== server/discover (2026-07-28)"
call "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"server/discover\",\"params\":{$META}}" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: server/discover"

echo "== tools/call search_knowledge (2026-07-28)"
call "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"search_knowledge\",\"arguments\":{\"query\":\"$q\"},$META}}" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: tools/call" -H "Mcp-Name: search_knowledge"
