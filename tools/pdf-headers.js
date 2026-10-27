#!/usr/bin/env node
'use strict';
// tools/pdf-headers.js — print the print-ready HTML to PDF WITH a running header and page numbers.
//
// Why this exists: Chromium's command-line printer (`--print-to-pdf`) has no header-template flag,
// so `tools/build-pdf.sh` could not put the app name, the logo or page numbers on every page — the
// brief asks for exactly that, and the build script recorded it as a known gap. The DevTools
// Protocol *can* do it (`Page.printToPDF` takes `headerTemplate` and `footerTemplate`), so this
// drives the browser over CDP instead of the command line. Node's global WebSocket does the
// talking, so there is no npm dependency.
//
// Usage:
//   node tools/pdf-headers.js <htmlFile> <outPdf> [logoPng]
//
// The HTML is expected to be the print-ready page produced by `bash tools/build-pdf.sh --html <dir>`;
// its `@page` rule supplies the A4 size and the margins the header and footer render inside.

const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');

const [htmlArg, outArg, logoArg] = process.argv.slice(2);
if (!htmlArg || !outArg) {
  console.error('usage: node tools/pdf-headers.js <htmlFile> <outPdf> [logoPng]');
  process.exit(2);
}
const htmlFile = path.resolve(htmlArg);
const outFile = path.resolve(outArg);
if (!fs.existsSync(htmlFile)) { console.error('no such HTML: ' + htmlFile); process.exit(1); }

const CANDIDATES = [
  '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'
];
const browser = CANDIDATES.find(p => { try { fs.accessSync(p, fs.constants.X_OK); return true; } catch (e) { return false; } });
if (!browser) { console.error('no Chromium browser found in /Applications'); process.exit(1); }

// A small logo keeps the per-page header cheap: the header template is rendered on every page, so
// a 150 KB app icon would be embedded 190+ times. build-pdf.sh pre-shrinks it to ~16 px tall.
const logo = (logoArg && fs.existsSync(logoArg))
  ? '<img src="data:image/png;base64,' + fs.readFileSync(logoArg).toString('base64') + '" style="height:15px;vertical-align:middle;margin-right:6px;">'
  : '';

const header = '<div style="font-family:Helvetica,Arial,sans-serif;font-size:8px;color:#6E6E76;width:100%;padding:0 14mm;display:flex;align-items:center;justify-content:space-between;">'
  + '<span style="display:flex;align-items:center;">' + logo
  + '<span style="font-weight:700;color:#1F1F24;font-size:9px;">StudyForge</span></span>'
  + '<span>Turn any material into mastery.</span></div>';

const footer = '<div style="font-family:Helvetica,Arial,sans-serif;font-size:8px;color:#6E6E76;width:100%;padding:0 14mm;display:flex;justify-content:space-between;">'
  + '<span>StudyForge &mdash; Project Design Document</span>'
  + '<span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span></div>';

const sleep = ms => new Promise(r => setTimeout(r, ms));
const httpGet = url => new Promise((res, rej) => {
  http.get(url, r => { let b = ''; r.on('data', c => b += c); r.on('end', () => res(b)); }).on('error', rej);
});

(async () => {
  const port = 9200 + Math.floor(Math.random() * 300);
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'sfpdf-'));
  const child = spawn(browser, [
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--disable-sync', '--user-data-dir=' + profile, '--remote-debugging-port=' + port, 'about:blank'
  ], { stdio: 'ignore' });

  let wsUrl = null;
  const deadline = Date.now() + 30000;
  while (Date.now() < deadline && !wsUrl) {
    try {
      // /json/list gives the PAGE targets. /json/version gives the browser endpoint, where the
      // Page domain does not exist ("'Page.enable' wasn't found"), so the page target is the one
      // this script needs.
      const targets = JSON.parse(await httpGet('http://127.0.0.1:' + port + '/json/list'));
      const page = targets.find(t => t.type === 'page' && t.webSocketDebuggerUrl);
      if (page) wsUrl = page.webSocketDebuggerUrl;
    } catch (e) { /* the port is not up yet */ }
    if (!wsUrl) await sleep(300);
  }
  if (!wsUrl) { child.kill(); console.error('the browser never exposed a page target'); process.exit(1); }

  const sock = new WebSocket(wsUrl);
  const say = m => console.error('[pdf-headers] ' + m);
  say('page target: ' + wsUrl);
  let seq = 0;
  const pending = new Map();
  let loaded = false;
  const send = (method, params) => new Promise((res, rej) => {
    const id = ++seq;
    pending.set(id, { res, rej });
    sock.send(JSON.stringify({ id, method, params: params || {} }));
  });
  sock.addEventListener('message', ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) {
      const p = pending.get(m.id); pending.delete(m.id);
      m.error ? p.rej(new Error(JSON.stringify(m.error))) : p.res(m.result);
    } else if (m.method === 'Page.loadEventFired') { loaded = true; }
  });
  await Promise.race([
    new Promise((res, rej) => { sock.addEventListener('open', res); sock.addEventListener('error', rej); }),
    sleep(10000).then(() => { throw new Error('the debug socket never opened'); })
  ]);
  say('socket open');

  await send('Page.enable');
  say('page domain enabled');
  await send('Page.navigate', { url: 'file://' + htmlFile });
  const t0 = Date.now();
  while (!loaded && Date.now() - t0 < 60000) await sleep(200);
  say('loaded=' + loaded + ' after ' + Math.round((Date.now() - t0) / 1000) + 's');
  await sleep(2000); // let webfonts and figure images settle before printing
  say('printing...');

  // `transferMode: 'ReturnAsStream'` matters: the default returns the whole PDF as one base64
  // string inside a single WebSocket frame, and at ~26 MB that frame never arrives — the call
  // simply hangs with the browser and Node both idle. Stream mode hands back a handle and the
  // bytes are pulled in 1 MB chunks instead.
  const { stream } = await send('Page.printToPDF', {
    printBackground: true,
    preferCSSPageSize: true,   // honours the print stylesheet's `@page { size: A4; margin: ... }`
    displayHeaderFooter: true,
    headerTemplate: header,
    footerTemplate: footer,
    transferMode: 'ReturnAsStream',
    // Inches, not "15mm": CDP deserialises these as doubles, and a string is rejected with
    // "Failed to deserialize params.marginTop - BINDINGS: double value expected".
    marginTop: 0.5906,     // 15 mm, matching the @page rule
    marginBottom: 0.6693,  // 17 mm
    marginLeft: 0.5512,    // 14 mm
    marginRight: 0.5512    // 14 mm
  });
  const chunks = [];
  for (;;) {
    const r = await send('IO.read', { handle: stream, size: 1048576 });
    if (r.data) chunks.push(Buffer.from(r.data, 'base64'));
    if (r.eof) break;
  }
  try { await send('IO.close', { handle: stream }); } catch (e) { /* already closed */ }
  fs.writeFileSync(outFile, Buffer.concat(chunks));
  sock.close();
  child.kill();
  console.log('wrote ' + path.relative(process.cwd(), outFile) + ' (' + fs.statSync(outFile).size + ' bytes)');
  process.exit(0);
})().catch(e => { console.error('ERROR ' + e.message); process.exit(1); });
