// ECharts setup: colours from the CSS theme, canvas rendering, tooltips drawn on the canvas (renderMode 'richText', so
// no HTML is injected and the Content-Security-Policy needs no inline styles), resize handling.

const live = new Set();
let observer = null;

function css(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

export function themeColours() {
  return { text: css('--chart-text'), grid: css('--chart-grid'), bar: css('--accent'), bar2: css('--accent-2'),
    soft: css('--accent-soft'), surface: css('--surface'), fg: css('--fg') };
}

export function disposeAll() {
  for (const c of live) c.dispose();
  live.clear();
  if (observer) observer.disconnect();
}

function watch(el, chart) {
  if (!observer) observer = new ResizeObserver((entries) => entries.forEach((e) => e.target.chart?.resize()));
  el.chart = chart;
  observer.observe(el);
}

// Create a chart in `el` from an option builder that receives the theme colours.
export function chart(el, build, label) {
  const c = window.echarts.init(el, null, { renderer: 'canvas' });
  const t = themeColours();
  c.setOption({
    animation: false,
    textStyle: { color: t.text, fontFamily: 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif' },
    aria: { enabled: true, label: { description: label } },
    tooltip: { renderMode: 'richText', backgroundColor: t.surface, borderColor: t.grid, textStyle: { color: t.fg } },
    ...build(t),
  });
  el.setAttribute('role', 'img');
  el.setAttribute('aria-label', label);
  live.add(c);
  watch(el, c);
  return c;
}

const axisCommon = (t) => ({ axisLine: { lineStyle: { color: t.grid } }, axisLabel: { color: t.text }, splitLine: { lineStyle: { color: t.grid } } });

// Horizontal bars, largest first (categories listed top to bottom).
export function hbar(el, label, categories, values, fmt, { max = null, tooltip = null } = {}) {
  const narrow = el.clientWidth < 520;
  return chart(el, (t) => ({
    grid: { left: 8, right: 64, top: 8, bottom: 24, containLabel: true },
    xAxis: { type: 'value', max, ...axisCommon(t), splitNumber: narrow ? 2 : 5,
      axisLabel: { color: t.text, formatter: (v) => fmt(v, true), hideOverlap: true } },
    yAxis: { type: 'category', inverse: true, data: categories, ...axisCommon(t),
      axisLabel: { color: t.text, width: narrow ? 130 : 260, overflow: 'truncate' } },
    tooltip: { trigger: 'item', renderMode: 'richText', backgroundColor: t.surface, borderColor: t.grid, textStyle: { color: t.fg },
      formatter: (p) => tooltip ? tooltip(p.dataIndex) : `${p.name}\n${fmt(p.value)}` },
    series: [{ type: 'bar', data: values, itemStyle: { color: t.bar }, barMaxWidth: 18,
      label: { show: true, position: 'right', color: t.text, formatter: (p) => fmt(p.value) } }],
  }), label);
}

// Vertical columns with value labels.
export function columns(el, label, categories, values, fmt, { tooltip = null } = {}) {
  const slot = Math.max(36, Math.floor((el.clientWidth - 60) / Math.max(1, categories.length)) - 6);
  return chart(el, (t) => ({
    grid: { left: 8, right: 8, top: 24, bottom: 8, containLabel: true },
    xAxis: { type: 'category', data: categories, ...axisCommon(t),
      axisLabel: { color: t.text, interval: 0, width: slot, overflow: 'break', fontSize: 11, lineHeight: 13 } },
    yAxis: { type: 'value', ...axisCommon(t), splitNumber: el.clientWidth < 520 ? 3 : 5,
      axisLabel: { color: t.text, formatter: (v) => fmt(v, true), hideOverlap: true } },
    tooltip: { trigger: 'item', renderMode: 'richText', backgroundColor: t.surface, borderColor: t.grid, textStyle: { color: t.fg },
      formatter: (p) => tooltip ? tooltip(p.dataIndex) : `${p.name}\n${fmt(p.value)}` },
    series: [{ type: 'bar', data: values, itemStyle: { color: t.bar }, barMaxWidth: 48,
      label: { show: true, position: 'top', color: t.text, formatter: (p) => fmt(p.value, true) } }],
  }), label);
}

// Line over years, with the n of each point in the tooltip.
export function line(el, label, xs, ys, ns, fmt) {
  return chart(el, (t) => ({
    grid: { left: 8, right: 16, top: 24, bottom: 8, containLabel: true },
    xAxis: { type: 'category', data: xs.map(String), ...axisCommon(t), axisLabel: { color: t.text, hideOverlap: true } },
    yAxis: { type: 'value', ...axisCommon(t), splitNumber: el.clientWidth < 520 ? 3 : 5 },
    tooltip: { trigger: 'item', renderMode: 'richText', backgroundColor: t.surface, borderColor: t.grid, textStyle: { color: t.fg },
      formatter: (p) => `${p.name}: ${fmt(p.value)} (n = ${ns[p.dataIndex].toLocaleString('en')})` },
    series: [{ type: 'line', data: ys, itemStyle: { color: t.bar }, lineStyle: { color: t.bar, width: 2 }, symbolSize: 7,
      label: { show: xs.length <= 10, position: 'top', color: t.text, fontSize: 10, formatter: (p) => fmt(p.value) } }],
  }), label);
}

// Doughnut with the total in the centre.
export function donut(el, label, items, centre, fmt) {
  return chart(el, (t) => {
    const palette = [t.bar, t.bar2, t.soft, t.grid];
    return {
      legend: { bottom: 0, left: 'center', textStyle: { color: t.text }, type: 'plain' },
      title: { text: centre, left: 'center', top: '33%', textStyle: { color: t.fg, fontSize: 22, fontWeight: 'normal' } },
      tooltip: { trigger: 'item', renderMode: 'richText', backgroundColor: t.surface, borderColor: t.grid, textStyle: { color: t.fg },
        formatter: (p) => `${p.name}\n${fmt(p.value)} (${p.percent}%)` },
      series: [{ type: 'pie', radius: ['40%', '58%'], center: ['50%', '40%'], avoidLabelOverlap: true,
        data: items.map((it, i) => ({ ...it, itemStyle: { color: palette[i % palette.length] } })),
        label: { color: t.text, formatter: (p) => `${fmt(p.value)}
${p.percent}%` } }],
    };
  }, label);
}
