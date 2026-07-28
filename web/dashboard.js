/**
 * SATE AI — Stress Test Report Viewer
 *
 * Parses StressReport JSON, renders summary cards, charts (Chart.js),
 * detailed results table, and supports export to JSON / Markdown / CSV.
 */
(function () {
  'use strict';

  // ── SVG icons ─────────────────────────────────────────────────────
  const ICONS = {
    check:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>',
    x:      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>',
    clock:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>',
    cpu:    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>',
    alert:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>',
    gauge:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a10 10 0 1 0 10 10"/><path d="M12 12l5-5"/><circle cx="12" cy="12" r="1"/></svg>',
    globe:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>',
    inbox:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>',
  };

  // ── Fault-type lookup ─────────────────────────────────────────────
  const FAULT_INFO = {
    memoryPressure:  { icon: ICONS.cpu,   name: 'Memory Pressure' },
    malformedInput:  { icon: ICONS.inbox, name: 'Malformed Input' },
    latency:         { icon: ICONS.clock, name: 'Latency' },
    thermalThrottle: { icon: ICONS.gauge, name: 'Thermal Throttle' },
    networkFailure:  { icon: ICONS.globe, name: 'Network Failure' },
  };

  function faultInfo(type) {
    return FAULT_INFO[type] || { icon: ICONS.alert, name: type };
  }

  // ── DOM refs ──────────────────────────────────────────────────────
  const dropZone       = document.getElementById('dropZone');
  const fileInput      = document.getElementById('fileInput');
  const dashboard      = document.getElementById('dashboard');
  const emptyState     = document.getElementById('emptyState');
  const fileNameEl     = document.getElementById('fileName');
  const newReportBtn   = document.getElementById('newReportBtn');
  const newReportInput = document.getElementById('newReportInput');
  const statusBanner   = document.getElementById('statusBanner');
  const statusIcon     = document.getElementById('statusIcon');
  const statusText     = document.getElementById('statusText');
  const summaryCards   = document.getElementById('summaryCards');
  const resultsBody    = document.getElementById('resultsBody');
  const failuresCard   = document.getElementById('failuresCard');
  const failuresBody   = document.getElementById('failuresBody');
  const exportJson     = document.getElementById('exportJson');
  const exportMarkdown = document.getElementById('exportMarkdown');
  const exportCsv      = document.getElementById('exportCsv');

  let inferChart = null;
  let memChart   = null;

  // ── Colours ───────────────────────────────────────────────────────
  const PASS = '#059669';
  const FAIL = '#dc2626';
  const BLUE = '#2563eb';

  // ==================================================================
  // File handling
  // ==================================================================

  dropZone.addEventListener('click', () => fileInput.click());
  dropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropZone.classList.add('drag-over');
  });
  dropZone.addEventListener('dragleave', () => dropZone.classList.remove('drag-over'));
  dropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropZone.classList.remove('drag-over');
    if (e.dataTransfer.files[0]) loadFile(e.dataTransfer.files[0]);
  });
  fileInput.addEventListener('change', () => {
    if (fileInput.files[0]) loadFile(fileInput.files[0]);
  });

  newReportBtn.addEventListener('click', () => {
    localStorage.removeItem('sate-report');
    localStorage.removeItem('sate-report-name');
    newReportInput.click();
  });
  newReportInput.addEventListener('change', () => {
    if (newReportInput.files[0]) loadFile(newReportInput.files[0]);
    newReportInput.value = '';
  });

  function loadFile(file) {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const report = JSON.parse(reader.result);
        fileNameEl.textContent = file.name;
        localStorage.setItem('sate-report', reader.result);
        localStorage.setItem('sate-report-name', file.name);
        render(report);
      } catch (err) {
        alert('Invalid JSON:\n' + err.message);
      }
    };
    reader.readAsText(file);
  }

  function restore() {
    const saved = localStorage.getItem('sate-report');
    const name  = localStorage.getItem('sate-report-name');
    if (saved) {
      try {
        fileNameEl.textContent = name || 'report.json';
        render(JSON.parse(saved));
      } catch (_) { /* ignore corrupt data */ }
    }
  }

  // ==================================================================
  // Render
  // ==================================================================

  function render(report) {
    dropZone.classList.add('hidden');
    emptyState.classList.add('hidden');
    dashboard.classList.remove('hidden');

    // Status
    statusBanner.classList.add('visible');
    if (report.passed) {
      statusBanner.className = 'status-banner visible pass';
      statusIcon.innerHTML = ICONS.check;
      statusText.textContent = 'All injectors passed — no degradation detected';
    } else {
      statusBanner.className = 'status-banner visible fail';
      statusIcon.innerHTML = ICONS.x;
      statusText.textContent = 'One or more injectors caused model degradation';
    }

    // Summary cards
    const s = report.summary || {};
    const results = report.results || [];
    const total  = s.totalTests  ?? results.length;
    const passed = s.passed      ?? results.filter(r => r.passed).length;
    const failed = s.failed      ?? (total - passed);
    const errors = s.unexpectedErrors ?? (report.failures || []).length;

    summaryCards.innerHTML = [
      { label: 'Model',    value: report.modelId ?? '—', cls: 'muted' },
      { label: 'Tests',    value: total,                  cls: 'info' },
      { label: 'Passed',   value: passed,                 cls: 'pass' },
      { label: 'Failed',   value: failed,                 cls: 'fail' },
      { label: 'Errors',   value: errors,                 cls: 'warn' },
      { label: 'Duration', value: (report.totalDurationMs ?? 0) + ' ms', cls: 'muted' },
    ].map(c => `<div class="card ${c.cls}"><div class="value">${esc(c.value)}</div><div class="label">${esc(c.label)}</div></div>`).join('');

    // Results table
    resultsBody.innerHTML = results.map(r => {
      const info = faultInfo(r.injectorType);
      const badge = r.passed ? ICONS.check : ICONS.x;
      return `<tr>
        <td>${info.icon}${esc(info.name)}</td>
        <td><span class="badge ${r.passed ? 'pass' : 'fail'}">${badge}${r.passed ? 'PASS' : 'FAIL'}</span></td>
        <td class="mono">${r.inferenceTimeMs ?? '—'}</td>
        <td class="mono">${r.memoryUsageMB != null ? Number(r.memoryUsageMB).toFixed(1) : '—'}</td>
        <td>${r.errorMessage ? `<span class="error-text">${esc(r.errorMessage)}</span>` : '—'}</td>
      </tr>`;
    }).join('');

    // Unexpected failures
    const failures = report.failures || [];
    if (failures.length) {
      failuresCard.classList.remove('hidden');
      failuresBody.innerHTML = failures.map(f => {
        const info = faultInfo(f.injectorType);
        return `<div class="failure-item"><div class="type">${esc(info.name)}</div><div class="msg">${esc(f.message)}</div></div>`;
      }).join('');
    } else {
      failuresCard.classList.add('hidden');
    }

    // Charts
    renderChart('inferenceChart', results, r => r.inferenceTimeMs ?? 0, r => r.passed ? PASS : FAIL, 'ms');
    renderChart('memoryChart', results, r => r.memoryUsageMB ?? 0, r => (r.memoryUsageMB ?? 0) > 150 ? FAIL : BLUE, 'MB');

    // Export
    exportJson.onclick     = () => download(JSON.stringify(report, null, 2), filename(report, 'json'), 'application/json');
    exportMarkdown.onclick = () => download(toMarkdown(report), filename(report, 'md'), 'text/markdown');
    exportCsv.onclick      = () => download(toCsv(report), filename(report, 'csv'), 'text/csv');
  }

  // ── Chart helper ──────────────────────────────────────────────────

  function renderChart(canvasId, results, valueFn, colorFn, unit) {
    const labels = results.map(r => faultInfo(r.injectorType).name);
    const data   = results.map(valueFn);
    const colors = results.map(colorFn);

    const existing = canvasId === 'inferenceChart' ? inferChart : memChart;
    if (existing) existing.destroy();

    const chart = new Chart(document.getElementById(canvasId).getContext('2d'), {
      type: 'bar',
      data: {
        labels,
        datasets: [{
          data,
          backgroundColor: colors.map(c => c + '22'),
          borderColor: colors,
          borderWidth: 1.5,
          borderRadius: 4,
          barPercentage: 0.6,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: '#1a1d23',
            titleColor: '#fff',
            bodyColor: '#9ca3af',
            borderColor: '#e2e5e9',
            borderWidth: 1,
            padding: 10,
            cornerRadius: 6,
            callbacks: { label: (ctx) => ctx.parsed.y + ' ' + unit },
          },
        },
        scales: {
          x: {
            ticks: { color: '#9ca3af', font: { family: 'Inter', size: 11, weight: '500' } },
            grid: { display: false },
            border: { color: '#e2e5e9' },
          },
          y: {
            beginAtZero: true,
            ticks: { color: '#9ca3af', font: { family: 'JetBrains Mono', size: 11 } },
            grid: { color: '#f1f3f5' },
            border: { display: false },
          },
        },
      },
    });

    if (canvasId === 'inferenceChart') inferChart = chart;
    else memChart = chart;
  }

  // ==================================================================
  // Export
  // ==================================================================

  function toMarkdown(report) {
    const results = report.results || [];
    const lines = [
      '# SATE AI Stress Test Report', '',
      '## Summary', '',
      '| Key | Value |', '|---|---|',
      `| Model | \`${report.modelId ?? '—'}\` |`,
      `| Overall | ${report.passed ? 'PASSED' : 'FAILED'} |`,
      `| Total tests | ${results.length} |`,
      `| Passed | ${results.filter(r => r.passed).length} |`,
      `| Failed | ${results.filter(r => !r.passed).length} |`,
      `| Unexpected errors | ${(report.failures || []).length} |`,
      `| Duration | ${report.totalDurationMs ?? 0} ms |`,
      '', '## Test Results', '',
    ];
    for (const r of results) {
      const info = faultInfo(r.injectorType);
      lines.push(`### ${info.name}`);
      lines.push(`- **Status**: ${r.passed ? 'PASS' : 'FAIL'}`);
      if (r.inferenceTimeMs != null) lines.push(`- **Inference time**: ${r.inferenceTimeMs} ms`);
      if (r.memoryUsageMB != null) lines.push(`- **Memory usage**: ${Number(r.memoryUsageMB).toFixed(1)} MB`);
      if (r.errorMessage) lines.push(`- **Error**: \`${r.errorMessage}\``);
      lines.push('');
    }
    return lines.join('\n');
  }

  function toCsv(report) {
    const rows = [['Injector', 'Status', 'Inference (ms)', 'Memory (MB)', 'Error']];
    for (const r of (report.results || [])) {
      rows.push([
        faultInfo(r.injectorType).name,
        r.passed ? 'PASS' : 'FAIL',
        r.inferenceTimeMs ?? '',
        r.memoryUsageMB != null ? Number(r.memoryUsageMB).toFixed(1) : '',
        r.errorMessage ?? '',
      ]);
    }
    return rows.map(row => row.map(csvEscape).join(',')).join('\n');
  }

  function csvEscape(val) {
    const s = String(val);
    return (s.includes(',') || s.includes('"') || s.includes('\n'))
      ? '"' + s.replace(/"/g, '""') + '"'
      : s;
  }

  function filename(report, ext) {
    const model = (report.modelId || 'report').replace(/[^a-zA-Z0-9_-]/g, '_');
    const ts    = (report.startTime || new Date().toISOString()).replace(/[:.]/g, '-').slice(0, 19);
    return `sate-ai_${model}_${ts}.${ext}`;
  }

  function download(content, name, type) {
    const blob = new Blob([content], { type });
    const url  = URL.createObjectURL(blob);
    const a    = Object.assign(document.createElement('a'), { href: url, download: name });
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  // ── Utility ───────────────────────────────────────────────────────

  function esc(str) {
    const d = document.createElement('div');
    d.textContent = String(str);
    return d.innerHTML;
  }

  restore();
})();
