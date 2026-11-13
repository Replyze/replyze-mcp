<p align="center">
  <a href="https://replyze.chat/?utm_source=github&utm_medium=replyze-mcp">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Replyze/.github/main/assets/logo-on-dark.png">
      <img src="https://raw.githubusercontent.com/Replyze/.github/main/assets/logo-on-light.png" alt="Replyze" height="48">
    </picture>
  </a>
</p>

# Replyze MCP server: your customer support inbox in Claude, Cursor and VS Code

The Replyze [MCP](https://modelcontextprotocol.io) server lets an AI assistant work with your customer support: find and read conversations, reply to customers, leave internal notes for your team, assign conversations, look up contacts and search the knowledge base your support AI answers from. It is a **remote server**: you give your assistant a URL and an API key. There is nothing to install or run. [Replyze](https://replyze.chat/?utm_source=github&utm_medium=replyze-mcp) is AI customer support: an AI agent that answers from your docs, live chat for your website, and one inbox for chat, email, WhatsApp and Telegram.

**[Create a free account](https://client.replyze.chat/register?utm_source=github&utm_medium=replyze-mcp&utm_content=cta-top)** · [Live demo](https://replyze.chat/?utm_source=github&utm_medium=replyze-mcp&utm_content=live-demo) · [Docs](https://github.com/Replyze/replyze)

## Quickstart

1. **Make an API key.** [Create a free account](https://client.replyze.chat/register?utm_source=github&utm_medium=replyze-mcp&utm_content=quickstart), open **Settings → Integrations → Developer** and create a key. For a first try, tick only the read scopes (`conversations:read`, `contacts:read`, `knowledge:read`): the assistant can look everything up but can't write to a customer.
2. **Add the server to your assistant.** In Claude Code:

   ```bash
   claude mcp add --transport http replyze https://client.replyze.chat/api/mcp \
     --header "Authorization: Bearer YOUR_API_KEY"
   ```

   [Claude Desktop](#claude-desktop), [Cursor](#cursor), [VS Code](#vs-code) and [other clients](#other-clients) are below.
3. **Ask it something**, for example "Which open conversations are waiting on us? Group them by topic."

| Server | URL | Sign-in |
|---|---|---|
| Your workspace | `https://client.replyze.chat/api/mcp` | API key as a Bearer token |
| Your public help center | `https://client.replyze.chat/api/mcp/kb/<your-help-center-slug>` | none |

## Contents

[Quickstart](#quickstart) ·
[What you can ask](#what-you-can-ask) ·
[Example](#example) ·
[Tools](#tools) ·
[Set up](#set-up) ([Claude Code](#claude-code) · [Claude Desktop](#claude-desktop) · [Cursor](#cursor) · [VS Code](#vs-code) · [Other clients](#other-clients) · [claude.ai and ChatGPT](#claudeai-and-chatgpt)) ·
[Public help center](#public-help-center-mcp) ·
[Permissions and safety](#permissions-and-safety) ·
[Protocol](#protocol-details) ·
[Errors](#errors)

## What you can ask

- "Which open conversations are waiting on us? Group them by topic."
- "Find everything Maria Lopez wrote to us this month and summarize it before my call."
- "Draft replies for the open refund questions from our knowledge base. Don't send anything."
- "Assign the conversations about invoices to Ana and leave her a note with the context."
- "What do customers ask that our knowledge base doesn't answer?"
- "Is our return window 30 or 60 days? Check the knowledge base."

## Example

An example of how a session goes (the assistant decides which tools to call):

> **You:** Which open conversations mention a refund? Draft a reply for each, but don't send them.
>
> *The assistant calls `search_conversations(query="refund", status="open")`, then `get_conversation` for each result and `search_knowledge(query="refund policy")`, and writes the drafts in the chat.*
>
> **You:** The draft for #4812 is good. Send it, and leave a note for the team that we promised a refund within 5 days.
>
> *The assistant calls `send_message(conversation_id=4812, content="...")`, so the customer gets the reply on the channel they wrote from, then `add_note(conversation_id=4812, content="...")`, which only the team sees.*

## Tools

What a key can do depends on its scopes. `tools/list` shows only the tools the key can use, and a write scope includes the read scope of the same resource (`conversations:write` can also read conversations).

| Tool | Scope | What it does | Arguments |
|---|---|---|---|
| `search_conversations` | `conversations:read` | Finds conversations, newest activity first. Matches the contact's name, email or phone, the subject, and anything the visitor or the team wrote (not internal notes). | `query`, `status` (`open`, `pending`, `snoozed`, `resolved`, `closed`, `spam`), `contact_id`, `assigned_agent_id`, `limit` (1 to 50, default 10); all optional |
| `get_conversation` | `conversations:read` | One conversation with its latest messages, oldest first: the visitor's messages, the team's replies, the AI's replies and the team's internal notes (marked as such). | `conversation_id` (required), `message_limit` (1 to 100, default 30) |
| `list_agents` | `conversations:read` | The teammates who answer conversations, with their ids, roles and whether they are online. | none |
| `send_message` | `conversations:write` | Sends a reply to the customer on the conversation's channel (the chat widget, email, WhatsApp, Telegram or another connected channel). A resolved conversation opens again. | `conversation_id`, `content` (plain text, up to 10,000 characters), `agent_id` (optional: the teammate it is sent as; without it, it is from the team) |
| `add_note` | `conversations:write` | Adds an internal note the team sees in the inbox and the customer never does. | `conversation_id`, `content`, `agent_id` (optional) |
| `assign_conversation` | `conversations:write` | Gives a conversation to a teammate and/or a team; `null` takes it off them. | `conversation_id`, `agent_id`, `team_id` (at least one of the two) |
| `search_contacts` | `contacts:read` | Finds contacts by name, email, phone or company, newest first. | `query` (required), `limit` (1 to 50, default 10) |
| `get_contact` | `contacts:read` | One contact with their details, custom data and latest conversations. | `contact_id` |
| `search_knowledge` | `knowledge:read` | Searches what your AI answers from: published knowledge base articles and the website pages and files it learned. Each result says where it comes from. | `query` (required, 2 to 500 characters) |
| `get_article` | `knowledge:read` | One knowledge base article with its full text, drafts included. | `article_id` or `slug` |

Every tool carries MCP annotations: the read tools are `readOnlyHint: true`, and `send_message` is `openWorldHint: true` because it reaches someone outside the workspace. The other scopes (`contacts:write`, `knowledge:write`, `analytics:read`) are used by the [REST API](https://github.com/Replyze/replyze#4-rest-api), not by MCP tools.

## Set up

### 1. Make an API key

In the Replyze dashboard: **Settings → Integrations → Developer**, create a key and tick the scopes it needs. Owners and admins can make keys. The key (`rpz_live_...`) is shown once; it acts as the workspace, not as a person, and you can revoke it at any time.

Whether a workspace has the API and the MCP server depends on its plan ([pricing](https://replyze.chat/pricing?utm_source=github&utm_medium=replyze-mcp)); without it, the server answers `403` with `plan_required`. No account yet? [Sign up](https://client.replyze.chat/register?utm_source=github&utm_medium=replyze-mcp).

Start with a read-only key (`conversations:read`, `contacts:read`, `knowledge:read`): the assistant can look everything up but cannot write to a customer.

### 2. Add the server to your assistant

Replace `YOUR_API_KEY` with your key. Ready-made files are in [`examples/`](examples).

#### Claude Code

```bash
claude mcp add --transport http replyze https://client.replyze.chat/api/mcp \
  --header "Authorization: Bearer YOUR_API_KEY"
```

#### Claude Desktop

Claude Desktop reaches remote servers with an API key through [`mcp-remote`](https://github.com/punkpeye/mcp-remote), which needs Node.js. Open Settings → Developer → Edit Config, add this to `claude_desktop_config.json`, then restart Claude:

```json
{
  "mcpServers": {
    "replyze": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://client.replyze.chat/api/mcp", "--header", "Authorization:${REPLYZE_AUTH}"],
      "env": { "REPLYZE_AUTH": "Bearer YOUR_API_KEY" }
    }
  }
}
```

The header is passed through `env` because some systems split an argument with a space in it.

#### Cursor

Cursor → Settings → MCP → Add new server, or `.cursor/mcp.json` in your project (`~/.cursor/mcp.json` for every project):

```json
{
  "mcpServers": {
    "replyze": {
      "url": "https://client.replyze.chat/api/mcp",
      "headers": { "Authorization": "Bearer YOUR_API_KEY" }
    }
  }
}
```

#### VS Code

`.vscode/mcp.json`. VS Code asks for the key the first time and stores it, so it isn't in the file:

```json
{
  "inputs": [
    { "type": "promptString", "id": "replyze-api-key", "description": "Replyze API key", "password": true }
  ],
  "servers": {
    "replyze": {
      "type": "http",
      "url": "https://client.replyze.chat/api/mcp",
      "headers": { "Authorization": "Bearer ${input:replyze-api-key}" }
    }
  }
}
```

#### Other clients

Any client that connects to a remote MCP server over Streamable HTTP with a custom header works the same way: the URL `https://client.replyze.chat/api/mcp` and the header `Authorization: Bearer YOUR_API_KEY` (`X-Api-Key: YOUR_API_KEY` works too). Windsurf, for example, takes a URL and headers; see your client's docs for where its config file lives.

#### claude.ai and ChatGPT

Custom connectors on claude.ai and in ChatGPT sign in with OAuth, which Replyze doesn't offer yet, so they can't use the workspace server. Both can use your [public help center server](#public-help-center-mcp), which needs no sign-in.

## Public help center MCP

When your public help center is on (Knowledge Base in the dashboard), it is also an MCP server that anyone's assistant can use without a key:

```
https://client.replyze.chat/api/mcp/kb/<your-help-center-slug>
```

The slug is the last part of your help center's address; the dashboard shows the full MCP URL in Settings → Integrations → Developer. It answers only while the help center is on, and only with published articles.

| Tool | What it does | Arguments |
|---|---|---|
| `search_articles` | Searches the published articles, the way the help center's own search does. Returns titles, URLs and short summaries. | `query` (2 to 200 characters), `locale` (one of the help center's languages), `limit` (1 to 20, default 5) |
| `get_article` | One published article with its full text and URL. | `slug` or `article_id` |

Use it to let customers ask your docs from their own assistant: put the URL on your help center. In ChatGPT, add it in developer mode as a connector with no authentication; on claude.ai, as a custom connector with the URL.

## Permissions and safety

- **Replies are real.** `send_message` reaches the customer at once, on their channel. The server tells assistants to confirm with you before sending; keep your client's tool approval on for it.
- **Notes stay internal.** `add_note` is seen by your team only.
- **Scopes limit the damage.** Give a key only the scopes it needs, and make separate keys for separate uses so you can revoke one without the others.
- **Everything is logged.** Every change, and every read of a conversation or contact, made through MCP is in the workspace's audit log, as with the REST API. A reply sent through MCP records that it came through MCP and which key sent it.
- **Rate limits.** Requests count against the key's rate limit, as for the REST API: 120 a minute per key. Each answer carries `X-RateLimit-Limit`, `X-RateLimit-Remaining` and `X-RateLimit-Reset`. The public help center server is rate limited per IP.

## Protocol details

For client authors and debugging:

- Transport: Streamable HTTP, stateless. JSON-RPC 2.0 messages are POSTed to the URL and each request gets one JSON answer. There is no event stream and no session; with a valid key, GET and DELETE answer 405.
- Protocol versions: `2026-07-28`, and the `initialize`-based `2025-11-25`, `2025-06-18`, `2025-03-26` and `2024-11-05`. Clients that speak `2026-07-28` find it with `server/discover`; the others use `initialize` as before.
- `2026-07-28` has no handshake. Every request names the version and the client's capabilities in `params._meta` (`io.modelcontextprotocol/protocolVersion`, `io.modelcontextprotocol/clientCapabilities`) and repeats them in headers: `MCP-Protocol-Version`, `Mcp-Method`, and `Mcp-Name` on `tools/call`. A missing header or one that disagrees with the body gets `400`. Every result carries `resultType: "complete"` and the server's name and version in `_meta["io.modelcontextprotocol/serverInfo"]`. `server/discover` and `tools/list` say how long a client may reuse them: `ttlMs: 300000` (5 minutes) and `cacheScope: "private"`, because the tools depend on the key.
- The `initialize`-based versions: `initialize` answers in the client's version when it is one of the four, and in `2025-11-25` otherwise. Their answers have no `resultType` and no caching hints.
- Methods: `server/discover`, `tools/list` and `tools/call` in `2026-07-28`; `initialize`, `ping`, `tools/list` and `tools/call` in the older versions. Notifications get `202` with no body. Batches are accepted from older clients only. The tool list doesn't push changes (`listChanged: false`), so there is no `subscriptions/listen`.
- Tool results come as text (JSON) and as `structuredContent`. A tool that fails returns `isError: true` with a message.

Try it with cURL ([`examples/curl.sh`](examples/curl.sh) runs both flows: `initialize` in `2025-11-25`, then `server/discover` and a tool call in `2026-07-28`). Without the `2026-07-28` metadata, a request is answered the way the older versions are:

```bash
curl -s https://client.replyze.chat/api/mcp \
  -H "Authorization: Bearer $REPLYZE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'

curl -s https://client.replyze.chat/api/mcp \
  -H "Authorization: Bearer $REPLYZE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"search_knowledge","arguments":{"query":"How long does shipping take?"}}}'
```

The same call in `2026-07-28`:

```bash
curl -s https://client.replyze.chat/api/mcp \
  -H "Authorization: Bearer $REPLYZE_API_KEY" \
  -H "Content-Type: application/json" \
  -H "MCP-Protocol-Version: 2026-07-28" \
  -H "Mcp-Method: tools/call" \
  -H "Mcp-Name: search_knowledge" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"search_knowledge","arguments":{"query":"How long does shipping take?"},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{}}}}'
```

The [MCP Inspector](https://github.com/modelcontextprotocol/inspector) works too: transport Streamable HTTP, the URL above and the `Authorization` header. Its CLI uses `2026-07-28` with `--protocol-era auto` (or `modern`) and `2025-11-25` by default.

## Errors

The HTTP status says what went wrong and the body is a JSON-RPC error whose `data.code` a client can act on:

| Status | `data.code` | Meaning |
|---|---|---|
| 401 | `missing_api_key` | No key was sent. Send `Authorization: Bearer <key>`. |
| 401 | `invalid_api_key`, `api_key_revoked`, `api_key_expired` | The key doesn't work any more. Make a new one. |
| 403 | `plan_required` | The workspace's plan doesn't include the API. |
| 403 | `workspace_suspended` | The workspace is suspended. |
| 429 | `rate_limited` | Too many requests. Wait for `Retry-After` seconds. |

The key is checked first: without a valid one, every request gets the `401` above, whatever its method or protocol version.

With a valid key, these are about the request itself (no `data.code`):

| Status | JSON-RPC code | Meaning |
|---|---|---|
| 400 | `-32700` | The body isn't JSON. |
| 400 | `-32022` | The `MCP-Protocol-Version` header, or `_meta` in `2026-07-28`, names a version the server doesn't speak. `data.supported` lists the ones it does, `data.requested` the one you sent. |
| 400 | `-32020` | `2026-07-28`: the `MCP-Protocol-Version`, `Mcp-Method` or `Mcp-Name` header is missing or disagrees with the body, or `initialize` was sent with `MCP-Protocol-Version: 2026-07-28`. |
| 400 | `-32602` | `2026-07-28`: `params._meta` lacks `io.modelcontextprotocol/protocolVersion` or `io.modelcontextprotocol/clientCapabilities`, or one of its values has the wrong type. |
| 400 | `-32600` | `2026-07-28`: a batch, or a body that isn't a JSON-RPC 2.0 request. |
| 404 | `-32601` | `2026-07-28`: a method the server doesn't have, including `initialize` and `ping`, which that version doesn't define. |

With HTTP `200`, a JSON-RPC error means the request itself was wrong: `-32601` for an unknown method (older versions), `-32602` for an unknown tool or a tool the key's scopes don't cover (then `data.required_scope` names the scope it needs). A tool that ran but failed answers a normal result with `isError: true`, and `structuredContent` holds `error` and a `message` the assistant can show: `invalid_arguments` when the arguments don't fit the tool's schema, otherwise a code such as `not_found` or `validation_failed`.

## Related

- [replyze](https://github.com/Replyze/replyze): the chat widget, its JavaScript API, the REST API and webhooks
- [add-live-chat-to-website](https://github.com/Replyze/add-live-chat-to-website): the chat on any website, platform by platform
- [REST API reference (OpenAPI 3.1)](https://client.replyze.chat/api/v1/openapi.json)

The endpoints, transport and errors on this page follow the server's source and its test suite, and were checked with the MCP Inspector and the official TypeScript and Python SDKs in November 2026; the client configs are the ones the Replyze dashboard gives.

## For registries

[`server.json`](server.json) describes this server in the format of the official [MCP Registry](https://registry.modelcontextprotocol.io). How it gets published, and to which other directories: [RELEASING.md](RELEASING.md). CI checks the example configs, `server.json` and the live server's error answers on every push.

## License

MIT, see [LICENSE](LICENSE).
