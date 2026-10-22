// Page and filter state, kept in the URL hash so each view has a shareable link: #page?buyer=…&method=…
// Changing page adds a history entry (the back button works); changing a filter replaces the current one.

import { PAGES } from './text.js';

const listeners = new Set();

export function current() {
  const raw = location.hash.replace(/^#/, '');
  const [pageId, query = ''] = raw.split('?');
  const page = PAGES.find((p) => p.id === pageId) ? pageId : PAGES[0].id;
  return { page, params: Object.fromEntries(new URLSearchParams(query)) };
}

function hashFor(page, params) {
  const q = new URLSearchParams(Object.entries(params).filter(([, v]) => v != null && v !== '')).toString();
  return `#${page}${q ? `?${q}` : ''}`;
}

export function goTo(page) {
  location.hash = hashFor(page, {});
}

// Merge into the current page's filters (null removes a filter).
export function setParams(changes) {
  const { page, params } = current();
  const next = { ...params };
  for (const [k, v] of Object.entries(changes)) {
    if (v == null || v === '') delete next[k];
    else next[k] = String(v);
  }
  history.replaceState(null, '', hashFor(page, next));
  listeners.forEach((fn) => fn(current()));
}

export function onChange(fn) {
  listeners.add(fn);
  window.addEventListener('hashchange', () => fn(current()));
}

// Typed reads with defaults.
export function int(params, key, fallback) {
  const v = Number.parseInt(params[key], 10);
  return Number.isFinite(v) ? v : fallback;
}
