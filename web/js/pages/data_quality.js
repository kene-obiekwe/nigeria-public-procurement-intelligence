// Page 7: Data quality and coverage. Filters: metric and impact type (they apply to the issues table only).

import { measure, rs11a } from '../metrics.js';
import { decimalToScaled } from '../format.js';
import { card, cards, caveat, grid, h, panel, selectControl, table } from '../ui.js';
import { CAVEATS } from '../text.js';
import { int, ngn, pct } from './common.js';

const asRows = (t) => t.rows.map((r) => Object.fromEntries(t.cols.map((c, i) => [c, r[i]])));

export function render({ d, el, params, set }) {
  const reg = asRows(d.registers.metric_population).map((r) => ({ ...r, share: r.eligible_count / r.candidate_count }))
    .sort((a, b) => (a.metric_name < b.metric_name ? -1 : 1));
  const dqAll = asRows(d.registers.dq_impact);
  const metrics = [...new Set(dqAll.map((r) => r.metric_id))];
  const impacts = [...new Set(dqAll.map((r) => r.impact_type))].sort();
  const metric = params.metric ?? null;
  const impact = params.impact ?? null;
  const dq = dqAll.filter((r) => (!metric || r.metric_id === metric) && (!impact || r.impact_type === impact));

  el.append(h('div', { class: 'controls' },
    selectControl('Metric', [['', 'All'], ...metrics.map((x) => [x, x])], metric ?? '', (v) => set({ metric: v || null })),
    selectControl('Impact type', [['', 'All'], ...impacts.map((x) => [x, x])], impact ?? '', (v) => set({ impact: v || null }))));

  const f = {};
  const [[flagged, , , flaggedBn, flaggedPct]] = rs11a(d);
  el.append(grid('two',
    h('div', {},
      panel('Population register: candidate and eligible records per metric', 'The table scrolls to show every metric',
        table([
          { key: 'metric_name', label: 'Metric' },
          { key: 'candidate_count', label: 'Candidate records', num: true, format: int },
          { key: 'eligible_count', label: 'Eligible records', num: true, format: int },
          { key: 'share', label: 'Eligible share', bar: true, format: (v) => pct(v) },
        ], reg, { cls: 'free', label: 'Population register' })),
      cards([
        card({ title: 'Supplier-ID gap: awards left out (award data)', value: measure(d, '[M-S01 Excluded Awards]', f), measure: '[M-S01 Excluded Awards]' }),
        card({ title: 'Supplier-ID gap: awards left out (DQ view)', value: measure(d, '[M-S01 Excluded Awards (DQ view)]', f),
          measure: '[M-S01 Excluded Awards (DQ view)]' }),
        card({ title: 'Supplier-ID gap: value left out, NGN (award data)', value: measure(d, '[M-S01 Excluded Value (NGN)]', f), unit: 'NGN',
          measure: '[M-S01 Excluded Value (NGN)]' }),
        card({ title: 'Supplier-ID gap: value left out, NGN (DQ view)', value: measure(d, '[M-S01 Excluded Value (DQ view)]', f), unit: 'NGN',
          measure: '[M-S01 Excluded Value (DQ view)]' }),
      ], 'two-col'),
      h('section', { class: 'panel' }, h('h2', { text: 'Reading these figures' }), caveat(CAVEATS.dataQuality),
        caveat(`DQ-21: ${int(flagged)} awards (NGN ${flaggedBn}bn, ${flaggedPct}% of eligible awarded value) are flagged as possible `
          + 'scale errors. They are kept in every figure; pages 1, 2a and 3 show a sensitivity panel without them, and page 5 has a switch.'))),
    panel('Data-quality issues by metric (counts overlap; they are not additive)', 'The table scrolls to show every issue; the filters apply to this table only',
      table([
        { key: 'metric_id', label: 'Metric' },
        { key: 'dq_ref', label: 'Issue' },
        { key: 'dq_issue', label: 'Description' },
        { key: 'impact_type', label: 'Impact' },
        { key: 'records_with_issue', label: 'Records with issue', num: true, format: int },
        { key: 'pct_of_candidate', label: '% of candidates', num: true, format: (v) => (v == null ? '' : `${v}%`) },
        { key: 'records_lost_only_to_issue', label: 'Lost to this issue only', num: true, format: int },
        { key: 'affected_value_ngn', label: 'Value affected (NGN)', num: true, format: (v) => (v == null ? '' : ngn(decimalToScaled(v, 2))) },
      ], dq, { cls: 'tall', label: 'Data-quality issues' }))));
}
