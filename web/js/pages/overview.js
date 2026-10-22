// Page 1: Executive overview. No filters, as in the Power BI report.

import { measure, rs11, rs6 } from '../metrics.js';
import { hbar } from '../charts.js';
import { card, cards, grid, h, panel } from '../ui.js';
import { disclosurePanel, pctAxis, pct, sensitivityPanel } from './common.js';

export function render({ d, el, after }) {
  const f = {};
  const m = (name, params) => measure(d, name, f, params);
  const awards = m('[Eligible Awards (n)]');
  const compN = m('[Competition n (primary)]');

  el.append(cards([
    card({ title: 'Procurement processes in scope', value: m('[Processes (n)]'), measure: '[Processes (n)]' }),
    card({ title: 'Planned budget (NGN)', value: m('[Planned Budget (NGN)]'), unit: 'NGN', n: m('[Budget Lines (n)]'), measure: '[Planned Budget (NGN)]' }),
    card({ title: 'Awarded value (NGN)', value: m('[Award Value (NGN)]'), unit: 'NGN', n: awards, measure: '[Award Value (NGN)]' }),
    card({ title: 'Median award value (NGN)', value: m('[Median Award Value (NGN)]'), unit: 'NGN', n: awards, measure: '[Median Award Value (NGN)]' }),
    card({ title: 'Share of tenders with a single bidder', value: m('[Single-Bidder Rate (primary)]'), unit: 'share', n: compN, measure: '[Single-Bidder Rate (primary)]' }),
    card({ title: 'Median number of tenderers', value: m('[Median Tenderers (primary)]'), unit: 'median', n: compN, measure: '[Median Tenderers (primary)]' }),
    card({ title: 'Share of awarded value held by the 10 largest suppliers', value: m('[Top N Supplier Share]', { n: 10 }), unit: 'share',
      n: m('[M-S01 Eligible Awards]'), measure: '[Top N Supplier Share]', params: { n: 10 } }),
    card({ title: 'Median awarded value as a multiple of planned budget', value: m('[Median Award-to-Budget Ratio]'), unit: 'ratio',
      n: m('[Comparable OCIDs]'), measure: '[Median Award-to-Budget Ratio]' }),
    card({ title: 'Median tender open duration (days)', value: m('[Median Tender Duration (days)]'), unit: 'days', n: m('[Tender Duration n]'),
      measure: '[Median Tender Duration (days)]', timing: true }),
    card({ title: 'Median days from tender start to award', value: m('[Median Award Lag (days)]'), unit: 'days', n: m('[Award Lag n]'),
      measure: '[Median Award Lag (days)]', timing: true }),
    card({ title: 'Contracts with implementation data published', value: m('[Implementation Coverage Rate]'), unit: 'share',
      n: m('[Contracts (n)]'), measure: '[Implementation Coverage Rate]', timing: true }),
    card({ title: 'Processes published only at planning stage', value: m('[Planning-Only Share]'), unit: 'share',
      n: m('[Processes (n)]'), measure: '[Planning-Only Share]', timing: true }),
  ]));

  const reg = d.registers.metric_population;
  const ci = reg.cols.indexOf('candidate_count');
  const ei = reg.cols.indexOf('eligible_count');
  const ni = reg.cols.indexOf('metric_name');
  const metrics = reg.rows.map((r) => ({ name: r[ni], share: r[ei] / r[ci], e: r[ei], c: r[ci] })).sort((a, b) => b.share - a.share);
  const chartEl = h('div', { class: 'chart tall' });

  const [s6pub, s6wo] = rs6(d);
  const [s11pub, s11wo] = rs11(d);
  el.append(grid('wide-left',
    panel('Share of candidate records that are eligible for each metric', 'Eligible records as a share of the candidate records of each metric (population register)', chartEl),
    disclosurePanel(d, f)));
  el.append(sensitivityPanel(d, [
    { figure: 'Share of awarded value held by the 10 largest suppliers (01 RS6)', pub: `${s6pub[6]}%`, wo: `${s6wo[6]}%` },
    { figure: 'Median awarded value as a multiple of planned budget (03 RS11)', pub: s11pub[6], wo: s11wo[6] },
  ]));

  after(() => hbar(chartEl, 'Eligible share of candidate records by metric', metrics.map((x) => x.name), metrics.map((x) => x.share),
    (v, axis) => (axis ? pctAxis(v) : pct(v)), { max: 1,
      tooltip: (i) => `${metrics[i].name}\n${pct(metrics[i].share)} (${metrics[i].e.toLocaleString('en')} of ${metrics[i].c.toLocaleString('en')})` }));
}
