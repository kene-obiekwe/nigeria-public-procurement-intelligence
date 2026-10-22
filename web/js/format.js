// Number formats and exact rounding.
//
// Rounding is half away from zero, as PostgreSQL round() and the reconciliation log. Money is handled as BigInt
// kobo so totals larger than 2^53 kobo stay exact. Other values are rounded from their 15-significant-digit decimal
// form, which removes binary floating-point noise (0.92975 stored as 0.929749999...) before the decision is made.

const PLACES = { share: 4, ratio: 4, index: 1, NGN: 0, days: 1, count: 1 };

export function unitPlaces(unit) {
  return PLACES[unit];
}

// BigInt division rounded half away from zero.
export function roundDiv(a, b) {
  const neg = (a < 0n) !== (b < 0n);
  const [x, y] = [a < 0n ? -a : a, b < 0n ? -b : b];
  const q = (2n * x + y) / (2n * y);
  return neg ? -q : q;
}

// Exact decimal string -> BigInt scaled by 10^places, rounded half away from zero.
export function decimalToScaled(text, places) {
  const s = String(text).trim();
  const neg = s.startsWith('-');
  const [int, frac = ''] = s.replace(/^[-+]/, '').split('.');
  const digits = BigInt(int + frac || '0');
  const scale = 10n ** BigInt(frac.length);
  const target = 10n ** BigInt(places);
  const v = roundDiv(digits * target, scale);
  return neg ? -v : v;
}

// BigInt scaled by 10^places -> decimal string.
export function scaledToString(v, places) {
  const neg = v < 0n;
  let s = (neg ? -v : v).toString().padStart(places + 1, '0');
  if (places > 0) s = `${s.slice(0, -places)}.${s.slice(-places)}`;
  return (neg && /[1-9]/.test(s) ? '-' : '') + s;
}

// A number's 15-significant-digit form as a plain decimal string (no exponent).
function plainDecimal(x) {
  const [mant, exp = '0'] = x.toPrecision(15).split('e');
  const neg = mant.startsWith('-');
  const [int, frac = ''] = mant.replace('-', '').split('.');
  const e = Number(exp);
  const digits = int + frac;
  const point = int.length + e;
  let s;
  if (point <= 0) s = `0.${'0'.repeat(-point)}${digits}`;
  else if (point >= digits.length) s = digits + '0'.repeat(point - digits.length);
  else s = `${digits.slice(0, point)}.${digits.slice(point)}`;
  return (neg ? '-' : '') + s;
}

// Round a number (or BigInt, or exact decimal string) half away from zero; returns a decimal string.
export function roundTo(x, places) {
  if (x == null) return null;
  if (typeof x === 'bigint') return scaledToString(x * 10n ** BigInt(places), places);
  if (typeof x === 'string') return scaledToString(decimalToScaled(x, places), places);
  if (!Number.isFinite(x)) return null;
  return scaledToString(decimalToScaled(plainDecimal(x), places), places);
}

// Kobo (BigInt, or a Number for medians that may fall between two kobo values) -> naira rounded to `places`.
export function koboToNaira(kobo, places = 0) {
  if (kobo == null) return null;
  if (typeof kobo === 'bigint') return scaledToString(roundDiv(kobo * 10n ** BigInt(places), 100n), places);
  return roundTo(kobo / 100, places);
}

// Kobo -> NGN billions rounded to `places` (as round(value / 1e9, places) in SQL).
export function koboToBillions(kobo, places) {
  return scaledToString(roundDiv(BigInt(kobo), 10n ** BigInt(11 - places)), places);
}

// 100 * a / b for BigInts, rounded to `places`, exact.
export function percentOf(a, b, places) {
  return scaledToString(roundDiv(100n * BigInt(a) * 10n ** BigInt(places), BigInt(b)), places);
}

function groupThousands(text) {
  const [int, frac] = text.split('.');
  const neg = int.startsWith('-');
  const digits = neg ? int.slice(1) : int;
  const grouped = digits.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return (neg ? '-' : '') + grouped + (frac != null ? `.${frac}` : '');
}

// Exact display, as in dashboard/reconciliation_log.md. NGN values are kobo.
export function formatExact(value, unit) {
  if (value == null) return '(blank)';
  switch (unit) {
    case 'share': return `${roundTo(typeof value === 'number' ? value * 100 : value, 2)}%`;
    case 'ratio': return roundTo(value, 4);
    case 'index': return roundTo(value, 1);
    case 'NGN': return groupThousands(koboToNaira(value, 0));
    case 'days': return groupThousands(roundTo(value, 1).replace(/\.0$/, ''));
    default: {
      const r = roundTo(value, 1);
      return groupThousands(r.endsWith('.0') ? r.slice(0, -2) : r);
    }
  }
}

// Compact display for cards (98K, 93T); NGN values are kobo.
export function formatCompact(value, unit) {
  if (value == null) return '(blank)';
  if (unit === 'share') return `${roundTo(value * 100, 1)}%`;
  if (unit === 'ratio') return roundTo(value, 2);
  let v = unit === 'NGN' ? Number(value) / 100 : Number(value);
  const neg = v < 0;
  v = Math.abs(v);
  const steps = [[1e12, 'T'], [1e9, 'bn'], [1e6, 'M'], [1e3, 'K']];
  for (const [size, suffix] of steps) {
    if (v >= size) {
      const r = v / size;
      return `${neg ? '-' : ''}${roundTo(r, r >= 100 ? 0 : 1).replace(/\.0$/, '')}${suffix}`;
    }
  }
  return `${neg ? '-' : ''}${roundTo(v, unit === 'days' || unit === 'count' ? 1 : 0).replace(/\.0$/, '')}`;
}
