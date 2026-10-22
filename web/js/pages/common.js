// Shared page parts: number formats for charts and tables, the M-S01 disclosure, the DQ-21 sensitivity panel.

import { formatCompact, formatExact, koboToBillions, roundTo } from '../format.js';
import { measure, rs11a } from '../metrics.js';
import { CAVEATS } from '../text.js';
import { card, cards, h, table } from '../ui.js';

export const pct = (v, places = 2) => (v == null ? '' : `${roundTo(v * 100, places)}%`);
export const pctAxis = (v) => `${Math.round(v * 100)}%`;
export const ngn = (kobo) => (kobo == null ? '' : formatExact(kobo, 'NGN'));
export const ngnCompact = (kobo) => (kobo == null ? '' : formatCompact(kobo, 'NGN'));
export const int = (n) => (n == null ? '' : formatExact(n, 'count'));
export const compact = (n, axis) => (axis ? formatCompact(n, 'count') : int(n));
export const dec = (places) => (v) => (v == null ? '' : roundTo(v, places));

export function labelOf(d, b) {
  return b < 0 ? d.dims.bare_buyer : d.buyerLabels[b];
}

// M-S01 disclosure (the [M-S01 Disclosure] measure): computed from the data under the given filter.
export function supplierDisclosure(d, f) {
  const excluded = measure(d, '[M-S01 Excluded Awards]', f);
  const eligible = measure(d, '[Eligible Awards (n)]', f);
  const value = measure(d, '[M-S01 Excluded Value (NGN)]', f);
  const share = measure(d, '[M-S01 Excluded Value Share]', f);
  const text = `Lower bound: ${int(excluded)} of ${int(eligible)} eligible awards (NGN ${koboToBillions(value, 1)}bn, `
    + `${share == null ? '0.0%' : pct(share, 1)} of eligible award value) have no usable supplier ID and are left out. `
    + 'Suppliers are identified by source ID and are not merged, so true concentration may be higher.';
  return { excluded, eligible, value, share, text };
}

export function disclosurePanel(d, f) {
  const s = supplierDisclosure(d, f);
  return h('section', { class: 'panel' },
    h('h2', { text: 'Supplier coverage disclosure' }),
    h('p', { class: 'disclosure', text: s.text }),
    h('p', { class: 'caveat', text: CAVEATS.supplier }),
    cards([
      card({ title: 'Awards left out', value: s.excluded, n: s.eligible, nLabel: 'Of (n)', resultLabel: 'Left out', measure: '[M-S01 Excluded Awards]' }),
      card({ title: 'Value left out (NGN)', value: s.value, unit: 'NGN', resultLabel: 'Left out', measure: '[M-S01 Excluded Value (NGN)]' }),
      card({ title: 'Share of eligible value', value: s.share, unit: 'share', resultLabel: 'Left out', measure: '[M-S01 Excluded Value Share]' }),
    ], 'three'));
}

// DQ-21 sensitivity panel (decision D-1): fixed figures from the Phase 10.1 result sets, never filtered.
export function flagFootprint(d) {
  const [[n, dropped, sibling, bn, pctOfValue]] = rs11a(d);
  return `${int(n)} awards are flagged as possible scale errors (DQ-21): ${dropped} by the dropped-decimal test and `
    + `${sibling} by the sibling-lot test, NGN ${bn}bn in all, ${pctOfValue}% of eligible awarded value. They are kept in `
    + 'every figure on this page, as published.';
}

export function sensitivityPanel(d, rows, extra = null) {
  return h('section', { class: 'panel sensitivity' },
    h('h2', { text: 'Sensitivity: without awards flagged as possible scale errors (DQ-21)' }),
    h('p', { class: 'sub', text: 'Fixed figures for the whole dataset: this panel does not respond to the filters on this page. '
      + 'Each figure is checked against the Phase 10.1 result sets (see Data checks).' }),
    h('p', { text: flagFootprint(d) }),
    table([
      { key: 'figure', label: 'Figure' },
      { key: 'pub', label: 'As published', num: true },
      { key: 'wo', label: 'Without flagged awards', num: true },
    ], rows, { cls: 'free', label: 'DQ-21 sensitivity' }),
    extra);
}
