'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');
const { createApplication } = require('./app');
const { renderSSR } = require('./ssr/render');

// L2-006-package-exports: package.json exposes this server as the sole public package entry.
// L2-007-env-config: PORT lets each project process select its listening port at startup.
const port = Number(process.env.PORT || 18081);
const vueEntry = require.resolve('vue');
const vueDirectory = path.dirname(vueEntry);
const staticFiles = {
  '/src/client.js': path.join(__dirname, 'client.js'),
  '/src/components/TodoApp.vue': path.join(__dirname, 'components/TodoApp.vue'),
  '/src/components/TodoItem.vue': path.join(__dirname, 'components/TodoItem.vue'),
  '/src/components/app-factory.js': path.join(__dirname, 'components/app-factory.js'),
  '/src/store/todos.js': path.join(__dirname, 'store/todos.js'),
  '/src/router/router.js': path.join(__dirname, 'router/router.js'),
  '/src/ssr/hydrate.js': path.join(__dirname, 'ssr/hydrate.js'),
  '/src/styles.css': path.join(__dirname, 'styles.css'),
  '/vendor/vue.global.js': path.join(vueDirectory, 'dist', 'vue.global.js'),
};

function send(response, status, contentType, body) {
  response.writeHead(status, {
    'content-type': contentType,
    'cache-control': 'no-store',
  });
  response.end(body);
}

function escapeJson(value) {
  return JSON.stringify(value).replace(/</g, '\\u003c');
}

async function renderPage(urlPath) {
  const application = createApplication(urlPath);
  let html;
  try {
    html = await renderSSR(application.app);
  } finally {
    // L3-023-leak-audit: release the request's watcher scope on success and failure.
    application.store.dispose();
  }
  const footer = '<!-- Vue SSR output -->';
  return (
    '<!doctype html>' +
    '<html lang="en"><head><meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
    '<title>Devbox todos</title>' +
    '<link rel="stylesheet" href="/src/styles.css">' +
    '<script>window.__INITIAL_PATH__=' +
    escapeJson(urlPath) +
    ';</script>' +
    '</head><body><div id="app">' +
    html +
    '</div>' +
    '<script src="/vendor/vue.global.js"></script>' +
    '<script src="/src/store/todos.js"></script>' +
    '<script src="/src/router/router.js"></script>' +
    '<script src="/src/components/app-factory.js"></script>' +
    '<script src="/src/ssr/hydrate.js"></script>' +
    '<script src="/src/client.js"></script>' +
    footer +
    '</body></html>'
  );
}

const server = http.createServer(async function handleRequest(request, response) {
  const pathname = new URL(request.url, 'http://localhost').pathname;
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    send(response, 405, 'text/plain; charset=utf-8', 'Method not allowed');
    return;
  }
  if (pathname === '/' || pathname === '/about' || /^\/todos\/[^/]+$/.test(pathname)) {
    try {
      send(response, 200, 'text/html; charset=utf-8', await renderPage(pathname));
    } catch (error) {
      console.error('SSR request failed:', error);
      send(response, 500, 'text/plain; charset=utf-8', 'SSR rendering failed');
    }
    return;
  }
  if (pathname === '/favicon.ico') {
    send(response, 204, 'image/x-icon', '');
    return;
  }

  const file = staticFiles[pathname];
  if (!file) {
    send(response, 404, 'text/plain; charset=utf-8', 'Not found');
    return;
  }
  try {
    const contentType = file.endsWith('.css')
      ? 'text/css; charset=utf-8'
      : file.endsWith('.vue')
        ? 'text/plain; charset=utf-8'
        : 'text/javascript; charset=utf-8';
    send(response, 200, contentType, fs.readFileSync(file));
  } catch (error) {
    console.error('Static file request failed:', error);
    send(response, 500, 'text/plain; charset=utf-8', 'Static file unavailable');
  }
});

server.listen(port, '0.0.0.0', function onListen() {
  console.error('Vue todo SSR listening on port ' + port);
});

server.on('error', function onServerError(error) {
  console.error('HTTP server failed:', error);
  process.exitCode = 1;
});

process.on('SIGINT', function closeOnInterrupt() {
  server.close(function exitAfterInterrupt() {
    process.exit(0);
  });
});

process.on('SIGTERM', function closeOnTerminate() {
  server.close(function exitAfterTerminate() {
    process.exit(0);
  });
});
