// Page 4: Procurement-cycle timing. Filters: entity, method, tender start year (tender duration), award year (award
// lag). Signature lag carries no method or year; the coverage cards come from the population register (no filter).

import { BANDS, measure, bandDays, median } from '../metrics.js';
import { rows as filterRows, pick } from '../data.js';
import { columns, line } from '../charts.js';
import { int as intParam } from '../state.js';
import { card, cards, caveat, entityControl, grid, h, methodControl, panel, selectControl, table } from '../ui.js';
import { CAVEATS } from '../text.js';
import { compact, dec, int, pct } from './common.js';

function years(col) {
  return [...new Set(col)].sort((a, b) => a - b);
}

function bandCounts(values) {
  const c = [0, 0, 0, 0, 0, 0];
  for (const v of values) c[bandDays(v) - 1] += 1;
  return c;
}

function byYear(table, idx) {
  const groups = new Map();
  for (const i of idx) {
    const y = table.y[i];
    if (!groups.has(y)) groups.set(y, []);
    groups.get(y).push(table.d[i]);
  }
  const ys = [...groups.keys()].sort((a, b) => a - b);
  return { ys, med: ys.map((y) => median(groups.get(y))), n: ys.map((y) => groups.get(y).length) };
}

export function render({ d, el, params, set, after }) {
  const tsy = intParam(params, 'tyear', null);
  const ay = intParam(params, 'ayear', null);
  const base = { buyer: params.buyer ?? null, method: params.method ?? null };
  const ftd = { ...base, tenderStartYear: tsy };
  const fal = { ...base, awardYear: ay };
  const fsl = { buyer: base.buyer };

  el.append(h('div', { class: 'controls' },
    entityControl(d, base.buyer, (v) => set({ buyer: v })),
    methodControl(d, base.method, (v) => set({ method: v })),
    selectControl('Tender start year (tender duration)', [['', 'All'], ...years(d.tender_duration.y).map((y) => [y, String(y)])], tsy ?? '',
      (v) => set({ tyear: v || null })),
    selectControl('Award year (award lag)', [['', 'All'], ...years(d.award_lag.y).map((y) => [y, String(y)])], ay ?? '',
      (v) => set({ ayear: v || null }))));

  const cov = (name) => measure(d, name, {});
  el.append(cards([
    card({ title: 'Median tender open duration (days)', value: measure(d, '[Median Tender Duration (days)]', ftd), unit: 'days',
      n: measure(d, '[Tender Duration n]', ftd), measure: '[Median Tender Duration (days)]', timing: true }),
    card({ title: 'Median days from tender start to award', value: measure(d, '[Median Award Lag (days)]', fal), unit: 'days',
      n: measure(d, '[Award Lag n]', fal), measure: '[Median Award Lag (days)]', timing: true }),
    card({ title: 'Median days from award to signature', value: measure(d, '[Median Signature Lag (days)]', fsl), unit: 'days',
      n: measure(d, '[Signature Lag n]', fsl), measure: '[Median Signature Lag (days)]', timing: true }),
    card({ title: 'Share of tenders with valid dates', value: cov('[Coverage M-E01]'), unit: 'share', measure: '[Coverage M-E01]' }),
    card({ title: 'Share of processes with valid dates (award lag)', value: cov('[Coverage M-E02]'), unit: 'share', measure: '[Coverage M-E02]' }),
    card({ title: 'Share of contracts with valid dates (signature lag)', value: cov('[Coverage Signature Lag]'), unit: 'share',
      measure: '[Coverage Signature Lag]' }),
  ], 'six'));

  const td = d.tender_duration;
  const al = d.award_lag;
  const sl = d.signature_lag;
  const tdIdx = filterRows(d, 'tender_duration', ftd);
  const alIdx = filterRows(d, 'award_lag', fal);
  const slIdx = filterRows(d, 'signature_lag', fsl);
  const charts = [
    ['Tenders by open duration', bandCounts(pick(td.d, tdIdx))],
    ['Processes by days from tender start to award', bandCounts(pick(al.d, alIdx))],
    ['Contracts by days from award to signature', bandCounts(pick(sl.d, slIdx))],
  ].map(([title, counts]) => ({ title, counts, el: h('div', { class: 'chart short' }) }));
  el.append(grid('three', charts.map((c) => panel(c.title, null, c.el))));

  const tdYear = byYear(td, tdIdx);
  const alYear = byYear(al, alIdx);
  const tdYearEl = h('div', { class: 'chart short' });
  const alYearEl = h('div', { class: 'chart short' });
  const methodRows = (base.method ? [base.method] : d.methods).map((method) => {
    const ti = filterRows(d, 'tender_duration', { ...ftd, method });
    const ai = filterRows(d, 'award_lag', { ...fal, method });
    return { method, tn: ti.length, tm: median(pick(td.d, ti)), an: ai.length, am: median(pick(al.d, ai)) };
  }).filter((r) => r.tn + r.an > 0).sort((a, b) => b.tn - a.tn);
  el.append(grid('three',
    panel('Median tender open duration (days), by tender start year', 'n of each year in the tooltip', tdYearEl),
    panel('Median days from tender start to award, by award year', 'n of each year in the tooltip', alYearEl),
    panel('By procurement method', 'Largest first; the table scrolls to show every method',
      table([
        { key: 'method', label: 'Method' },
        { key: 'tn', label: 'Tenders (n)', num: true, format: int },
        { key: 'tm', label: 'Median days', num: true, format: dec(1) },
        { key: 'an', label: 'Processes (n)', num: true, format: int },
        { key: 'am', label: 'Median days to award', num: true, format: dec(1) },
      ], methodRows, { cls: 'short', label: 'Timing by procurement method' }))));

  const timingCaveat = `Valid dates exist for ${pct(cov('[Coverage M-E01]'), 0)} of tenders (tender duration), `
    + `${pct(cov('[Coverage M-E02]'), 0)} of processes (award lag) and ${pct(cov('[Coverage Signature Lag]'), 0)} of contracts `
    + '(signature lag). Missing dates are reporting gaps, not delays. Results describe only the processes that published valid dates.';
  el.append(caveat(timingCaveat), caveat(CAVEATS.timing));

  after(() => {
    charts.forEach((c) => columns(c.el, c.title, BANDS.duration, c.counts, compact));
    line(tdYearEl, 'Median tender open duration by tender start year', tdYear.ys, tdYear.med, tdYear.n, dec(1));
    line(alYearEl, 'Median days from tender start to award by award year', alYear.ys, alYear.med, alYear.n, dec(1));
  });
}
