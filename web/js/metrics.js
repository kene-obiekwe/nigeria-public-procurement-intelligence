// Pure functions that mirror the Power BI DAX measures (dashboard/README.md §5) over the decoded web data.
//
// Every measure takes (d, filter, params) and recomputes from the rows that pass the filter, so medians,
// percentiles, Top N shares and distinct counts stay exact under any filter. Money is BigInt kobo; NGN medians are
// Number kobo (they can fall between two values). Shares and ratios are Numbers; rounding happens only on display.

import { rows, pick, buyerId } from './data.js';
import { decimalToScaled, koboToBillions, percentOf, roundDiv, roundTo, scaledToString } from './format.js';

// ---------------------------------------------------------------- helpers

export function sumBig(values) {
  let s = 0n;
  for (const v of values) s += BigInt(v);
  return s;
}

// DAX MEDIAN / PERCENTILE.INC = SQL percentile_cont: linear interpolation between the closest ranks.
export function percentileInc(values, p) {
  if (!values.length) return null;
  const v = Float64Array.from(values).sort();
  const pos = p * (v.length - 1);
  const lo = Math.floor(pos);
  return lo + 1 >= v.length ? v[lo] : v[lo] + (v[lo + 1] - v[lo]) * (pos - lo);
}

export function median(values) {
  return percentileInc(values, 0.5);
}

// DIVIDE: blank when the denominator is zero or blank. BigInt operands are divided in floating point, which keeps
// 15 to 16 significant digits, ample for a share or ratio shown at four decimals.
export function divide(a, b) {
  if (b == null || a == null || Number(b) === 0) return null;
  return Number(a) / Number(b);
}

// Sum of the n largest values (BigInt); as DAX TOPN, every value tied with the n-th is included.
export function topNSum(values, n) {
  const v = [...values].sort((x, y) => (x < y ? 1 : x > y ? -1 : 0));
  if (v.length <= n) return sumBig(v);
  const cut = v[n - 1];
  return sumBig(v.filter((x) => x >= cut));
}

// Map key -> BigInt sum.
export function groupSum(keys, values) {
  const m = new Map();
  keys.forEach((k, i) => m.set(k, (m.get(k) ?? 0n) + BigInt(values[i])));
  return m;
}

export function groupCount(keys) {
  const m = new Map();
  for (const k of keys) m.set(k, (m.get(k) ?? 0) + 1);
  return m;
}

// Herfindahl index (0 to 10,000) of a map of values: 10,000 x sum of squared shares, exact in BigInt.
export function hhi(values) {
  const v = [...values];
  const tot = sumBig(v);
  if (tot === 0n) return null;
  let sq = 0n;
  for (const x of v) sq += BigInt(x) * BigInt(x);
  return Number(roundDiv(sq * 10000n * 10n ** 6n, tot * tot)) / 1e6;
}

// row_number() OVER (ORDER BY value DESC, id): entries of a Map in rank order.
export function ranked(map, idOf) {
  return [...map.entries()].sort((a, b) => (a[1] < b[1] ? 1 : a[1] > b[1] ? -1 : idOf(a[0]) < idOf(b[0]) ? -1 : 1));
}

export function bandTenderers(t) {
  const cuts = [1, 2, 5, 10, 20, 50, 100];
  const i = cuts.findIndex((hi) => t <= hi);
  return i < 0 ? 8 : i + 1;
}

export function bandRatio(r) {
  if (r < 0.5) return 1;
  if (r < 0.9) return 2;
  if (r <= 1.1) return 3;
  if (r <= 1.5) return 4;
  return r <= 10 ? 5 : 6;
}

export function bandDays(days) {
  const cuts = [7, 30, 90, 180, 365];
  const i = cuts.findIndex((hi) => days <= hi);
  return i < 0 ? 6 : i + 1;
}

export const BANDS = {
  participation: ['1 tenderer', '2 tenderers', '3-5 tenderers', '6-10 tenderers', '11-20 tenderers', '21-50 tenderers',
    '51-100 tenderers', '101-1,000 (sensitivity only)'],
  ratio: ['Below 0.5', '0.5 to under 0.9', '0.9 to 1.1', 'Over 1.1 to 1.5', 'Over 1.5 to 10', 'Over 10'],
  duration: ['Up to 7 days', '8-30 days', '31-90 days', '91-180 days', '181-365 days', 'Over 1 year'],
  implementation: ['Transactions and milestones', 'Milestones only', 'Transactions only', 'No implementation data'],
  stage: ['Planning', 'Tender', 'Award', 'Contract', 'Implementation'],
};

