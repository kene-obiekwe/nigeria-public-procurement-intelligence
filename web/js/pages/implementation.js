// Page 6: Implementation and lifecycle. Filters: entity, contract status (contracts only; the lifecycle has no status).

import { BANDS, measure } from '../metrics.js';
import { donut, hbar } from '../charts.js';
import { card, cards, caveat, entityControl, grid, h, panel, selectControl, table } from '../ui.js';
import { CAVEATS } from '../text.js';
import { compact, int, labelOf, pct, pctAxis } from './common.js';
import { extremes } from './competition.js';

const MIN_CONTRACTS = 20;

export function render({ d, el, params, set, after }) {
  const fc = { buyer: params.buyer ?? null, contractStatus: params.status ?? null };
  const fl = { buyer: fc.buyer };
  const m = (name, p) => measure(d, name, fc, p);
  const n = m('[Contracts (n)]');

  el.append(h('div', { class: 'controls' },
    entityControl(d, fc.buyer, (v) => set({ buyer: v })),
    selectControl('Contract status', [['', 'All'], ...d.dims.contract_statuses.map((s) => [s, s])], fc.contractStatus ?? '',
      (v) => set({ status: v || null }))));

  el.append(cards([
    card({ title: 'Contracts in scope', value: n, measure: '[Contracts (n)]', timing: true }),
    card({ title: 'Contracts with implementation data published', value: m('[Contracts With Implementation Data]'), n,
      measure: '[Contracts With Implementation Data]', timing: true }),
    card({ title: 'Implementation reporting coverage', value: m('[Implementation Coverage Rate]'), unit: 'share', n,
      measure: '[Implementation Coverage Rate]', timing: true }),
  ], 'three'));

  const types = BANDS.implementation.map((name, i) => ({ name, value: m('[Contracts (n)] by [Implementation Data Type]', { band: i + 1 }) }));
  const statuses = (fc.contractStatus ? [fc.contractStatus] : d.dims.contract_statuses).map((s) => ({ s,
    rate: measure(d, '[Implementation Coverage Rate]', { ...fc, contractStatus: s }),
    n: measure(d, '[Contracts (n)]', { ...fc, contractStatus: s }) })).filter((x) => x.n > 0).sort((a, b) => b.rate - a.rate);
  const stages = BANDS.stage.map((name, i) => ({ name, n: measure(d, '[OCIDs Reaching Stage]', fl, { stage: i + 1 }),
    conv: i ? measure(d, '[Stage Conversion Rate]', fl, { stage: i + 1 }) : null }));
  const typeEl = h('div', { class: 'chart' });
  const statusEl = h('div', { class: 'chart' });
  const stageEl = h('div', { class: 'chart' });
  el.append(grid('three',
    panel('Contracts by type of implementation data published', null, typeEl),
    panel('Implementation reporting coverage, by contract status', 'n in the tooltip', statusEl),
    panel('Processes reaching each stage', 'Label: processes; tooltip: conversion from the previous stage. The contract-status filter does not apply.', stageEl)));

  const e = d.entities;
  const ents = [];
  e.b.forEach((b, i) => {
    if (fc.buyer != null && d.buyerIds[b] !== fc.buyer) return;
    if ((e.contract_n[i] ?? 0) >= MIN_CONTRACTS && e.implementation_coverage_rate[i] != null) {
      ents.push({ label: labelOf(d, b), rate: e.implementation_coverage_rate[i], n: e.contract_n[i] });
    }
  });
  el.append(grid('two',
    panel(`Entities with the lowest implementation coverage (at least ${MIN_CONTRACTS} contracts)`,
      'Lowest 15; entities tied at the cut-off are all listed. Precomputed per entity: the contract-status filter does not apply.',
      table([
        { key: 'label', label: 'Procuring entity' },
        { key: 'rate', label: 'Implementation coverage', bar: true, format: (v) => pct(v) },
        { key: 'n', label: 'Contracts (n)', num: true, format: int },
      ], extremes(ents, 'rate', 15, false), { cls: 'short', label: 'Lowest implementation coverage' })),
    h('section', { class: 'panel' }, h('h2', { text: 'Reading these figures' }), caveat(CAVEATS.implementation), caveat(CAVEATS.funnel))));

  after(() => {
    donut(typeEl, 'Contracts by type of implementation data published', types.filter((x) => x.value > 0), compact(n, true), int);
    hbar(statusEl, 'Implementation reporting coverage by contract status', statuses.map((x) => x.s), statuses.map((x) => x.rate),
      (v, axis) => (axis ? pctAxis(v) : pct(v)), { max: 1, tooltip: (i) => `${statuses[i].s}\n${pct(statuses[i].rate)} of ${statuses[i].n.toLocaleString('en')} contracts` });
    hbar(stageEl, 'Processes reaching each stage', stages.map((x) => x.name), stages.map((x) => x.n), compact,
      { tooltip: (i) => `${stages[i].name}: ${int(stages[i].n)} processes${stages[i].conv == null ? '' : `\n${pct(stages[i].conv, 1)} of the previous stage`}` });
  });
}
