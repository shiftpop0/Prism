const http = require("http");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

const frontendPort = Number(process.env.FRONTEND_PORT || "5173");
const frontendHost = process.env.FRONTEND_HOST || "0.0.0.0";
const backendTarget = process.env.BACKEND_TARGET || "http://127.0.0.1:8081";
const staticDir = process.env.PRISM_FRONTEND_DIST || path.join(__dirname, "dist");

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
};

function send(res, code, body, contentType) {
  res.writeHead(code, { "Content-Type": contentType || "text/plain; charset=utf-8" });
  res.end(body);
}

function proxyApi(req, res) {
  const base = new URL(backendTarget);
  const options = {
    protocol: base.protocol,
    hostname: base.hostname,
    port: base.port,
    method: req.method,
    path: req.url,
    headers: { ...req.headers, host: base.host },
  };
  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
    proxyRes.pipe(res);
  });
  proxyReq.on("error", (err) => send(res, 502, "proxy error: " + err.message));
  req.pipe(proxyReq);
}

function serveStatic(req, res) {
  let pathname = req.url || "/";
  if (pathname.includes("?")) pathname = pathname.split("?")[0];
  if (pathname === "/") pathname = "/index.html";
  const normalized = path.normalize(pathname).replace(/^(\.\.[\\/])+/, "");
  let filePath = path.join(staticDir, normalized);
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(staticDir, "index.html");
  }
  fs.readFile(filePath, (err, data) => {
    if (err) return send(res, 404, "not found");
    const ext = path.extname(filePath).toLowerCase();
    send(res, 200, data, MIME[ext] || "application/octet-stream");
  });
}

const server = http.createServer((req, res) => {
  if (!req.url) return send(res, 400, "bad request");
  if (req.url.startsWith("/api/")) return proxyApi(req, res);
  return serveStatic(req, res);
});

server.listen(frontendPort, frontendHost, () => {
  console.log(`[frontend] static+proxy server listening on http://${frontendHost}:${frontendPort}`);
  console.log(`[frontend] proxy target: ${backendTarget}`);
});
