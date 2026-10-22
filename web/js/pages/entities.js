// Page 5: Entity benchmark. Filters: entity, Top N, minimum n per KPI, and the DQ-21 switch (decision F-2).
//
// KPIs are precomputed per entity in SQL (vw_entity_benchmark) and are never recombined here. The DQ-21 switch
// changes only what is a sum of award rows: entity award value, the Top N entity share and the order by award value.
// Those figures without flagged awards are checked against script 05 RS7/RS7b.

import { divide, entityAwardScenarios, entityValues, median, sumBig, topNSum } from '../metrics.js';
import { hbar } from '../charts.js';
import { int as intParam } from '../state.js';
import { card, cards, caveat, checkControl, controlBar, entityControl, grid, h, numberControl, panel, table, topNControl } from '../ui.js';
import { CAVEATS } from '../text.js';
import { dec, int, labelOf, ngn, ngnCompact, pct } from './common.js';

export function render({ d, el, params, set, after }) {
  const buyer = params.buyer ?? null;
  const n = intParam(params, 'topn', 10);
  const minT = intParam(params, 'mint', 30);
  const minA = intParam(params, 'mina', 10);
  const minC = intParam(params, 'minc', 20);
  const minP = intParam(params, 'minp', 30);
  const includeFlagged = params.dq21 !== 'off';

  el.append(controlBar(
    entityControl(d, buyer, (v) => set({ buyer: v })),
    topNControl(n, (v) => set({ topn: v === 10 ? null : v }), 'Top N'),
    numberControl('Minimum tenders', minT, 1, 200, (v) => set({ mint: v === 30 ? null : v })),
    numberControl('Minimum awards', minA, 1, 200, (v) => set({ mina: v === 10 ? null : v })),
    numberControl('Minimum contracts', minC, 1, 200, (v) => set({ minc: v === 20 ? null : v })),
    numberControl('Minimum processes', minP, 1, 200, (v) => set({ minp: v === 30 ? null : v })),
    checkControl('Include awards flagged as possible scale errors (DQ-21)', includeFlagged, (on) => set({ dq21: on ? null : 'off' }))));

  // Award value per entity: published (vw_entity_benchmark) or summed from award rows without flagged awards.
  const f = { buyer };
  const published = entityValues(d, f);
  let values = published;
  if (!includeFlagged) {
    const { wo } = entityAwardScenarios(d);
    values = new Map([...published.keys()].map((b) => [b, wo.get(b) ?? 0n]));
  }
  const vals = [...values.values()];
  const topShare = divide(topNSum(vals, n), sumBig(vals));

  const e = d.entities;
  const rowsAll = e.b.map((b, i) => ({ b, i })).filter(({ b }) => buyer == null || d.buyerIds[b] === buyer).map(({ b, i }) => ({
    label: labelOf(d, b),
    processes: e.process_count[i],
    budget: e.planned_budget_total[i],
    award: values.get(b) === 0n && e.award_value_total[i] == null ? null : values.get(b),
    reach: e.process_count[i] >= minP ? e.tender_reach_rate[i] : null,
    tenderers: e.median_tenderers[i],
    single: (e.competition_n[i] ?? 0) >= minT ? e.single_bidder_rate[i] : null,
    top: (e.award_n[i] ?? 0) >= minA ? e.top_supplier_value_share[i] : null,
    impl: (e.contract_n[i] ?? 0) >= minC ? e.implementation_coverage_rate[i] : null,
  })).sort((a, b) => (Number(b.award ?? -1n) - Number(a.award ?? -1n)) || (a.label < b.label ? -1 : 1));

  const yard = (kpi, nCol, min) => {
    const v = [];
    e.b.forEach((b, i) => {
      if ((buyer == null || d.buyerIds[b] === buyer) && (e[nCol][i] ?? 0) >= min && e[kpi][i] != null) v.push(e[kpi][i]);
    });
    return median(v);
  };

  el.append(cards([
    card({ title: 'Procuring entities with a complete buyer ID', value: values.size, measure: '[Entities (n)]' }),
    card({ title: `Share of entity awarded value held by the ${n} largest entities${includeFlagged ? '' : ' (without DQ-21 flagged awards)'}`,
      value: topShare, unit: 'share', n: values.size, measure: includeFlagged ? '[Top N Entity Share]' : null, params: { n } }),
    card({ title: 'Median entity single-bidder share (entities meeting the minimum)', value: yard('single_bidder_rate', 'competition_n', minT),
      unit: 'share', measure: '[Median Entity Single-Bidder Rate]', params: { minN: minT } }),
    card({ title: 'Median entity top-supplier share (entities meeting the minimum)', value: yard('top_supplier_value_share', 'award_n', minA),
      unit: 'share', measure: '[Median Entity Top-Supplier Share]', params: { minN: minA } }),
    card({ title: 'Median entity implementation coverage (entities meeting the minimum)',
      value: yard('implementation_coverage_rate', 'contract_n', minC), unit: 'share', measure: '[Median Entity Implementation Coverage]',
      params: { minN: minC } }),
  ], 'five'));

  if (!includeFlagged) {
    el.append(h('p', { class: 'caveat', text: 'Showing entity award value without the awards flagged as possible scale errors (DQ-21). '
      + 'Only award value, the share held by the largest entities and the order by award value change; per-entity medians and KPIs '
      + 'are precomputed and stay as published. Checked against Phase 10.1 result sets 05 RS7 and RS7b.' }));
  }

  const top15 = rowsAll.filter((r) => r.award != null).slice(0, 15);
  const barEl = h('div', { class: 'chart tall' });
  el.append(grid('wide-right',
    panel(`15 entities with the largest awarded value${includeFlagged ? '' : ' (without DQ-21 flagged awards)'}`, null, barEl),
    panel('Entity KPIs (a KPI is blank where the entity is below the minimum number of records)',
      'Largest awarded value first; the table scrolls to show every entity',
      table([
        { key: 'label', label: 'Procuring entity' },
        { key: 'processes', label: 'Processes', num: true, format: int },
        { key: 'budget', label: 'Planned budget (NGN)', num: true, format: ngn },
        { key: 'award', label: 'Award value (NGN)', bar: true, format: ngn },
        { key: 'reach', label: 'Reached tender', num: true, format: (v) => pct(v) },
        { key: 'tenderers', label: 'Median tenderers', num: true, format: dec(1) },
        { key: 'single', label: 'Single-bidder share', num: true, format: (v) => pct(v) },
        { key: 'top', label: 'Top-supplier share', num: true, format: (v) => pct(v) },
        { key: 'impl', label: 'Implementation coverage', num: true, format: (v) => pct(v) },
      ], rowsAll, { label: 'Entity KPIs' }))));
  el.append(caveat(CAVEATS.entity));

  after(() => hbar(barEl, '15 entities with the largest awarded value', top15.map((r) => r.label), top15.map((r) => Number(r.award)),
    (v) => ngnCompact(BigInt(Math.round(v))), { tooltip: (i) => `${top15[i].label}\nNGN ${ngn(top15[i].award)}` }));
}
