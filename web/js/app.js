// Entry point: loads the data (each file verified against data/manifest.json), builds the navigation and renders the
// page named in the URL hash.

import { loadData } from './data.js';
import { disposeAll } from './charts.js';
import { current, goTo, onChange, setParams } from './state.js';
import { CAVEATS, PAGES, SOURCE_LINE } from './text.js';
import { h } from './ui.js';
import * as overview from './pages/overview.js';
import * as suppliers from './pages/suppliers.js';
import * as competition from './pages/competition.js';
import * as budget from './pages/budget.js';
import * as timing from './pages/timing.js';
import * as entities from './pages/entities.js';
import * as implementation from './pages/implementation.js';
import * as dataQuality from './pages/data_quality.js';

const MODULES = { overview, suppliers, competition, budget, timing, entities, implementation, 'data-quality': dataQuality };

const $ = (id) => document.getElementById(id);
let data = null;
let lastPage = null;

function buildShell() {
  $('nav').replaceChildren(...PAGES.map((p) => h('li', {}, h('a', { href: `#${p.id}`, text: p.label, dataset: { page: p.id } }))));
  $('page-menu').replaceChildren(...PAGES.map((p) => h('option', { value: p.id, text: p.label })));
  $('page-menu').addEventListener('change', (e) => goTo(e.target.value));
  $('about-source').textContent = SOURCE_LINE;
  $('about-inline').textContent = `${SOURCE_LINE} Each figure shows the number of records it is based on. Records that do not meet a metric's eligibility rules are excluded from that metric only.`;
  $('footer-caveat').textContent = CAVEATS.footer;

  const toggle = $('theme-toggle');
  const effective = () => document.documentElement.getAttribute('data-theme')
    || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  const label = () => { toggle.textContent = effective() === 'dark' ? 'Light' : 'Dark'; };
  label();
  toggle.addEventListener('click', () => {
    const next = effective() === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    try { localStorage.setItem('theme', next); } catch (e) { /* not saved; applies to this visit */ }
    label();
    render(current());
  });
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => { label(); render(current()); });
}

function render({ page, params }) {
  const meta = PAGES.find((p) => p.id === page);
  document.title = `${meta.title} · Nigeria Procurement Dashboard`;
  $('page-title').textContent = meta.title;
  $('page-question').textContent = meta.question;
  document.querySelectorAll('#nav a').forEach((a) => {
    if (a.dataset.page === page) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current');
  });
  $('page-menu').value = page;

  const scrollY = page === lastPage ? window.scrollY : 0;
  const focused = document.activeElement?.id || null;
  disposeAll();
  const el = h('div', { dataset: { page } });
  const queue = [];
  try {
    MODULES[page].render({ d: data, el, params, set: setParams, after: (fn) => queue.push(fn) });
  } catch (exc) {
    el.replaceChildren(h('div', { class: 'error', text: `This page could not be drawn: ${exc.message}` }));
    console.error(exc);
  }
  $('page').replaceChildren(el);
  queue.forEach((fn) => fn());
  if (page !== lastPage) {
    window.scrollTo(0, 0);
    if (lastPage !== null) $('main').focus({ preventScroll: true });
  } else {
    window.scrollTo(0, scrollY);
    if (focused && document.getElementById(focused)) document.getElementById(focused).focus({ preventScroll: true });
  }
  lastPage = page;
}

async function main() {
  buildShell();
  try {
    data = await loadData('data/');
  } catch (exc) {
    $('page').replaceChildren(h('div', { class: 'error', text: `The data could not be loaded: ${exc.message}` }));
    return;
  }
  onChange(render);
  render(current());
}

main();