// ---------------------------------------------------------------- populations

// M-V01 award rows; M-S01 rows are the awards with a usable supplier ID (one supplier per award).
export function awardRows(d, f) {
  return rows(d, 'awards', f);
}

export function supplierRows(d, f) {
  return rows(d, 'awards', f).filter((i) => d.awards.s[i] >= 0);
}

// Supplier index -> value (BigInt kobo) within the filter.
export function supplierValues(d, f) {
  const idx = supplierRows(d, f);
  return groupSum(pick(d.awards.s, idx), pick(d.awards.v, idx));
}

// Entity award totals from vw_entity_benchmark (blank -> 0), keyed by buyer index.
export function entityValues(d, f) {
  const e = d.entities;
  const m = new Map();
  e.b.forEach((b, i) => {
    if (f.buyer == null || d.buyerIds[b] === f.buyer) m.set(b, BigInt(e.award_value_total[i] ?? 0));
  });
  return m;
}

function competitionRows(d, f, primary) {
  const idx = rows(d, 'competition', f);
  return primary == null ? idx : idx.filter((i) => d.competition.p[i] === primary);
}

function lifecycleCells(d, f) {
  return rows(d, 'lifecycle', f).map((i) => [d.lifecycle.k[i], d.lifecycle.n[i]]);
}

function reached(d, f, k) {
  return lifecycleCells(d, f).reduce((s, [stage, n]) => s + (stage >= k ? n : 0), 0);
}

function contractCells(d, f) {
  const c = d.contracts;
  return rows(d, 'contracts', f).map((i) => [c.t[i], c.h[i], c.n[i]]);
}

function register(d, metricId) {
  const t = d.registers.metric_population;
  const row = t.rows.find((r) => r[0] === metricId);
  return Object.fromEntries(t.cols.map((c, i) => [c, row[i]]));
}

function dqRow(d, metricId, dqRef) {
  const t = d.registers.dq_impact;
  const row = t.rows.find((r) => r[1] === metricId && r[4] === dqRef);
  return Object.fromEntries(t.cols.map((c, i) => [c, row[i]]));
}

// exact NGN decimal string -> BigInt kobo
const decimalKobo = (text) => decimalToScaled(text, 2);

function entityKpi(d, f, column) {
  const e = d.entities;
  const i = e.b.indexOf(d.buyerIndex.get(f.buyer));
  return i < 0 ? null : e[column][i];
}

function medianEntity(d, kpi, nCol, minN) {
  const e = d.entities;
  const v = [];
  e.b.forEach((_, i) => {
    if ((e[nCol][i] ?? 0) >= minN && e[kpi][i] != null) v.push(e[kpi][i]);
  });
  return median(v);
}

const count = (idx) => idx.length;
const ba = (d, f) => rows(d, 'budget_award', f);

function singleBidderRate(d, f, primary) {
  const idx = competitionRows(d, f, primary ? 1 : null);
  return divide(idx.reduce((s, i) => s + d.competition.sb[i], 0), idx.length);
}

function awardValue(d, f) {
  return sumBig(pick(d.awards.v, awardRows(d, f)));
}

function supplierValue(d, f) {
  return sumBig(pick(d.awards.v, supplierRows(d, f)));
}

// ---------------------------------------------------------------- measures, by DAX name

