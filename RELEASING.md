# Releasing

This repository documents a hosted server, so there is no package to build or publish. What gets released is the server's entry in MCP registries and directories, made from [`server.json`](server.json).

## server.json

- Format: the official MCP Registry's [`server.json` schema, 2025-12-11](https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json), a remote (`streamable-http`) server with no package.
- Name: `io.github.Replyze/replyze-mcp`. The registry checks this namespace letter for letter, so keep the capital `R` of the organization's name.
- `version` matches the `serverInfo.version` the server answers `initialize` with (`1.0.0`). Publish a new version when the tools or the sign-in change.
- The key goes in the `X-Api-Key` header, which the server accepts as well as `Authorization: Bearer`. A registry client asks for it as a secret.
- CI checks it on every push: against the schema (`check-jsonschema`) and with the registry's own validator (`mcp-publisher validate`, which publishes nothing).

## Publish to the official MCP Registry

The registry gives the `io.github.Replyze/*` namespace only to someone who can prove they are an **Owner** of the Replyze GitHub organization. The browser login (`mcp-publisher login github`) can't prove that at the moment ([registry issue #1468](https://github.com/modelcontextprotocol/registry/issues/1468)), so use one of these:

1. **GitHub Actions (no secret needed).** Merge to `main`, then Actions → **Publish to MCP Registry** → **Run workflow**. The workflow ([`publish-mcp-registry.yml`](.github/workflows/publish-mcp-registry.yml)) signs in with the run's OIDC token, which names the organization. Only its `publish` job gets `id-token: write` (and `contents: read`), it runs only on `main`, and `mcp-publisher` is a pinned version checked against its sha256. The first publish works the same way: there is no token to create and nothing to delete afterwards.
2. **From a computer** (only if Actions can't be used), as an Owner of the organization, with a classic personal access token that has only the `read:org` scope and a 1-day expiration; delete it right after:

   ```bash
   mcp-publisher login github --token <token>
   mcp-publisher publish server.json
   ```

   `mcp-publisher` is on the registry's [releases page](https://github.com/modelcontextprotocol/registry/releases) and in Homebrew (`brew install mcp-publisher`).

Then check the entry:

```bash
curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=io.github.Replyze/replyze-mcp"
```

## Other directories

| Directory | How a server gets in | Notes for this server |
|---|---|---|
| [GitHub MCP Registry](https://github.com/mcp) | Reads the official MCP Registry | Nothing more to do after publishing above. |
| VS Code | Looks names up in its active MCP gallery: `vscode:mcp/by-name/io.github.Replyze/replyze-mcp` | Works only once a gallery VS Code uses lists the server. |
| [PulseMCP](https://www.pulsemcp.com/submit) | Not taking submissions; picks up the official MCP Registry | Nothing to do. |
| [Docker MCP Catalog](https://github.com/docker/mcp-registry/blob/main/CONTRIBUTING.md) | A pull request to `docker/mcp-registry` (`task remote-wizard`), reviewed by Docker | Takes remote `streamable-http` servers. |
| [Claude connectors directory](https://claude.com/docs/connectors/building/submission) | A submission form (`claude.ai/directory/manage`), reviewed by Anthropic | Asks for OAuth 2.0 when tools act on a user's account. This server signs in with an API key, so it doesn't qualify until it offers OAuth. |
