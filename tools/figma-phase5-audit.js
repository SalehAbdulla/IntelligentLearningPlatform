/**
 * figma-phase5-audit.js — the Phase 5 measurements behind docs/01 §8, re-runnable.
 *
 * THIS IS NOT A NODE SCRIPT. It is Plugin API code, run inside Figma through the committed CLI:
 *
 *   node tools/figma-cli.js script uzTHnydXGeZSmImS5k2cLv \
 *     tools/figma-phase5-audit.js "the Phase 5 re-measurement"
 *
 * It only READS. Nothing is written to the document, and it needs no writes to answer anything
 * below. The numbers it prints are the ones quoted in `deliverables/prototype/figma-audit.md`
 * §Phase 5 and in the verdicts in `docs/01` §8 — committed so they can be reproduced rather than
 * believed, which is the same standard the rest of that audit is held to.
 *
 * WHY IT EXISTS. The Phase 5 block carried 16 unticked boxes while the audit reported PASSes and
 * `prototype-v1` was tagged. Nobody could tell which was right, so the block was measured instead
 * of argued about — and the measurement found two items genuinely unfinished (P5-14 Smart Animate,
 * P5-01's component library) that no amount of reading the checklists would have surfaced.
 *
 * THE ONE TRAP, recorded because it cost an hour: the frame numbering is `NN_` for `01`–`99` and
 * `NNN_` for `100`+, so a `/^\d{3}_/` filter silently matches only the 100+ screens and reports 42
 * of 123. The rule is `/^\d{2,3}_/`. And the screens live INSIDE a `SECTION`, so a page's direct
 * children are not the screens — `findAll` is required.
 */

const out = {};
const byName = {};
for (const p of figma.root.children) byName[p.name] = p;

const NAME = /^\d{2,3}_[A-Za-z0-9_]+_\d{9}$/;
const num = n => parseInt(n.name.slice(0, 3).replace(/[^0-9]/g, ''), 10);

// ── the screen set, and M1's four groups ───────────────────────────────────
const screens = byName['3 · Screens (all features)'];
await figma.setCurrentPageAsync(screens);
const numbered = screens.findAll(n => n.type === 'FRAME' && NAME.test(n.name));

out.screens = { total: numbered.length, framesOnPage: screens.findAll(n => n.type === 'FRAME').length };
out.numbers = numbered.map(num).sort((a, b) => a - b);

const group = (label, lo, hi) => {
  const set = numbered.filter(f => { const n = num(f); return n >= lo && n <= hi; });
  return {
    label,
    count: set.length,
    standard: set.filter(f => Math.round(f.width) === 390 && Math.round(f.height) === 844).length,
    numbers: set.map(num).sort((a, b) => a - b),
  };
};
out.groupA = group('A', 1, 10);
out.groupB = group('B', 11, 23);
out.groupC = group('C', 24, 34);
out.groupM = group('M', 128, 141);

// ── overflow (P5-12) and the frames tall enough for it to matter ───────────
const overflow = {};
for (const f of numbered) {
  const d = f.overflowDirection || 'NONE';
  overflow[d] = (overflow[d] || 0) + 1;
}
out.overflow = overflow;
out.tallest = numbered
  .map(f => ({ name: f.name, h: Math.round(f.height) }))
  .sort((a, b) => b.h - a.h)
  .slice(0, 3);

// ── transitions (P5-14), with "no transition object" told apart from "instant" ──
let withTransition = 0;
let nullTransition = 0;
const types = {};
const walk = n => {
  if (n.reactions) {
    for (const r of n.reactions) {
      if (r.transition) {
        withTransition += 1;
        const t = r.transition.type || 'UNSET';
        types[t] = (types[t] || 0) + 1;
      } else {
        nullTransition += 1;
      }
    }
  }
  if (n.children) for (const c of n.children) walk(c);
};
for (const c of screens.children) walk(c);
out.transitions = { withTransition, nullTransition, types };

// ── the design system (P5-01, P5-02) ───────────────────────────────────────
const ds = byName['1 · Design System'];
await figma.setCurrentPageAsync(ds);
const dsAll = ds.findAll(() => true);
out.designSystem = {
  boards: ds.children.map(c => c.name),
  frames: dsAll.filter(n => n.type === 'FRAME').length,
  components: dsAll.filter(n => n.type === 'COMPONENT').length,
  componentSets: dsAll.filter(n => n.type === 'COMPONENT_SET').length,
  boundNodes: dsAll.filter(n => n.boundVariables && Object.keys(n.boundVariables).length).length,
};
out.variables = (await figma.variables.getLocalVariableCollectionsAsync())
  .map(c => ({ name: c.name, count: c.variableIds.length, modes: c.modes.map(m => m.name) }));
out.styles = {
  text: (await figma.getLocalTextStylesAsync()).length,
  effect: (await figma.getLocalEffectStylesAsync()).length,
  paint: (await figma.getLocalPaintStylesAsync()).length,
};

// ── the cover page (P5-15) ────────────────────────────────────────────────
const cover = byName['0 · Cover & Legend'];
await figma.setCurrentPageAsync(cover);
out.cover = {
  frames: cover.findAll(n => n.type === 'FRAME').map(n => n.name),
  nodes: cover.findAll(() => true).length,
};

return out;
