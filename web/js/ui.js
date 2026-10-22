// DOM building blocks: cards, panels, tables and controls. Text is always set with textContent, and sizes with the
// CSSOM, so no markup is built from data and the Content-Security-Policy needs no inline styles.

import { formatCompact, formatExact, roundTo } from './format.js';

export function h(tag, attrs = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k === 'text') el.textContent = v;
    else if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
    else if (k === 'dataset') Object.assign(el.dataset, v);
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (const c of children.flat()) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}

// Value shown on a card, in the style of the Power BI cards (98K, 93T, 44.04%, 0.9298).
export function cardText(value, unit) {
  if (value == null) return '(blank)';
  switch (unit) {
    case 'share': return `${roundTo(value * 100, 2)}%`;
    case 'ratio': return roundTo(value, 4);
    case 'index': return roundTo(value, 1);
    case 'days': return roundTo(value, 1);
    case 'median': return roundTo(value, 1);
    case 'NGN': return formatCompact(value, 'NGN');
    default: return Number(value) >= 1000 ? formatCompact(value, 'count') : String(value);
  }
}

function exactText(value, unit) {
  if (unit === 'median') return formatExact(value, 'count');
  return formatExact(value, unit);
}

// A card: title, result and (optionally) the number of records it is based on. The exact value is in the tooltip,
// in data-value (raw: kobo for NGN) and shown in place on click or Enter.
export function card({ title, value, unit = 'count', n = null, nLabel = 'Records (n)', measure = null, params = null,
  resultLabel = 'Result', timing = false }) {
  const shown = cardText(value, unit);
  const exact = value == null ? '(blank)' : exactText(value, unit);
  const nExact = n == null ? null : formatExact(n, 'count');
  const vEl = h('div', { class: 'v', text: shown });
  const nEl = n == null ? null : h('div', { class: 'v', text: cardText(n, 'count') });
  const el = h('div', {
    class: `card${timing ? ' timing' : ''}`, tabindex: '0', role: 'button',
    title: `${title}: ${exact}${nExact ? ` (n = ${nExact})` : ''}`,
    'aria-label': `${title}: ${exact}${nExact ? `, based on ${nExact} records` : ''}. Press to show the exact value.`,
    dataset: { value: value == null ? '' : String(value), unit: unit === 'median' ? 'count' : unit,
      ...(measure ? { measure } : {}), ...(params ? { params: JSON.stringify(params) } : {}), ...(n != null ? { n: String(n) } : {}) },
  },
  h('p', { class: 'card-title', text: title }),
  h('div', { class: 'card-body' },
    h('div', { class: 'card-cell' }, h('div', { class: 'k', text: resultLabel }), vEl),
    nEl ? h('div', { class: 'card-cell n' }, h('div', { class: 'k', text: nLabel }), nEl) : null));
  const toggle = () => {
    const on = el.classList.toggle('exact');
    vEl.textContent = on ? exact : shown;
    if (nEl) nEl.textContent = on ? nExact : cardText(n, 'count');
  };
  el.addEventListener('click', toggle);
  el.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); } });
  return el;
}

export function cards(list, cls = '') {
  return h('div', { class: `cards ${cls}` }, list);
}

export function panel(title, subtitle, ...body) {
  return h('section', { class: 'panel' }, h('h2', { text: title }), subtitle ? h('p', { class: 'sub', text: subtitle }) : null, ...body);
}

export function grid(cls, ...children) {
  return h('div', { class: `grid ${cls}` }, ...children);
}

export function caveat(text) {
  return h('p', { class: 'caveat', text });
}

