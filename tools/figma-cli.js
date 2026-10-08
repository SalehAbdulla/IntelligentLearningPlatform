// figma-cli.js, drive the Figma MCP server from the shell for repeatable evidence work.
//   node figex.js export <outDir> <listFile> <start> <count>
//   node figex.js call   <tool> <argsJsonFile>
//   node figex.js raw    <codeFile> <description>     (use_figma writes)
const fs = require('fs');
const os = require('os');
const path = require('path');
const dns = require('dns');
const https = require('https');

const FILE_KEY = 'uzTHnydXGeZSmImS5k2cLv';
function readToken() {
  const dir = path.join(os.homedir(), '.mcp-auth', 'mcp-remote-v1');
  const files = fs.existsSync(dir) ? fs.readdirSync(dir).filter(f => f.endsWith('_tokens.json')) : [];
  if (!files.length) {
    throw new Error('no Figma MCP token in ~/.mcp-auth/mcp-remote-v1: authenticate the Figma '
      + 'MCP through your MCP client once, then retry');
  }
  return JSON.parse(fs.readFileSync(path.join(dir, files[0]), 'utf8')).access_token;
}
const TOK = readToken();
const MCP = 'mcp.figma.com';
const log = s => console.log(s);
let SID = null;
const sleep = ms => new Promise(r => setTimeout(r, ms));

const resolver = new dns.Resolver();
resolver.setServers(['1.1.1.1', '8.8.8.8']);
const cache = {};
function lookup(hostname, options, cb) {
  const wantAll = options && options.all;
  const deliver = addrs => {
    if (wantAll) return cb(null, addrs.map(a => ({ address: a, family: 4 })));
    cb(null, addrs[0], 4);
  };
  if (cache[hostname] && cache[hostname].length) return deliver(cache[hostname]);
  resolver.resolve4(hostname, (e, addrs) => {
    if (e || !addrs || !addrs.length) return cb(e || new Error('no address for ' + hostname), null, 4);
    cache[hostname] = addrs;
    deliver(addrs);
  });
}
function request(url, opts = {}) {
  const u = new URL(url);
  const body = opts.body || null;
  const headers = Object.assign({}, opts.headers);
  if (body) headers['Content-Length'] = Buffer.byteLength(body);
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: u.hostname, port: u.port || 443, path: u.pathname + u.search,
      method: opts.method || 'GET', headers, lookup, timeout: 120000
    }, res => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, buffer: Buffer.concat(chunks) }));
    });
    req.on('timeout', () => req.destroy(new Error('timeout')));
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}
function parseSSE(txt) {
  const out = [];
  for (const block of txt.split(/\r?\n\r?\n/)) {
    const data = block.split(/\r?\n/).filter(l => l.startsWith('data:')).map(l => l.slice(5).trim()).join('');
    if (data) out.push(data);
  }
  return out;
}
async function post(bodyObj) {
  const headers = { 'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream', 'Authorization': 'Bearer ' + TOK };
  if (SID) headers['mcp-session-id'] = SID;
  const r = await request('https://' + MCP + '/mcp', { method: 'POST', headers, body: JSON.stringify(bodyObj) });
  if (r.headers['mcp-session-id']) SID = r.headers['mcp-session-id'];
  const txt = r.buffer.toString('utf8');
  if (r.status >= 400) throw new Error('HTTP ' + r.status + ' ' + txt.slice(0, 200));
  if (!txt.trim()) return null;
  const parts = parseSSE(txt);
  const raw = parts.length ? parts[parts.length - 1] : txt;
  if (!raw.trim()) return null;
  let j;
  try { j = JSON.parse(raw); } catch (e) { throw new Error('bad response (' + r.status + '): ' + txt.slice(0, 200)); }
  if (j.error) throw new Error('RPC ' + JSON.stringify(j.error).slice(0, 300));
  return j.result;
}
async function init() {
  SID = null;
  await post({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'sf-export', version: '1' } } });
  await post({ jsonrpc: '2.0', method: 'notifications/initialized' });
}
async function toolCall(name, args) {
  const res = await post({ jsonrpc: '2.0', id: 2, method: 'tools/call', params: { name, arguments: args } });
  return (res.content || []).map(c => (c.type === 'text' ? c.text : JSON.stringify(c))).join('\n');
}
async function fetchFollow(url, depth) {
  const r = await request(url);
  if ([301, 302, 303, 307, 308].includes(r.status) && r.headers.location && (depth || 0) < 5) {
    const next = r.headers.location.startsWith('http') ? r.headers.location : new URL(r.headers.location, url).toString();
    return fetchFollow(next, (depth || 0) + 1);
  }
  return r;
}

