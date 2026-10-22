// Self-check: recompute every figure in data/expected.json with the site's own functions and compare.
//
// expected.json holds the 177 figures of dashboard/reconciliation_expected_values.sql (with the slice each holds in)
// and the Phase 10.1 DQ-21 sensitivity result sets, both written by python/web/export_web_data.py. Tolerance is the
// reconciliation log's: counts, days and bands identical; NGN to the whole naira; ratios and shares to four decimals;
// the index to one decimal.

import { measure, SENSITIVITY } from './metrics.js';
import { decimalToScaled, formatExact, koboToNaira, roundTo, unitPlaces } from './format.js';

// (measure, filter, params) from a pack row: the slice text and the figure ID carry the parameters.
export function parseFigure(fig) {
  let name = fig.measure;
  const filter = {};
  const params = {};
  const topN = name.match(/^(.*) with N = (\d+)$/);
  if (topN) {
    name = topN[1];
    params.n = Number(topN[2]);
  }
  for (const part of fig.slice.split(',').map((s) => s.trim())) {
    if (part === 'none') continue;
    const [key, val] = part.split('=').map((s) => s.trim());
    if (key === 'method') filter.method = val;
    else if (key === 'buyer') filter.buyer = val;
    else if (key === 'tender_status') filter.tenderStatus = val;
    else if (key === 'contract_status') filter.contractStatus = val;
    else if (key === 'Tender Start Year') filter.tenderStartYear = Number(val);
    else if (key === 'Stage') params.stage = Number(val);
    else if (key === 'population') params.population = val === 'primary' ? 1 : 0;
    else if (/^Min .* n$/.test(key)) params.minN = Number(val);
    else if (key === 'metric') params.metric = val;
    else if (key === 'issue') params.issue = val;
    else throw new Error(`${fig.id}: unknown slice "${part}"`);
  }
  let m = fig.id.match(/^(COM-B|BVA-B|IMP-T)(\d+)$/);
  if (m) params.band = Number(m[2]);
  m = fig.id.match(/^TIM-D(\d)-(\d)$/);
  if (m) {
    params.timingTable = ['tender_duration', 'award_lag', 'signature_lag'][Number(m[1]) - 1];
    params.band = Number(m[2]);
  }
  if (/^DQ-[CEP]-/.test(fig.id)) params.metric = fig.figure.split(': ')[1];
  return { name, filter, params };
}

// Shown value at the log's precision: NGN as rounded naira, the rest as rounded decimals.
function shown(value, unit, fromSql) {
  if (value == null) return null;
  if (unit === 'NGN') return fromSql ? roundTo(value, 0) : koboToNaira(value, 0);
  return roundTo(value, unitPlaces(unit));
}

export function agrees(expected, computed, unit) {
  if (expected == null || computed == null) return expected == null && computed == null;
  if (shown(expected, unit, true) === shown(computed, unit, false)) return true;
  // the absolute 1e-6 only absorbs a float result a hair either side of a rounding boundary
  const c = unit === 'NGN' ? Number(computed) / 100 : Number(computed);
  return Math.abs(Number(expected) - c) <= 1e-6;
}

function sameCell(e, c) {
  if (e == null || c == null) return e == null && c == null;
  const numeric = /^-?\d+(\.\d+)?$/;
  if (numeric.test(String(e)) && numeric.test(String(c))) return Number(e) === Number(c);
  return String(e) === String(c);
}

export function runChecks(d) {
  const figures = d.expected.pack.map((fig) => {
    let got = null;
    let error = '';
    try {
      const { name, filter, params } = parseFigure(fig);
      got = measure(d, name, filter, params);
    } catch (exc) {
      error = String(exc);
    }
    const ok = !error && agrees(fig.value, got, fig.unit);
    const sql = fig.unit === 'NGN' ? decimalToScaled(fig.value, 2) : Number(fig.value);
    return { id: fig.id, figure: fig.figure, slice: fig.slice, sql: formatExact(sql, fig.unit),
      web: error || formatExact(got, fig.unit), ok };
  });
  const cells = [];
  for (const [key, fn] of Object.entries(SENSITIVITY)) {
    const { cols, rows } = d.expected.sensitivity[key];
    const got = fn(d);
    if (got.length !== rows.length) cells.push({ key, row: 0, col: 'row count', sql: rows.length, web: got.length, ok: false });
    rows.forEach((r, ri) => cols.forEach((c, ci) => {
      const g = got[ri] ? got[ri][ci] : undefined;
      cells.push({ key, row: ri + 1, col: c, sql: r[ci], web: g, ok: g !== undefined && sameCell(r[ci], g) });
    }));
  }
  return { figures, cells };
}