export const MEASURES = {
  '[Processes (n)]': (d, f) => lifecycleCells(d, f).reduce((s, [, n]) => s + n, 0),
  '[Planning-Only Share]': (d, f) => {
    const c = lifecycleCells(d, f);
    return divide(c.reduce((s, [k, n]) => s + (k === 1 ? n : 0), 0), c.reduce((s, [, n]) => s + n, 0));
  },
  '[OCIDs Reaching Stage]': (d, f, p) => reached(d, f, p.stage),
  '[Stage Conversion Rate]': (d, f, p) => (p.stage > 1 ? divide(reached(d, f, p.stage), reached(d, f, p.stage - 1)) : null),

  '[Planned Budget (NGN)]': (d, f) => sumBig(pick(d.budget.v, rows(d, 'budget', f))),
  '[Budget Lines (n)]': (d, f) => pick(d.budget.n, rows(d, 'budget', f)).reduce((s, n) => s + n, 0),

  '[Award Value (NGN)]': (d, f) => awardValue(d, f),
  '[Eligible Awards (n)]': (d, f) => count(awardRows(d, f)),
  '[Median Award Value (NGN)]': (d, f) => median(pick(d.awards.v, awardRows(d, f))),

  '[M-S01 Eligible Awards]': (d, f) => count(supplierRows(d, f)),
  '[Suppliers (n)]': (d, f) => supplierValues(d, f).size,
  '[Supplier Value (NGN)]': (d, f) => supplierValue(d, f),
  '[Top N Supplier Share]': (d, f, p) => {
    const v = [...supplierValues(d, f).values()];
    return divide(topNSum(v, p.n), sumBig(v));
  },
  '[Supplier HHI]': (d, f) => hhi(supplierValues(d, f).values()),
  '[Suppliers With One Award]': (d, f) => [...groupCount(pick(d.awards.s, supplierRows(d, f))).values()].filter((c) => c === 1).length,
  '[M-S01 Excluded Awards]': (d, f) => count(awardRows(d, f)) - count(supplierRows(d, f)),
  '[M-S01 Excluded Value (NGN)]': (d, f) => awardValue(d, f) - supplierValue(d, f),
  '[M-S01 Excluded Value Share]': (d, f) => divide(awardValue(d, f) - supplierValue(d, f), awardValue(d, f)),
  '[M-S01 Excluded Awards (DQ view)]': (d) => dqRow(d, 'M-S01', 'DQ-14').records_with_issue,
  '[M-S01 Excluded Value (DQ view)]': (d) => decimalKobo(dqRow(d, 'M-S01', 'DQ-14').affected_value_ngn),

  '[Competition n (primary)]': (d, f) => count(competitionRows(d, f, 1)),
  '[Competition n (sensitivity)]': (d, f) => count(competitionRows(d, f, null)),
  '[Median Tenderers (primary)]': (d, f) => median(pick(d.competition.t, competitionRows(d, f, 1))),
  '[Median Tenderers (sensitivity)]': (d, f) => median(pick(d.competition.t, competitionRows(d, f, null))),
  '[Single-Bidder Rate (primary)]': (d, f) => singleBidderRate(d, f, true),
  '[Single-Bidder Rate (sensitivity)]': (d, f) => singleBidderRate(d, f, false),
  '[Tenders (n)] by [Participation Band]': (d, f, p) => competitionRows(d, f, p.population)
    .filter((i) => bandTenderers(d.competition.t[i]) === p.band).length,

  '[Comparable OCIDs]': (d, f) => count(ba(d, f)),
  '[Budget of Comparable OCIDs (NGN)]': (d, f) => sumBig(pick(d.budget_award.bud, ba(d, f))),
  '[Award of Comparable OCIDs (NGN)]': (d, f) => sumBig(pick(d.budget_award.aw, ba(d, f))),
  '[Net Variance (NGN)]': (d, f) => sumBig(pick(d.budget_award.aw, ba(d, f))) - sumBig(pick(d.budget_award.bud, ba(d, f))),
  '[Aggregate Award-to-Budget Ratio]': (d, f) => divide(sumBig(pick(d.budget_award.aw, ba(d, f))), sumBig(pick(d.budget_award.bud, ba(d, f)))),
  '[Median Award-to-Budget Ratio]': (d, f) => median(pick(d.budget_award.r, ba(d, f))),
  '[Share Within 10% of Budget]': (d, f) => {
    const r = pick(d.budget_award.r, ba(d, f));
    return divide(r.filter((x) => x >= 0.9 && x <= 1.1).length, r.length);
  },
  '[OCIDs With Budget Under 100k]': (d, f) => pick(d.budget_award.bud, ba(d, f)).filter((k) => k < 100000 * 100).length,
  '[Comparable OCIDs] by [Ratio Band]': (d, f, p) => pick(d.budget_award.r, ba(d, f)).filter((r) => bandRatio(r) === p.band).length,

  '[Tender Duration n]': (d, f) => count(rows(d, 'tender_duration', f)),
  '[Award Lag n]': (d, f) => count(rows(d, 'award_lag', f)),
  '[Signature Lag n]': (d, f) => count(rows(d, 'signature_lag', f)),
  '[Median Tender Duration (days)]': (d, f) => median(pick(d.tender_duration.d, rows(d, 'tender_duration', f))),
  '[Median Award Lag (days)]': (d, f) => median(pick(d.award_lag.d, rows(d, 'award_lag', f))),
  '[Median Signature Lag (days)]': (d, f) => median(pick(d.signature_lag.d, rows(d, 'signature_lag', f))),
  '[P90 Tender Duration (days)]': (d, f) => percentileInc(pick(d.tender_duration.d, rows(d, 'tender_duration', f)), 0.9),
  '[P90 Award Lag (days)]': (d, f) => percentileInc(pick(d.award_lag.d, rows(d, 'award_lag', f)), 0.9),
  '[P90 Signature Lag (days)]': (d, f) => percentileInc(pick(d.signature_lag.d, rows(d, 'signature_lag', f)), 0.9),
  '[Award Lag Over 1 Year Share]': (d, f) => {
    const v = pick(d.award_lag.d, rows(d, 'award_lag', f));
    return divide(v.filter((x) => x > 365).length, v.length);
  },
  '[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]': (d, f, p) => pick(d[p.timingTable].d, rows(d, p.timingTable, f))
    .filter((x) => bandDays(x) === p.band).length,
  '[Coverage M-E01]': (d) => divide(register(d, 'M-E01').eligible_count, register(d, 'M-E01').candidate_count),
  '[Coverage M-E02]': (d) => divide(register(d, 'M-E02').eligible_count, register(d, 'M-E02').candidate_count),
  '[Coverage Signature Lag]': (d) => divide(register(d, 'P5-SIG').eligible_count, register(d, 'P5-SIG').candidate_count),

  '[Entities (n)]': (d, f) => entityValues(d, f).size,
  '[Entity Processes]': (d) => d.entities.process_count.reduce((s, n) => s + n, 0),
  '[Entity Planned Budget (NGN)]': (d) => sumBig(d.entities.planned_budget_total.map((x) => x ?? 0)),
  '[Entity Award Value (NGN)]': (d, f) => sumBig(entityValues(d, f).values()),
  '[Top N Entity Share]': (d, f, p) => {
    const v = [...entityValues(d, f).values()];
    return divide(topNSum(v, p.n), sumBig(v));
  },
  '[Median Entity Single-Bidder Rate]': (d, f, p) => medianEntity(d, 'single_bidder_rate', 'competition_n', p.minN),
  '[Median Entity Top-Supplier Share]': (d, f, p) => medianEntity(d, 'top_supplier_value_share', 'award_n', p.minN),
  '[Median Entity Implementation Coverage]': (d, f, p) => medianEntity(d, 'implementation_coverage_rate', 'contract_n', p.minN),
  '[Entity Single-Bidder Rate]': (d, f) => entityKpi(d, f, 'single_bidder_rate'),
  '[Entity Top-Supplier Share]': (d, f) => entityKpi(d, f, 'top_supplier_value_share'),
  '[Entity Implementation Coverage]': (d, f) => entityKpi(d, f, 'implementation_coverage_rate'),
  '[Entity Tender Reach Rate]': (d, f) => entityKpi(d, f, 'tender_reach_rate'),
  '[Entity Median Award Value (NGN)]': (d, f) => entityKpi(d, f, 'median_award_value'),

  '[Contracts (n)]': (d, f) => contractCells(d, f).reduce((s, [, , n]) => s + n, 0),
  '[Contracts With Implementation Data]': (d, f) => contractCells(d, f).reduce((s, [, h, n]) => s + (h ? n : 0), 0),
  '[Implementation Coverage Rate]': (d, f) => {
    const c = contractCells(d, f);
    return divide(c.reduce((s, [, h, n]) => s + (h ? n : 0), 0), c.reduce((s, [, , n]) => s + n, 0));
  },
  '[Contracts (n)] by [Implementation Data Type]': (d, f, p) => contractCells(d, f).reduce((s, [t, , n]) => s + (t === p.band ? n : 0), 0),

  'MetricPopulation[candidate_count]': (d, f, p) => register(d, p.metric).candidate_count,
  'MetricPopulation[eligible_count]': (d, f, p) => register(d, p.metric).eligible_count,
  '[Eligible Share]': (d, f, p) => divide(register(d, p.metric).eligible_count, register(d, p.metric).candidate_count),
  'DQImpact[records_with_issue]': (d, f, p) => dqRow(d, p.metric, p.issue).records_with_issue,
  'DQImpact[affected_value_ngn]': (d, f, p) => decimalKobo(dqRow(d, p.metric, p.issue).affected_value_ngn),
};

