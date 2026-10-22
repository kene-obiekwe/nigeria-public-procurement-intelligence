// Page 2a: Supplier concentration (M-S01). Filters: entity, method, Top N.

import { measure, rs6, rs6b, ranked, supplierValues, supplierRows, sumBig, topNSum, divide, groupCount } from '../metrics.js';
import { pick } from '../data.js';
import { hbar } from '../charts.js';
import { int as intParam } from '../state.js';
import { card, cards, controlBar, entityControl, grid, h, methodControl, panel, table, topNControl } from '../ui.js';
import { disclosurePanel, int, ngn, pct, pctAxis, sensitivityPanel } from './common.js';

export function render({ d, el, params, set, after }) {
  const f = { buyer: params.buyer ?? null, method: params.method ?? null };
  const n = intParam(params, 'topn', 10);
  const m = (name, p) => measure(d, name, f, p);
  const eligible = m('[M-S01 Eligible Awards]');

  el.append(controlBar(
    entityControl(d, f.buyer, (v) => set({ buyer: v })),
    methodControl(d, f.method, (v) => set({ method: v })),
    topNControl(n, (v) => set({ topn: v === 10 ? null : v }))));

  el.append(cards([
    card({ title: 'Awards with a usable supplier ID', value: eligible, measure: '[M-S01 Eligible Awards]' }),
    card({ title: 'Suppliers identified by source ID', value: m('[Suppliers (n)]'), n: eligible, measure: '[Suppliers (n)]' }),
    card({ title: `Share of awarded value held by the ${n} largest suppliers`, value: m('[Top N Supplier Share]', { n }), unit: 'share',
      n: eligible, measure: '[Top N Supplier Share]', params: { n } }),
    card({ title: 'Herfindahl index (0 to 10,000)', value: m('[Supplier HHI]'), unit: 'index', n: eligible, measure: '[Supplier HHI]' }),
    card({ title: 'Suppliers with exactly one award', value: m('[Suppliers With One Award]'), n: m('[Suppliers (n)]'), measure: '[Suppliers With One Award]' }),
  ], 'five'));

  // Top-20 table: rank (RANKX, skip), share and cumulative share relative to every supplier in the filter (P-12).
  const values = supplierValues(d, f);
  const total = sumBig(values.values());
  const awardsPer = groupCount(pick(d.awards.s, supplierRows(d, f)));
  const order = ranked(values, (s) => d.suppliers.id[s]);
  const rows = [];
  let cumulative = 0n;
  let rank = 0;
  order.forEach(([s, v], i) => {
    if (i === 0 || order[i - 1][1] !== v) rank = i + 1;
    cumulative += v;
    if (rank <= 20) {
      rows.push({ rank, id: d.suppliers.id[s], name: d.suppliers.name[s] + (d.suppliers.variants[s] > 1 ? ` (${d.suppliers.variants[s]} name variants)` : ''),
        awards: awardsPer.get(s), value: v, share: divide(v, total), cum: divide(cumulative, total) });
    }
  });

  // N largest suppliers' share, by method (entity filter applies; the method filter narrows the list).
  const byMethod = (f.method ? [f.method] : d.methods).map((method) => {
    const vals = [...supplierValues(d, { ...f, method }).values()];
    return { method, share: vals.length ? divide(topNSum(vals, n), sumBig(vals)) : null };
  }).filter((x) => x.share != null).sort((a, b) => b.share - a.share);
  const methodEl = h('div', { class: 'chart tall' });

  el.append(grid('wide-left',
    panel('20 largest suppliers by awarded value', 'Supplier ID and name as published; suppliers are not merged on name similarity. Suppliers tied on value share a rank.',
      table([
        { key: 'rank', label: 'Rank', num: true },
        { key: 'id', label: 'Supplier ID' },
        { key: 'name', label: 'Supplier name' },
        { key: 'awards', label: 'Awards', num: true, format: int },
        { key: 'value', label: 'Value (NGN)', bar: true, format: ngn },
        { key: 'share', label: 'Share of value', num: true, format: (v) => pct(v) },
        { key: 'cum', label: 'Cumulative share', num: true, format: (v) => pct(v) },
      ], rows, { cls: 'tall', label: '20 largest suppliers' })),
    h('div', {},
      panel(`Share of value held by the ${n} largest suppliers, by method`,
        'Suppliers tied at the cut-off are all included, so a share can cover more than N suppliers.', methodEl),
      disclosurePanel(d, f))));

  const [pub, wo] = rs6(d);
  const label = ['', 'Awards with a usable supplier ID', '', 'Value attributed to suppliers (NGN bn)', 'Share held by the largest supplier',
    'Share held by the 5 largest suppliers', 'Share held by the 10 largest suppliers', 'Share held by the 100 largest suppliers',
    'Herfindahl index (0 to 10,000)', 'Largest supplier', 'Largest supplier value (NGN bn)'];
  const rowsS = [1, 3, 4, 5, 6, 7, 8, 9, 10].map((i) => ({ figure: `${label[i]} (01 RS6)`,
    pub: i >= 4 && i <= 7 ? `${pub[i]}%` : (i === 1 ? int(Number(pub[i])) : String(pub[i])),
    wo: i >= 4 && i <= 7 ? `${wo[i]}%` : (i === 1 ? int(Number(wo[i])) : String(wo[i])) }));
  const methodRows = rs6b(d).map((r) => ({ method: r[0], flagged: r[1], t1p: `${r[4]}%`, t1w: r[5] == null ? '' : `${r[5]}%`, hp: r[6], hw: r[7] }));
  el.append(sensitivityPanel(d, rowsS, h('div', {},
    h('p', { class: 'sub', text: 'By procurement method (01 RS6b): share held by the largest supplier and Herfindahl index' }),
    table([
      { key: 'method', label: 'Procurement method' },
      { key: 'flagged', label: 'Flagged awards', num: true },
      { key: 't1p', label: 'Largest supplier, as published', num: true },
      { key: 't1w', label: 'Largest supplier, without flagged', num: true },
      { key: 'hp', label: 'Herfindahl, as published', num: true },
      { key: 'hw', label: 'Herfindahl, without flagged', num: true },
    ], methodRows, { cls: 'free', label: 'DQ-21 sensitivity by method' }))));

  after(() => hbar(methodEl, `Share of value held by the ${n} largest suppliers, by procurement method`,
    byMethod.map((x) => x.method), byMethod.map((x) => x.share), (v, axis) => (axis ? pctAxis(v) : pct(v)), { max: 1 }));
}
