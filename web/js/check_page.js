// Runs the data self-check on check.html and shows the result.
import { loadData } from './data.js';
import { runChecks } from './check.js';

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const result = (ok) => `<td class="${ok ? 'pass' : 'fail'}">${ok ? 'PASS' : 'FAIL'}</td>`;
const summary = document.getElementById('summary');

try {
  const t0 = performance.now();
  const d = await loadData('data/');
  const { figures, cells } = runChecks(d);
  const ms = Math.round(performance.now() - t0);
  const fOk = figures.filter((x) => x.ok).length;
  const cOk = cells.filter((x) => x.ok).length;
  const allOk = fOk === figures.length && cOk === cells.length;
  summary.className = allOk ? 'pass' : 'fail';
  summary.textContent = `${allOk ? 'PASS' : 'FAIL'}: figures ${fOk}/${figures.length} PASS; DQ-21 sensitivity ${cOk}/${cells.length} cells PASS; `
    + `${Object.keys(d.manifest.files).length} data files verified against manifest SHA-256`;
  document.getElementById('meta').textContent = `Data exported ${d.manifest.generated_at} (role ${d.manifest.role}); `
    + `expected.json SHA-256 ${d.manifest.files['expected.json'].sha256.slice(0, 16)}…; loaded and checked in ${ms} ms; `
    + `${navigator.userAgent}`;
  document.querySelector('#figures tbody').innerHTML = figures.map((f) => `<tr data-ok="${f.ok}"><td>${esc(f.id)}</td><td>${esc(f.figure)}</td>`
    + `<td>${esc(f.slice)}</td><td class="num">${esc(f.sql)}</td><td class="num">${esc(f.web)}</td>${result(f.ok)}</tr>`).join('');
  document.querySelector('#cells tbody').innerHTML = cells.map((c) => `<tr data-ok="${c.ok}"><td>${esc(c.key)}</td><td class="num">${c.row}</td>`
    + `<td>${esc(c.col)}</td><td class="num">${esc(c.sql)}</td><td class="num">${esc(c.web)}</td>${result(c.ok)}</tr>`).join('');
  document.body.dataset.result = allOk ? 'pass' : 'fail';
} catch (exc) {
  summary.className = 'fail';
  summary.textContent = `FAIL: ${exc.message}`;
  document.body.dataset.result = 'error';
}
document.getElementById('only-fail').addEventListener('change', (e) => {
  document.querySelectorAll('tbody tr').forEach((tr) => { tr.hidden = e.target.checked && tr.dataset.ok === 'true'; });
});
