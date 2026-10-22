// Loads and decodes the dashboard data (web/data/*.json, written by python/web/export_web_data.py).
//
// Fact files are columnar ({column: [values]}). Buyers and methods are indices into dims.json; buyer -1 is the bare
// ID NG-BPP- (DQ-19), which counts in totals but has no entry in the entity list. Money is integer kobo: each value
// is below 2^53 and exact as a JSON number, and totals are summed as BigInt (see metrics.js).

const FILES = ['dims', 'lifecycle', 'budget', 'competition', 'awards', 'suppliers', 'budget_award',
  'tender_duration', 'award_lag', 'signature_lag', 'contracts', 'entities', 'registers', 'expected'];

async function sha256Hex(buffer) {
  const digest = await crypto.subtle.digest('SHA-256', buffer);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

// Fetch every file named in the manifest; with verify, each file's SHA-256 must match the manifest.
export async function loadData(base = 'data/', { verify = true } = {}) {
  const manifest = await (await fetch(`${base}manifest.json`, { cache: 'no-cache' })).json();
  const raw = {};
  await Promise.all(FILES.map(async (name) => {
    const entry = manifest.files[`${name}.json`];
    if (!entry) throw new Error(`${name}.json is not in the manifest`);
    const buffer = await (await fetch(`${base}${name}.json`, { cache: 'no-cache' })).arrayBuffer();
    if (verify && (await sha256Hex(buffer)) !== entry.sha256) {
      throw new Error(`${name}.json does not match its SHA-256 in manifest.json`);
    }
    raw[name] = JSON.parse(new TextDecoder('utf-8').decode(buffer));
  }));
  return makeData(raw, manifest);
}

// Build the in-memory data object from the parsed files (also used by tests that read the files directly).
export function makeData(raw, manifest = null) {
  const d = { ...raw, manifest };
  d.buyerIds = raw.dims.buyers.map((b) => b[0]);
  d.buyerLabels = raw.dims.buyers.map((b) => b[1]);
  d.buyerNames = raw.dims.buyers.map((b) => b[2]);
  d.buyerIndex = new Map(d.buyerIds.map((id, i) => [id, i]));
  d.methods = raw.dims.methods;
  d.methodIndex = new Map(d.methods.map((m, i) => [m, i]));
  d.tenderStatusIndex = new Map(raw.dims.tender_statuses.map((s, i) => [s, i]));
  d.contractStatusIndex = new Map(raw.dims.contract_statuses.map((s, i) => [s, i]));
  return d;
}

export function buyerId(d, b) {
  return b < 0 ? d.dims.bare_buyer : d.buyerIds[b];
}

export function tableLength(t) {
  return Object.values(t)[0].length;
}

// Row indices of a fact table that pass the filter. A filter field applies only to tables that carry it, as the
// Power BI slicers do: budgets, lifecycle, contracts and signature lag carry no procurement method, so a method
// filter leaves them unchanged.
//   filter = { buyer, method, tenderStatus, contractStatus, tenderStartYear, awardYear, dq21: 'exclude' }
export function rows(d, table, filter = {}) {
  const t = d[table];
  const n = tableLength(t);
  const tests = [];
  if (filter.buyer != null && t.b) {
    const b = d.buyerIndex.has(filter.buyer) ? d.buyerIndex.get(filter.buyer) : (filter.buyer === d.dims.bare_buyer ? -1 : -2);
    tests.push((i) => t.b[i] === b);
  }
  if (filter.method != null && t.m) {
    const m = d.methodIndex.get(filter.method);
    tests.push((i) => t.m[i] === m);
  }
  if (filter.tenderStatus != null && table === 'competition') {
    const s = d.tenderStatusIndex.get(filter.tenderStatus);
    tests.push((i) => t.s[i] === s);
  }
  if (filter.contractStatus != null && table === 'contracts') {
    const s = d.contractStatusIndex.get(filter.contractStatus);
    tests.push((i) => t.s[i] === s);
  }
  if (filter.tenderStartYear != null && table === 'tender_duration') {
    tests.push((i) => t.y[i] === filter.tenderStartYear);
  }
  if (filter.awardYear != null && table === 'award_lag') {
    tests.push((i) => t.y[i] === filter.awardYear);
  }
  if (filter.dq21 === 'exclude' && (table === 'awards' || table === 'budget_award')) {
    tests.push((i) => !t.f[i]);
  }
  const out = [];
  for (let i = 0; i < n; i += 1) {
    if (tests.every((test) => test(i))) out.push(i);
  }
  return out;
}

export function pick(column, idx) {
  return idx.map((i) => column[i]);
}
