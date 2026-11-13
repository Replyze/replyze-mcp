// Checks that the client configs, server.json and the README agree with each other:
// - every URL in examples/*/*.json is the server's URL from server.json;
// - VS Code ${input:...} and Claude Desktop ${VAR} references are all defined;
// - every config block in the README is one of the example files, unchanged;
// - (when examples/install-links.mjs exists) the README's one-click links are what
//   the script prints, and they decode to the server's configuration.
// The JSON Schemas in .github/schemas/ are checked separately with check-jsonschema.
//   node scripts/check-configs.mjs
import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { deepStrictEqual } from 'node:assert/strict';
import { fileURLToPath } from 'node:url';

const root = new URL('..', import.meta.url);
const read = (path) => readFileSync(new URL(path, root), 'utf8');
const failures = [];
const fail = (msg) => failures.push(msg);

// The server's URL, with each URL variable set to its placeholder ("acme-help").
const server = JSON.parse(read('server.json'));
const remote = server.remotes[0];
const endpoint = remote.url.replace(/\{(\w+)\}/g, (_, name) => {
  const v = remote.variables?.[name];
  if (!v?.placeholder) fail(`server.json: variable {${name}} has no placeholder`);
  return v?.placeholder ?? name;
});

const examples = [];
for (const dir of readdirSync(new URL('examples/', root), { withFileTypes: true })) {
  if (!dir.isDirectory()) continue;
  for (const file of readdirSync(new URL(`examples/${dir.name}/`, root))) {
    if (file.endsWith('.json')) {
      const path = `examples/${dir.name}/${file}`;
      examples.push({ path, json: JSON.parse(read(path)) });
    }
  }
}
if (examples.length === 0) fail('no example configs found');

const strings = (value) => (typeof value === 'string' ? [value]
  : Array.isArray(value) ? value.flatMap(strings)
    : value && typeof value === 'object' ? Object.values(value).flatMap(strings) : []);

for (const { path, json } of examples) {
  const urls = strings(json).filter((s) => /^https?:\/\//.test(s));
  if (urls.length === 0) fail(`${path}: no server URL`);
  for (const url of urls) if (url !== endpoint) fail(`${path}: ${url} is not ${endpoint}`);

  if (json.servers) {
    const defined = new Set((json.inputs ?? []).map((i) => i.id));
    const used = new Set(strings(json.servers).flatMap((s) => [...s.matchAll(/\$\{input:([^}]+)\}/g)].map((m) => m[1])));
    for (const id of used) if (!defined.has(id)) fail(`${path}: \${input:${id}} has no input`);
    for (const id of defined) if (!used.has(id)) fail(`${path}: input ${id} is never used`);
  }
  for (const [name, s] of Object.entries(json.mcpServers ?? {})) {
    if (!s.command) continue;
    const used = strings(s.args).flatMap((a) => [...a.matchAll(/\$\{(\w+)\}/g)].map((m) => m[1]));
    for (const v of used) if (!(s.env && v in s.env)) fail(`${path}: ${name} uses \${${v}} but env doesn't set it`);
  }
}

// Every config block in the README is an example file.
const readme = read('README.md').replace(/\r\n/g, '\n');
const jsonBlocks = [...readme.matchAll(/```json\n([\s\S]*?)```/g)].map((m) => m[1]);
let configBlocks = 0;
for (const block of jsonBlocks) {
  let json;
  try {
    json = JSON.parse(block);
  } catch (e) {
    fail(`README.md: a json block doesn't parse: ${e.message}`);
    continue;
  }
  if (!json.mcpServers && !json.servers) continue;
  configBlocks++;
  const same = examples.some((ex) => {
    try { deepStrictEqual(json, ex.json); return true; } catch { return false; }
  });
  if (!same) fail(`README.md: this config block matches no file in examples/:\n${block}`);
}

// One-click install links (knowledge-base-mcp-server).
let links = 0;
if (existsSync(new URL('examples/install-links.mjs', root))) {
  const out = execFileSync(process.execPath, [fileURLToPath(new URL('examples/install-links.mjs', root)), 'acme-help'], { encoding: 'utf8' });
  const vscodeWeb = out.match(/VS Code: (\S+)/)?.[1];
  const cursor = out.match(/Cursor: +(\S+)/)?.[1];
  if (!vscodeWeb || !cursor) fail('examples/install-links.mjs: unexpected output');
  else {
    if (!readme.includes(`(${vscodeWeb})`)) fail('README.md: the VS Code link is not the one examples/install-links.mjs prints');
    if (!readme.includes(cursor)) fail('README.md: the Cursor link is not the one examples/install-links.mjs prints');
    const vscode = new URL(vscodeWeb).searchParams.get('url');
    const config = JSON.parse(decodeURIComponent(vscode.replace(/^vscode:mcp\/install\?/, '')));
    deepStrictEqual(config, { name: 'acme-help', type: 'http', url: endpoint });
    const c = new URL(cursor);
    deepStrictEqual(JSON.parse(Buffer.from(c.searchParams.get('config'), 'base64').toString('utf8')), { url: endpoint });
    if (c.searchParams.get('name') !== 'acme-help') fail('Cursor link: wrong name');
    links = 2;
  }
}

if (failures.length) {
  console.error(failures.join('\n'));
  process.exit(1);
}
console.log(`OK: ${examples.length} example configs, ${configBlocks} README config blocks, ${links} install links, all pointing at ${endpoint}.`);
