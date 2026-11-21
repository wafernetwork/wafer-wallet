// Wafer Wallet loader. The wallet's code is published as three gzip-compressed files, each in
// small parts (one on-chain blob each): the libraries, the wallet itself, and the QR scanner.
// The libraries and the scanner rarely change, so their parts stay on chain from one version to
// the next and only the wallet's own parts are new. This fetches every part, checks the SHA-256 of
// each file against the values below, and runs the three in order only if all of them match.
// A wrong or tampered part means nothing runs.
(function () {
  "use strict";
  var FILES = [{"name": "libraries", "tag": "49dcc0daceb0", "parts": 3, "sha256": "49dcc0daceb0121fc957b74d8e4d68d4ad28acbda41f5cbbdc163d27fe4610dc"}, {"name": "wallet", "tag": "8b87eabd6d8d", "parts": 5, "sha256": "8b87eabd6d8d22e389c5a9d7fbc88badc0d058c7f308c76eb2f25093165428fc"}, {"name": "scanner", "tag": "1f5660ca2ef3", "parts": 2, "sha256": "1f5660ca2ef3ea45962a8aab06b9ceab2bb51a40bb96667a726ee34aa54ad372"}],
    TAG = "20bdf3d24d7d",
    view = document.getElementById("view");
  if (window.__WW_FRAMED) {
    view.textContent = "";
    return;
  }
  // In a browser this page is the site about the app: the wallet's code is only ever loaded
  // inside the Wafer Wallet app (Android, Mac, Windows), never in a browser.
  if (!document.documentElement.classList.contains("ww-app") || !window.CircuitNative) return;
  start();
  var started = false;
  function start() {
  if (started) return; // once: a second load would ask for the page's one script policy again
  started = true;
  function fail(msg) {
    view.textContent = "";
    var p = document.createElement("p");
    p.className = "danger";
    p.style.margin = "24px 0";
    p.textContent = msg;
    view.appendChild(p);
  }
  // If loading fails, the usual cause is a page that was cached just before an update. Fetch the
  // page again past the cache and reload ONCE; only if that doesn't help is the error shown.
  var KEY = "ww.boot.retry",
    fresh = false;
  try {
    fresh = sessionStorage.getItem(KEY) === TAG;
  } catch (e) {}
  function retryOr(msg) {
    var tried = false;
    try {
      tried = sessionStorage.getItem(KEY) === TAG; // the one retry is per version
      sessionStorage.setItem(KEY, TAG);
    } catch (e) {
      tried = true;
    }
    if (tried) return fail(msg);
    fetch(location.pathname, { cache: "reload" })
      .catch(function () {})
      .then(function () {
        location.reload();
      });
  }
  if (typeof DecompressionStream !== "function") return fail("This device's web view is too old to open the wallet. Update it, then open the app again.");
  var two = function (i) { return (i < 10 ? "0" : "") + i; },
    hexOf = function (d) { return Array.prototype.map.call(new Uint8Array(d), function (x) { return (x < 16 ? "0" : "") + x.toString(16); }).join(""); };
  function part(tag, i) {
    return fetch("parts/" + tag + "-" + two(i) + ".bin", fresh ? { cache: "reload" } : {}).then(function (r) {
      if (!r.ok) throw new Error("part " + tag + "-" + two(i));
      return r.arrayBuffer();
    });
  }
  // one file: its parts, joined, un-gzipped, and checked against its SHA-256
  function file(f) {
    var jobs = [];
    for (var i = 0; i < f.parts; i++) jobs.push(part(f.tag, i));
    return Promise.all(jobs)
      .then(function (bufs) {
        return new Response(new Blob(bufs).stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer().catch(function () { throw new Error("integrity"); }); // not valid gzip: tampered
      })
      .then(function (b) {
        return crypto.subtle.digest("SHA-256", b).then(function (d) {
          if (hexOf(d) !== f.sha256) throw new Error("integrity");
          return b;
        });
      });
  }
  Promise.all(FILES.map(file))
    .then(function (bufs) {
      var url = URL.createObjectURL(new Blob(bufs, { type: "text/javascript" })),
        s = document.createElement("script");
      // Trusted Types: the only script address this page may ever load is the blob just checked
      var tt = window.trustedTypes && window.trustedTypes.createPolicy
        ? window.trustedTypes.createPolicy("wafer-boot", { createScriptURL: function (u) { if (u !== url) throw new TypeError("blocked script"); return u; } })
        : null;
      s.src = tt ? tt.createScriptURL(url) : url;
      s.onload = function () {
        URL.revokeObjectURL(url);
        try { sessionStorage.removeItem(KEY); } catch (e) {}
      };
      s.onerror = function () { fail("Couldn't start the wallet. Reload the page."); };
      document.body.appendChild(s);
    })
    .catch(function (e) {
      retryOr(e && e.message === "integrity" ? "The wallet's code didn't match its fingerprint, so it was not run. Reload the page; if this keeps happening, don't use this site." : "Couldn't load the wallet. Check your connection and reload the page.");
    });
  }
})();
