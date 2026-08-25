// ignore_for_file: avoid_print, prefer_const_constructors
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sate_ai/sate_ai.dart';

/// Simple HTTP server for Server-Sent Events (SSE) streaming.
class SSEServer {
  /// Port to listen on.
  final int port;
  HttpServer? _server;
  final List<HttpResponse> _clients = [];

  /// Creates a new [SSEServer] instance.
  SSEServer({this.port = 8080});

  /// Starts the SSE server.
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('SSE Server running on http://localhost:$port');
    print('Open http://localhost:$port to view the dashboard');

    _server!.listen(_handleRequest);
  }

  /// Handles incoming HTTP requests.
  void _handleRequest(HttpRequest request) {
    final path = request.uri.path;

    if (path == '/events') {
      _handleSSE(request);
    } else if (path == '/' || path == '/index.html') {
      _serveDashboard(request);
    } else {
      request.response.statusCode = 404;
      request.response.write('Not Found');
      request.response.close();
    }
  }

  /// Handles Server-Sent Events connections.
  void _handleSSE(HttpRequest request) {
    final response = request.response;
    response.headers
      ..contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..add('Cache-Control', 'no-cache')
      ..add('Connection', 'keep-alive');

    _clients.add(response);

    // Send initial connection message
    response.write(
        'event: connected\ndata: ${jsonEncode({'status': 'connected'})}\n\n');
    response.flush();

    // When client disconnects, remove from list
    unawaited(response.done.then((_) {
      _clients.remove(response);
    }));
  }

  /// Serves the dashboard HTML page.
  void _serveDashboard(HttpRequest request) {
    final response = request.response;
    response.headers.contentType = ContentType.html;
    response.write(_dashboardHtml());
    response.close();
  }

  /// Broadcasts an event to all connected clients.
  void broadcast(StressEvent event) {
    final data = jsonEncode(event.toJson());
    final message = 'event: ${event.type.name}\ndata: $data\n\n';

    for (final client in _clients) {
      try {
        client.write(message);
        client.flush();
      } catch (_) {
        // Client disconnected, will be removed on next write
      }
    }
  }

  /// Closes the server.
  Future<void> close() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
  }

  /// Generates the dashboard HTML.
  String _dashboardHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SATE AI – Real-Time Monitor</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', sans-serif; background: #0f1117; color: #e4e6ed; padding: 20px; }
    .container { max-width: 1200px; margin: 0 auto; }
    header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 12px; }
    header h1 { font-size: 1.8rem; color: #60a5fa; }
    .status-badge { padding: 8px 16px; border-radius: 20px; font-weight: 600; }
    .status-badge.idle { background: #2e3345; color: #a0a5b5; }
    .status-badge.running { background: rgba(96, 165, 250, 0.2); color: #60a5fa; animation: pulse 1s infinite; }
    .status-badge.done { background: rgba(52, 211, 153, 0.2); color: #34d399; }
    .status-badge.error { background: rgba(248, 113, 113, 0.2); color: #f87171; }
    @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
    .progress { background: #1a1d27; border-radius: 8px; padding: 4px; margin-bottom: 24px; border: 1px solid #2e3345; }
    .progress-bar { height: 8px; background: #60a5fa; border-radius: 4px; transition: width 0.3s; width: 0%; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }
    .card { background: #1a1d27; padding: 16px; border-radius: 8px; border: 1px solid #2e3345; }
    .card .label { color: #a0a5b5; font-size: 0.8rem; }
    .card .value { font-size: 1.5rem; font-weight: bold; }
    .card .value.pass { color: #34d399; }
    .card .value.fail { color: #f87171; }
    .logs { background: #1a1d27; padding: 16px; border-radius: 8px; border: 1px solid #2e3345; height: 300px; overflow-y: auto; font-family: 'JetBrains Mono', monospace; font-size: 0.85rem; }
    .logs .log-entry { padding: 4px 0; border-bottom: 1px solid #232733; }
    .logs .log-entry .time { color: #6b7185; margin-right: 8px; }
    .logs .log-entry .level-info { color: #60a5fa; }
    .logs .log-entry .level-success { color: #34d399; }
    .logs .log-entry .level-error { color: #f87171; }
    .result-item { display: flex; justify-content: space-between; padding: 8px 12px; border-bottom: 1px solid #232733; }
    .result-item.pass { border-left: 3px solid #34d399; }
    .result-item.fail { border-left: 3px solid #f87171; }
    .result-item .name { font-weight: 500; }
    .result-item .status-badge { font-size: 0.8rem; padding: 2px 10px; border-radius: 12px; }
    .result-item .status-badge.pass { background: rgba(52, 211, 153, 0.2); color: #34d399; }
    .result-item .status-badge.fail { background: rgba(248, 113, 113, 0.2); color: #f87171; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>🧪 SATE AI – Real-Time Monitor</h1>
      <span class="status-badge idle" id="statusBadge">Idle</span>
    </header>

    <div class="progress"><div class="progress-bar" id="progressBar"></div></div>

    <div class="grid" id="summaryGrid">
      <div class="card"><div class="label">Model</div><div class="value" id="modelName">—</div></div>
      <div class="card"><div class="label">Progress</div><div class="value" id="progressText">0 / 0</div></div>
      <div class="card"><div class="label">Passed</div><div class="value pass" id="passedCount">0</div></div>
      <div class="card"><div class="label">Failed</div><div class="value fail" id="failedCount">0</div></div>
    </div>

    <h3 style="margin-bottom: 8px;">Results</h3>
    <div id="results" style="margin-bottom: 16px; background: #1a1d27; border-radius: 8px; border: 1px solid #2e3345; padding: 8px;"></div>

    <h3 style="margin-bottom: 8px;">Live Logs</h3>
    <div class="logs" id="logs"><div style="color: #6b7185;">Waiting for test to start...</div></div>
  </div>

  <script>
    let eventSource = null;
    let totalInjectors = 0;
    let completedInjectors = 0;

    function connectSSE() {
      eventSource = new EventSource('/events');
      eventSource.onmessage = (e) => {
        const data = JSON.parse(e.data);
        handleEvent(data);
      };
      eventSource.onerror = () => {
        document.getElementById('statusBadge').textContent = 'Disconnected';
        document.getElementById('statusBadge').className = 'status-badge error';
        setTimeout(connectSSE, 3000);
      };
    }

    function handleEvent(data) {
      const type = data.type;

      switch(type) {
        case 'started':
          document.getElementById('statusBadge').textContent = 'Running';
          document.getElementById('statusBadge').className = 'status-badge running';
          document.getElementById('modelName').textContent = data.modelId;
          totalInjectors = data.totalInjectors;
          completedInjectors = 0;
          document.getElementById('progressText').textContent = '0 / ' + totalInjectors;
          break;

        case 'injectorStarting':
          document.getElementById('progressText').textContent = (completedInjectors + 1) + ' / ' + totalInjectors;
          document.getElementById('progressBar').style.width = ((completedInjectors / totalInjectors) * 100) + '%';
          addLog('Starting: ' + data.injectorName, 'info');
          break;

        case 'injectorComplete':
          completedInjectors++;
          document.getElementById('progressBar').style.width = ((completedInjectors / totalInjectors) * 100) + '%';
          if (data.passed) {
            const passed = parseInt(document.getElementById('passedCount').textContent);
            document.getElementById('passedCount').textContent = passed + 1;
          } else {
            const failed = parseInt(document.getElementById('failedCount').textContent);
            document.getElementById('failedCount').textContent = failed + 1;
          }
          addResult(data.injectorName, data.passed, data.inferenceTimeMs, data.memoryUsageMB, data.errorMessage);
          addLog(data.injectorName + ': ' + (data.passed ? 'PASS' : 'FAIL'), data.passed ? 'success' : 'error');
          break;

        case 'injectorError':
          addLog('Error: ' + data.injectorName + ' - ' + data.error, 'error');
          break;

        case 'finished':
          document.getElementById('statusBadge').textContent = data.passed ? 'Done ✅' : 'Failed ❌';
          document.getElementById('statusBadge').className = 'status-badge ' + (data.passed ? 'done' : 'error');
          document.getElementById('progressBar').style.width = '100%';
          addLog('Test finished: ' + data.passedCount + ' passed, ' + data.failedCount + ' failed in ' + data.durationMs + 'ms', 'info');
          break;

        case 'log':
          addLog(data.message, data.level);
          break;
      }
    }

    function addLog(message, level) {
      const logs = document.getElementById('logs');
      const entry = document.createElement('div');
      entry.className = 'log-entry';
      const time = new Date().toLocaleTimeString();
      const levelClass = 'level-' + (level === 'error' ? 'error' : level === 'success' ? 'success' : 'info');
      entry.innerHTML = '<span class="time">[' + time + ']</span><span class="' + levelClass + '">' + message + '</span>';
      logs.appendChild(entry);
      logs.scrollTop = logs.scrollHeight;
      if (logs.children.length > 100) {
        logs.removeChild(logs.children[0]);
      }
    }

    function addResult(name, passed, time, memory, error) {
      const container = document.getElementById('results');
      const div = document.createElement('div');
      div.className = 'result-item ' + (passed ? 'pass' : 'fail');
      div.innerHTML = '<span class="name">' + name + '</span><span class="status-badge ' + (passed ? 'pass' : 'fail') + '">' + (passed ? 'PASS' : 'FAIL') + '</span>';
      container.appendChild(div);
      if (container.children.length > 20) {
        container.removeChild(container.children[0]);
      }
    }

    connectSSE();
  </script>
</body>
</html>
''';
  }
}
