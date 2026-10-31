// Landing page: the light/dark toggle, and the figures re-rendered from data/expected.json (the SQL values of the
// reconciliation pack) after its SHA-256 is checked against data/manifest.json. The page's static text already holds
// the same figures, verified by python/web/check_web_data.py, so it reads correctly if the data cannot be loaded.

import { roundTo } from './format.js';

const toggle = document.getElementById('theme-toggle');
const effective = () => document.documentElement.getAttribute('data-theme')
  || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
const label = () => { toggle.textContent = effective() === 'dark' ? 'Light' : 'Dark'; };
label();
toggle.addEventListener('click', () => {
  const next = effective() === 'dark' ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', next);
  try { localStorage.setItem('theme', next); } catch (e) { /* not saved; applies to this visit */ }
  label();
});
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', label);

const grouped = (s) => s.replace(/^(-?\d+)/, (int) => int.replace(/\B(?=(\d{3})+(?!\d))/g, ','));

// The formats of data-format; the Python check formats the same way (half away from zero).
const FORMATS = {
  count: (v) => grouped(roundTo(v, 0)),
  days: (v) => grouped(roundTo(v, 0)),
  pct1: (v) => `${roundTo(Number(v) * 100, 1)}%`,
  ratio2: (v) => roundTo(v, 2),
  index1: (v) => roundTo(v, 1),
  bn1: (v) => `₦${grouped(roundTo(Number(v) / 1e9, 1))}bn`,
};

async function sha256Hex(buffer) {
  const digest = await crypto.subtle.digest('SHA-256', buffer);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function renderFigures() {
  const manifest = await (await fetch('data/manifest.json', { cache: 'no-cache' })).json();
  const buffer = await (await fetch('data/expected.json', { cache: 'no-cache' })).arrayBuffer();
  if ((await sha256Hex(buffer)) !== manifest.files['expected.json'].sha256) {
    throw new Error('expected.json does not match its SHA-256 in manifest.json');
  }
  const pack = new Map(JSON.parse(new TextDecoder('utf-8').decode(buffer)).pack.map((f) => [f.id, f]));
  let changed = 0;
  document.querySelectorAll('[data-fig]').forEach((el) => {
    const fig = pack.get(el.dataset.fig);
    const format = FORMATS[el.dataset.format];
    if (!fig || !format) throw new Error(`unknown figure ${el.dataset.fig} / ${el.dataset.format}`);
    const text = format(el.dataset.field === 'n' ? fig.n : fig.value);
    if (text !== el.textContent) changed += 1;
    el.textContent = text;
  });
  document.body.dataset.figures = changed ? `rendered, ${changed} changed` : 'rendered';
}

renderFigures().catch((exc) => {
  document.body.dataset.figures = 'static';
  console.warn(`Figures shown as written: ${exc.message}`);
});