export function measure(d, name, filter = {}, params = {}) {
  const fn = MEASURES[name];
  if (!fn) throw new Error(`unknown measure ${name}`);
  return fn(d, filter, params);
}

// ---------------------------------------------------------------- DQ-21 sensitivity (Phase 10.1 result sets)
// Each function returns the rows of its result set, rounded as the SQL rounds them (NGN billions, percentages),
// so the site can show them and the self-check can compare them cell by cell.

const EXCLUDE = { dq21: 'exclude' };

function shareOfTop(rankedEntries, k, tot) {
  return percentOf(sumBig(rankedEntries.slice(0, k).map((e) => e[1])), tot, 2);
}

// 01/RS6: overall supplier concentration, as published and without flagged awards.
export function rs6(d) {
  const flaggedInSup = supplierRows(d, {}).filter((i) => d.awards.f[i]).length;
  return [['1  as published (RS2)', {}], ['2  without DQ-21 flagged awards', EXCLUDE]].map(([label, f]) => {
    const v = supplierValues(d, f);
    const tot = sumBig(v.values());
    const rk = ranked(v, (s) => d.suppliers.id[s]);
    let sq = 0n;
    for (const x of v.values()) sq += x * x;
    return [label, supplierRows(d, f).length, flaggedInSup, koboToBillions(tot, 1),
      shareOfTop(rk, 1, tot), shareOfTop(rk, 5, tot), shareOfTop(rk, 10, tot), shareOfTop(rk, 100, tot),
      scaledToString(roundDiv(sq * 10000n * 10n, tot * tot), 1), d.suppliers.name[rk[0][0]], koboToBillions(rk[0][1], 2)];
  });
}

