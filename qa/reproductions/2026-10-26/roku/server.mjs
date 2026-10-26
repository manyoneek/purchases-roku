import http from "node:http";
import https from "node:https";
import fs from "node:fs";
import path from "node:path";
const root = path.join(path.dirname(new URL(import.meta.url).pathname), "web");
const logFile = process.env.REQUEST_LOG;
const port = Number(process.env.PORT || 8787);
const types = { ".html": "text/html", ".js": "text/javascript", ".zip": "application/zip", ".wasm": "application/wasm" };
function log(entry) { if (logFile) fs.appendFileSync(logFile, JSON.stringify({ at: new Date().toISOString(), ...entry }) + "\n"); }
http.createServer((req, res) => {
  const url = new URL(req.url, "http://localhost");
  if (url.pathname.startsWith("/offline/")) {
    log({ route: "offline", method: req.method, path: url.pathname, result: "connection closed without a response" });
    req.socket.destroy();
    return;
  }
  if (url.pathname.startsWith("/rc/v1/")) {
    const target = new URL("https://api.revenuecat.com" + url.pathname.slice(3) + url.search);
    const headers = {};
    for (const [k, v] of Object.entries(req.headers)) if (k === "authorization" || k === "content-type" || k.startsWith("x-")) headers[k] = v;
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      const upstream = https.request(target, { method: req.method, headers }, (up) => {
        const body = [];
        up.on("data", (c) => body.push(c));
        up.on("end", () => {
          log({ route: "pass-through", method: req.method, path: target.pathname, status: up.statusCode, platform: headers["x-platform"] });
          res.writeHead(up.statusCode, { "content-type": up.headers["content-type"] || "application/json", "cross-origin-resource-policy": "same-origin" });
          res.end(Buffer.concat(body));
        });
      });
      upstream.on("error", (e) => { log({ route: "pass-through", error: e.message }); res.writeHead(502); res.end(); });
      upstream.end(Buffer.concat(chunks));
    });
    return;
  }
  const file = path.join(root, url.pathname === "/" ? "index.html" : url.pathname);
  if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { console.log("404 " + url.pathname); res.writeHead(404); res.end(); return; }
  res.writeHead(200, { "content-type": types[path.extname(file)] || "application/octet-stream", "cross-origin-opener-policy": "same-origin", "cross-origin-embedder-policy": "require-corp", "cross-origin-resource-policy": "same-origin" });
  fs.createReadStream(file).pipe(res);
}).listen(port, () => console.log("listening " + port));