async function exportFrames(fileKey, outDir, listFile, startArg, countArg) {
  const start = parseInt(startArg || '1', 10);
  const count = parseInt(countArg || '9999', 10);
  const lines = fs.readFileSync(listFile, 'utf8').trim().split('\n');
  const stop = Math.min(lines.length, start - 1 + count);
  let ok = 0, fail = 0;
  for (let i = start - 1; i < stop; i++) {
    const parts = lines[i].split('\t');
    const nodeId = parts[1], name = parts[2];
    const file = path.join(outDir, name + '.png');
    if (fs.existsSync(file) && fs.statSync(file).size > 1000) { log('skip   ' + name); ok++; continue; }
    let done = false;
    for (let a = 1; a <= 8 && !done; a++) {
      try {
        const text = await toolCall('download_assets', { fileKey, nodeId, defaultFormat: 'png', defaultScale: 2 });
        const m = text.match(/"url":\s*"([^"]+)"/);
        if (!m) throw new Error('no asset url in the response');
        const r = await fetchFollow(m[1], 0);
        if (r.status !== 200) throw new Error('download HTTP ' + r.status);
        if (r.buffer.slice(0, 4).toString('binary') !== '\x89PNG') throw new Error('not a PNG');
        fs.writeFileSync(file, r.buffer);
        log('ok     ' + name + ' ' + r.buffer.length + ' bytes');
        ok++; done = true;
      } catch (e) {
        log('retry  ' + name + ' attempt ' + a + ': ' + e.message);
        await sleep(1200 * a);
        try { await init(); } catch (_) { /* the next attempt re-initialises */ }
      }
    }
    if (!done) { fail++; log('FAIL   ' + name); }
    await sleep(120);
  }
  log('SUMMARY ok=' + ok + ' fail=' + fail + ' frames=' + (stop - start + 1));
}

async function main() {
  const argv = process.argv.slice(2);
  const mode = argv[0], fileKey = argv[1], rest = argv.slice(2);
  if (mode === 'pages') {
    await init();
    const code = "const out = []; for (const p of figma.root.children) { await p.loadAsync(); out.push(p.id + '\\t' + p.name + '\\tchildren=' + p.children.length); } return out.join('\\n');";
    console.log(await toolCall('use_figma', { fileKey, code, description: 'List the pages of the file', skillNames: 'figma-use' }));
    return;
  }
  if (mode === 'call') {
    await init();
    console.log(await toolCall(rest[0], JSON.parse(fs.readFileSync(rest[1], 'utf8'))));
    return;
  }
  if (mode === 'script') {
    await init();
    const code = fs.readFileSync(rest[0], 'utf8');
    console.log(await toolCall('use_figma', { fileKey, code, description: rest[1] || 'StudyForge script', skillNames: 'figma-use' }));
    return;
  }
  if (mode === 'export') {
    await init();
    await exportFrames(fileKey, rest[0], rest[1], rest[2], rest[3]);
    return;
  }
  console.log('usage: node tools/figma-cli.js pages|call|script|export <fileKey> ...');
  process.exitCode = 2;
}

main().catch(e => { console.error('ERROR ' + e.message); process.exitCode = 1; });