// 01/RS6b: concentration by procurement method, as published and without flagged awards.
export function rs6b(d) {
  const out = [];
  d.methods.forEach((method, mi) => {
    const idx = supplierRows(d, { method });
    if (!idx.length) return;
    const pub = groupSum(pick(d.awards.s, idx), pick(d.awards.v, idx));
    const woIdx = idx.filter((i) => !d.awards.f[i]);
    const wo = groupSum(pick(d.awards.s, woIdx), pick(d.awards.v, woIdx));
    const tp = sumBig(pub.values());
    const tw = sumBig(wo.values());
    const maxOf = (m) => [...m.values()].reduce((a, b) => (b > a ? b : a), 0n);
    const sqOf = (m) => [...m.values()].reduce((a, b) => a + b * b, 0n);
    out.push([tp, [method, idx.filter((i) => d.awards.f[i]).length, koboToBillions(tp, 2), koboToBillions(tw, 2),
      percentOf(maxOf(pub), tp, 1), tw ? percentOf(maxOf(wo), tw, 1) : null,
      scaledToString(roundDiv(sqOf(pub) * 10000n, tp * tp), 0), tw ? scaledToString(roundDiv(sqOf(wo) * 10000n, tw * tw), 0) : '0']]);
  });
  return out.sort((a, b) => (a[0] < b[0] ? 1 : -1)).map((x) => x[1]);
}

// 03/RS11: budget-to-award totals, ratios and the above-10x band, as published and without flagged awards.
export function rs11(d) {
  const t = d.budget_award;
  const flagged = t.f.reduce((s, x) => s + x, 0);
  return [['1  as published (RS1, RS3)', {}], ['2  without DQ-21 flagged awards', EXCLUDE]].map(([label, f]) => {
    const idx = rows(d, 'budget_award', f);
    const bud = sumBig(pick(t.bud, idx));
    const aw = sumBig(pick(t.aw, idx));
    const hi = idx.filter((i) => t.r[i] > 10);
    const hiAw = sumBig(pick(t.aw, hi));
    return [label, idx.length, flagged, koboToBillions(bud, 1), koboToBillions(aw, 1),
      scaledToString(roundDiv(aw * 10000n, bud), 4), roundTo(median(pick(t.r, idx)), 4), hi.length,
      koboToBillions(hiAw, 1), percentOf(hiAw, aw, 2)];
  });
}

