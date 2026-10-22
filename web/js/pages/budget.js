// Page 3: Budget versus award. Filters: entity, method.

import { BANDS, measure, rs11, sumBig, median, divide } from '../metrics.js';
import { rows as filterRows, pick } from '../data.js';
import { columns } from '../charts.js';
import { card, cards, caveat, controlBar, entityControl, grid, h, methodControl, panel, table } from '../ui.js';
import { CAVEATS } from '../text.js';
import { compact, dec, int, labelOf, ngn, sensitivityPanel } from './common.js';

const MIN_PROCESSES = 10;

export function render({ d, el, params, set, after }) {
  const f = { buyer: params.buyer ?? null, method: params.method ?? null };
  const m = (name, p) => measure(d, name, f, p);
  const n = m('[Comparable OCIDs]');

  el.append(controlBar(
    entityControl(d, f.buyer, (v) => set({ buyer: v })),
    methodControl(d, f.method, (v) => set({ method: v }))));

  el.append(cards([
    card({ title: 'Processes with an award and one budget line', value: n, measure: '[Comparable OCIDs]' }),
    card({ title: 'Awarded value as a multiple of planned budget (total)', value: m('[Aggregate Award-to-Budget Ratio]'), unit: 'ratio', n,
      measure: '[Aggregate Award-to-Budget Ratio]' }),
    card({ title: 'Awarded value as a multiple of planned budget (median)', value: m('[Median Award-to-Budget Ratio]'), unit: 'ratio', n,
      measure: '[Median Award-to-Budget Ratio]' }),
    card({ title: 'Share of processes with awarded value within 10% of budget', value: m('[Share Within 10% of Budget]'), unit: 'share', n,
      measure: '[Share Within 10% of Budget]' }),
    card({ title: 'Processes with a budget under NGN 100,000', value: m('[OCIDs With Budget Under 100k]'), n,
      measure: '[OCIDs With Budget Under 100k]' }),
  ], 'five'));

  const bands = BANDS.ratio.map((name, i) => ({ name, n: m('[Comparable OCIDs] by [Ratio Band]', { band: i + 1 }) }));
  const t = d.budget_award;
  const methodRows = (f.method ? [f.method] : d.methods).map((method) => {
    const idx = filterRows(d, 'budget_award', { ...f, method });
    const bud = sumBig(pick(t.bud, idx));
    const aw = sumBig(pick(t.aw, idx));
    return { method, n: idx.length, bud, aw, total: divide(aw, bud), med: median(pick(t.r, idx)) };
  }).filter((r) => r.n > 0).sort((a, b) => b.n - a.n);

  const bandEl = h('div', { class: 'chart' });
  el.append(grid('two',
    panel('Processes by awarded value as a multiple of planned budget', null, bandEl),
    panel('By procurement method', 'Largest first; the table scrolls to show every method',
      table([
        { key: 'method', label: 'Procurement method' },
        { key: 'n', label: 'Processes (n)', num: true, format: int },
        { key: 'bud', label: 'Budget (NGN)', num: true, format: ngn },
        { key: 'aw', label: 'Award (NGN)', num: true, format: ngn },
        { key: 'total', label: 'Total ratio', num: true, format: dec(4) },
        { key: 'med', label: 'Median ratio', num: true, format: dec(4) },
      ], methodRows, { cls: 'short', label: 'Budget versus award by procurement method' }))));

  // Net difference (award minus budget) by entity, entities with at least 10 comparable processes.
  const idx = filterRows(d, 'budget_award', f);
  const byBuyer = new Map();
  for (const i of idx) {
    const cur = byBuyer.get(t.b[i]) ?? { diff: 0n, n: 0 };
    cur.diff += BigInt(t.aw[i]) - BigInt(t.bud[i]);
    cur.n += 1;
    byBuyer.set(t.b[i], cur);
  }
  const ents = [...byBuyer.entries()].filter(([, v]) => v.n >= MIN_PROCESSES).map(([b, v]) => ({ label: labelOf(d, b), diff: v.diff, n: v.n }));
  const pos = ents.filter((x) => x.diff > 0n).sort((a, b) => (b.diff > a.diff ? 1 : -1)).slice(0, 15);
  const neg = ents.filter((x) => x.diff < 0n).sort((a, b) => (a.diff > b.diff ? 1 : -1)).slice(0, 15);
  const cols = [
    { key: 'label', label: 'Procuring entity' },
    { key: 'diff', label: 'Difference (NGN)', bar: true, format: ngn },
    { key: 'n', label: 'Processes (n)', num: true, format: int },
  ];
  el.append(grid('two',
    panel(`Entities with the largest positive difference (award minus budget; at least ${MIN_PROCESSES} processes)`, 'Largest 15',
      table(cols, pos, { cls: 'short', label: 'Largest positive difference' })),
    panel(`Entities with the largest negative difference (award minus budget; at least ${MIN_PROCESSES} processes)`, 'Largest 15',
      table(cols, neg, { cls: 'short', label: 'Largest negative difference' }))));
  el.append(caveat(CAVEATS.budget), caveat(CAVEATS.budgetOver10));

  const [pub, wo] = rs11(d);
  const label = ['', 'Processes with an award and one budget line', '', 'Planned budget of these processes (NGN bn)',
    'Awarded value of these processes (NGN bn)', 'Awarded value as a multiple of planned budget (total)',
    'Awarded value as a multiple of planned budget (median)', 'Processes above 10 times budget', 'Awarded value above 10 times budget (NGN bn)',
    'Share of awarded value above 10 times budget'];
  el.append(sensitivityPanel(d, [1, 3, 4, 5, 6, 7, 8, 9].map((i) => ({ figure: `${label[i]} (03 RS11)`,
    pub: i === 9 ? `${pub[i]}%` : (i === 1 || i === 7 ? int(Number(pub[i])) : String(pub[i])),
    wo: i === 9 ? `${wo[i]}%` : (i === 1 || i === 7 ? int(Number(wo[i])) : String(wo[i])) }))));

  after(() => columns(bandEl, 'Processes by awarded value as a multiple of planned budget', bands.map((b) => b.name), bands.map((b) => b.n), compact));
}