// Table. columns: [{ key, label, num, bar, format(value, row) }]. A bar column draws a fill proportional to the
// largest absolute value in the column.
export function table(columns, rows, { cls = '', label = '', empty = 'No rows for this selection.' } = {}) {
  if (!rows.length) return h('p', { class: 'empty', text: empty });
  const maxOf = {};
  for (const c of columns.filter((x) => x.bar)) {
    maxOf[c.key] = Math.max(...rows.map((r) => Math.abs(Number(r[c.key] ?? 0))), 0);
  }
  const head = h('thead', {}, h('tr', {}, columns.map((c) => h('th', { class: c.num ? 'num' : null, scope: 'col', text: c.label }))));
  const body = h('tbody', {}, rows.map((r) => h('tr', {}, columns.map((c) => {
    const raw = r[c.key];
    const text = c.format ? c.format(raw, r) : (raw ?? '');
    if (c.bar) {
      const fill = h('div', { class: 'fill' });
      const max = maxOf[c.key];
      fill.style.width = `${max ? Math.round((Math.abs(Number(raw ?? 0)) / max) * 100) : 0}%`;
      return h('td', { class: 'num bar' }, fill, h('span', { text }));
    }
    return h('td', { class: c.num ? 'num' : null, text });
  }))));
  return h('div', { class: `table-wrap ${cls}`, role: 'region', 'aria-label': label || 'Table', tabindex: '0' },
    h('table', {}, head, body));
}

// ---------------------------------------------------------------- controls

let uid = 0;

export function selectControl(label, options, value, onChange, { wide = false } = {}) {
  const id = `c${uid += 1}`;
  const sel = h('select', { id, onchange: (e) => onChange(e.target.value) },
    options.map(([v, text]) => h('option', { value: v, text, selected: String(v) === String(value ?? '') })));
  return h('div', { class: `control${wide ? ' wide' : ''}` }, h('label', { for: id, text: label }), sel);
}

export function numberControl(label, value, min, max, onChange, hint = '') {
  const id = `c${uid += 1}`;
  const input = h('input', { id, type: 'number', min: String(min), max: String(max), step: '1', value: String(value),
    inputmode: 'numeric',
    onchange: (e) => {
      const v = Math.min(max, Math.max(min, Math.round(Number(e.target.value) || value)));
      e.target.value = String(v);
      onChange(v);
    } });
  return h('div', { class: 'control' }, h('label', { for: id, text: label }), input, hint ? h('span', { class: 'hint', text: hint }) : null);
}

export function checkControl(label, checked, onChange) {
  const id = `c${uid += 1}`;
  return h('div', { class: 'control check wide' },
    h('input', { id, type: 'checkbox', checked, onchange: (e) => onChange(e.target.checked) }),
    h('label', { for: id, text: label }));
}

// Searchable procuring-entity input: a native datalist keyed on the label, which carries the buyer ID.
export function entityControl(d, buyerIdValue, onChange) {
  const id = `c${uid += 1}`;
  const listId = `${id}-list`;
  const byLabel = new Map(d.buyerLabels.map((l, i) => [l, d.buyerIds[i]]));
  const current = buyerIdValue != null && d.buyerIndex.has(buyerIdValue) ? d.buyerLabels[d.buyerIndex.get(buyerIdValue)] : '';
  const input = h('input', { id, type: 'search', list: listId, value: current, placeholder: 'All entities (type to search)',
    autocomplete: 'off', spellcheck: 'false' });
  const commit = () => {
    const v = input.value.trim();
    if (!v) { if (buyerIdValue != null) onChange(null); return; }
    if (byLabel.has(v)) { if (byLabel.get(v) !== buyerIdValue) onChange(byLabel.get(v)); return; }
    const matches = d.buyerLabels.filter((l) => l.toLowerCase().includes(v.toLowerCase()));
    if (matches.length === 1) onChange(byLabel.get(matches[0]));
  };
  input.addEventListener('change', commit);
  input.addEventListener('keydown', (e) => { if (e.key === 'Enter') commit(); });
  const clear = h('button', { type: 'button', text: 'All', 'aria-label': 'Show all entities',
    onclick: () => { input.value = ''; onChange(null); } });
  const list = h('datalist', { id: listId }, d.buyerLabels.map((l) => h('option', { value: l })).sort((a, b) => (a.value < b.value ? -1 : 1)));
  return h('div', { class: 'control wide' }, h('label', { for: id, text: 'Procuring entity' }),
    h('div', { class: 'row' }, input, clear), list);
}

export function methodControl(d, value, onChange) {
  return selectControl('Procurement method', [['', 'All'], ...[...d.methods].sort().map((m) => [m, m])], value ?? '',
    (v) => onChange(v || null));
}

export function topNControl(value, onChange, label = 'Top N (default 10)') {
  return numberControl(label, value, 1, 100, onChange);
}