// 03/RS11a: footprint of the DQ-21 flag (bit 1 = dropped-decimal test, bit 2 = sibling-lot test).
export function rs11a(d) {
  const a = d.awards;
  const fl = a.f.map((x, i) => (x ? i : -1)).filter((i) => i >= 0);
  const val = sumBig(pick(a.v, fl));
  return [[fl.length, fl.filter((i) => a.f[i] & 1).length, fl.filter((i) => a.f[i] & 2).length, koboToBillions(val, 1),
    percentOf(val, sumBig(a.v), 1), d.budget_award.f.reduce((s, x) => s + x, 0), new Set(pick(a.b, fl)).size]];
}

// 03/RS11b: the above-10x band by entity without flagged awards (top 5).
export function rs11b(d) {
  const t = d.budget_award;
  const idx = rows(d, 'budget_award', EXCLUDE).filter((i) => t.r[i] > 10);
  const val = groupSum(pick(t.b, idx), pick(t.aw, idx));
  const cnt = groupCount(pick(t.b, idx));
  const tot = sumBig(val.values());
  const order = [...val.keys()].sort((x, y) => (val.get(x) < val.get(y) ? 1 : -1));
  return order.slice(0, 5).map((b) => [1 + [...val.values()].filter((x) => x > val.get(b)).length, buyerId(d, b),
    b >= 0 ? d.buyerNames[b] : null, cnt.get(b), koboToBillions(val.get(b), 1), percentOf(val.get(b), tot, 1),
    idx.length, koboToBillions(tot, 1)]);
}

// Entity award value from the award rows (complete buyer IDs), as published and without flagged awards.
export function entityAwardScenarios(d) {
  const a = d.awards;
  const pub = new Map();
  const wo = new Map();
  const flagged = new Map();
  a.b.forEach((b, i) => {
    if (b < 0) return;
    pub.set(b, (pub.get(b) ?? 0n) + BigInt(a.v[i]));
    wo.set(b, (wo.get(b) ?? 0n) + (a.f[i] ? 0n : BigInt(a.v[i])));
    flagged.set(b, (flagged.get(b) ?? 0) + (a.f[i] ? 1 : 0));
  });
  return { pub, wo, flagged };
}

// 05/RS7: share of award value held by the largest entities, as published and without flagged awards.
export function rs7(d) {
  const { pub, wo } = entityAwardScenarios(d);
  const idOf = (b) => d.buyerIds[b];
  const rp = ranked(pub, idOf);
  const rw = ranked(wo, idOf);
  const tp = sumBig(pub.values());
  const tw = sumBig(wo.values());
  const top = (r, k, tot) => percentOf(sumBig(r.slice(0, k).map((e) => e[1])), tot, 1);
  return [1, 5, 10, 20, 50, 100].map((n) => [n, top(rp, n, tp), top(rw, n, tw), koboToBillions(tp, 1), koboToBillions(tw, 1)]);
}

// 05/RS7b: the 10 largest entities by award value without flagged awards, with their published rank.
export function rs7b(d) {
  const { pub, wo, flagged } = entityAwardScenarios(d);
  const idOf = (b) => d.buyerIds[b];
  const rankPub = new Map(ranked(pub, idOf).map(([b], i) => [b, i + 1]));
  return ranked(wo, idOf).slice(0, 10).map(([b, v], i) => [i + 1, rankPub.get(b), d.buyerIds[b], d.buyerNames[b],
    koboToBillions(pub.get(b), 1), flagged.get(b), koboToBillions(v, 1)]);
}

export const SENSITIVITY = { '01/RS6': rs6, '01/RS6b': rs6b, '03/RS11': rs11, '03/RS11a': rs11a, '03/RS11b': rs11b,
  '05/RS7': rs7, '05/RS7b': rs7b };
