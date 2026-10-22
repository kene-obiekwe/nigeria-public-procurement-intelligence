// Page 2b: Competition (M-C01, M-C02). Filters: entity, method. The entity tables use the precomputed entity KPIs
// (minimum 30 primary tenders), which carry no procurement method.

import { BANDS, measure } from '../metrics.js';
import { columns, hbar } from '../charts.js';
import { card, cards, caveat, entityControl, grid, h, methodControl, panel, table } from '../ui.js';
import { CAVEATS } from '../text.js';
import { compact, int, labelOf, pct, pctAxis } from './common.js';

const MIN_TENDERS = 30;

// Highest or lowest k entities by a KPI; entities tied with the k-th are all listed.
export function extremes(rowsIn, key, k, highest) {
  const sorted = [...rowsIn].sort((a, b) => (highest ? b[key] - a[key] : a[key] - b[key]) || (a.label < b.label ? -1 : 1));
  if (sorted.length <= k) return sorted;
  const cut = sorted[k - 1][key];
  return sorted.filter((r, i) => i < k || r[key] === cut);
}

export function render({ d, el, params, set, after }) {
  const f = { buyer: params.buyer ?? null, method: params.method ?? null };
  const m = (name, p) => measure(d, name, f, p);
  const nPrim = m('[Competition n (primary)]');

  el.append(h('div', { class: 'controls' },
    entityControl(d, f.buyer, (v) => set({ buyer: v })),
    methodControl(d, f.method, (v) => set({ method: v }))));

  el.append(cards([
    card({ title: 'Median number of tenderers', value: m('[Median Tenderers (primary)]'), unit: 'median', n: nPrim, measure: '[Median Tenderers (primary)]' }),
    card({ title: 'Share of tenders with a single bidder', value: m('[Single-Bidder Rate (primary)]'), unit: 'share', n: nPrim, measure: '[Single-Bidder Rate (primary)]' }),
    card({ title: 'Single-bidder share, including 101 to 1,000 tenderers', value: m('[Single-Bidder Rate (sensitivity)]'), unit: 'share',
      n: m('[Competition n (sensitivity)]'), measure: '[Single-Bidder Rate (sensitivity)]' }),
    card({ title: 'Eligible tenders (1 to 100 tenderers)', value: nPrim, measure: '[Competition n (primary)]' }),
  ]));

  const bands = BANDS.participation.map((name, i) => ({ name,
    n: m('[Tenders (n)] by [Participation Band]', { band: i + 1, population: i < 7 ? 1 : 0 }) }));
  const methods = (f.method ? [f.method] : d.methods).map((method) => ({ method,
    rate: measure(d, '[Single-Bidder Rate (primary)]', { ...f, method }),
    n: measure(d, '[Competition n (primary)]', { ...f, method }) })).filter((x) => x.n > 0).sort((a, b) => b.rate - a.rate);
  const bandEl = h('div', { class: 'chart' });
  const methodEl = h('div', { class: 'chart' });
  el.append(grid('two',
    panel('Tenders by number of tenderers', 'Last band is the sensitivity population only', bandEl),
    panel('Share of tenders with a single bidder, by procurement method', 'Primary population (1 to 100 tenderers); n in the tooltip', methodEl)));

  const e = d.entities;
  const ents = [];
  e.b.forEach((b, i) => {
    if (f.buyer != null && d.buyerIds[b] !== f.buyer) return;
    if ((e.competition_n[i] ?? 0) >= MIN_TENDERS && e.single_bidder_rate[i] != null) {
      ents.push({ label: labelOf(d, b), rate: e.single_bidder_rate[i], n: e.competition_n[i] });
    }
  });
  const cols = [
    { key: 'label', label: 'Procuring entity' },
    { key: 'rate', label: 'Single-bidder share', bar: true, format: (v) => pct(v) },
    { key: 'n', label: 'Tenders (n)', num: true, format: int },
  ];
  el.append(grid('two',
    panel(`Entities with the highest single-bidder share (at least ${MIN_TENDERS} tenders)`, 'Highest 10; entities tied at the cut-off are all listed',
      table(cols, extremes(ents, 'rate', 10, true), { cls: 'short', label: 'Highest single-bidder share' })),
    panel(`Entities with the lowest single-bidder share (at least ${MIN_TENDERS} tenders)`, 'Lowest 10; entities tied at the cut-off are all listed',
      table(cols, extremes(ents, 'rate', 10, false), { cls: 'short', label: 'Lowest single-bidder share' }))));
  el.append(caveat(CAVEATS.competition));

  after(() => {
    columns(bandEl, 'Tenders by number of tenderers', bands.map((b) => b.name), bands.map((b) => b.n), compact);
    hbar(methodEl, 'Single-bidder share by procurement method', methods.map((x) => x.method), methods.map((x) => x.rate),
      (v, axis) => (axis ? pctAxis(v) : pct(v)), { max: 1,
        tooltip: (i) => `${methods[i].method}\n${pct(methods[i].rate)} of ${methods[i].n.toLocaleString('en')} tenders` });
  });
}
