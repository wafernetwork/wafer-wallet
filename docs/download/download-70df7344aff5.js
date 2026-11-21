// Wafer Wallet download pages: copy buttons and "for this device" highlight, and the app downloads below.
(function () {
  "use strict";
  if (window.__WW_FRAMED) return;
  // every install command has its own Copy button, next to it
  Array.prototype.forEach.call(document.querySelectorAll(".cmd"), function (box) {
    var btn = box.querySelector("button"),
      cmd = box.querySelector("code");
    if (!btn || !cmd) return;
    btn.addEventListener("click", function () {
      var done = function (ok) {
        btn.textContent = ok ? "Copied" : "Select and copy";
        setTimeout(function () { btn.textContent = "Copy"; }, 1800);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(cmd.textContent).then(function () { done(true); }, function () { done(false); });
      else done(false);
      var r = document.createRange();
      r.selectNodeContents(cmd);
      var sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(r);
    });
  });
  var ua = navigator.userAgent || "",
    os = /Android/i.test(ua) ? "android" : /Windows NT/i.test(ua) ? "windows" : /Macintosh|Mac OS X/i.test(ua) && !/iPhone|iPad|iPod/i.test(ua) && !(navigator.maxTouchPoints > 1) ? "mac" : "";
  if (!os) return;
  var pick = document.querySelector('.picker a[data-os="' + os + '"]');
  if (pick) pick.classList.add("here");
  var first = document.querySelector('.card[data-os="' + os + '"]');
  if (first) {
    first.classList.add("here");
    // put this device's option first (the Mac cards already are)
    var top = document.querySelector(".card");
    if (top !== first) top.parentNode.insertBefore(first, top);
  }
})();

// The Android app is published on BNB Chain in parts (no single on-chain file can hold it). To keep
// updates cheap, an earlier version (the base) stays on chain and a newer one is published as a
// small patch against it. This fetches the parts, rebuilds the app, checks the SHA-256 of the
// result against the one on this page, and only then saves it.
(function () {
  "use strict";
  if (window.__WW_FRAMED) return;
  var a = document.getElementById("apk");
  if (!a) return;
  var label = document.getElementById("apkLabel"), err = document.getElementById("apkErr"), busy = false;
  var N = +a.getAttribute("data-parts"), TAG = a.getAttribute("data-tag"), PN = +(a.getAttribute("data-patch-parts") || 0), PTAG = a.getAttribute("data-patch-tag"), SHA = a.getAttribute("data-sha");
  var pad = function (i) { return (i < 10 ? "0" : "") + i; };
  function hex(buf) { return Array.prototype.map.call(new Uint8Array(buf), function (x) { return (x < 16 ? "0" : "") + x.toString(16); }).join(""); }
  function sha(u8) { return crypto.subtle.digest("SHA-256", u8).then(hex); }
  function join(bufs) { var n = 0, o = 0; bufs.forEach(function (b) { n += b.byteLength; }); var u = new Uint8Array(n); bufs.forEach(function (b) { u.set(new Uint8Array(b), o); o += b.byteLength; }); return u; }
  function gunzip(u8) { return new Response(new Blob([u8]).stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer().then(function (b) { return new Uint8Array(b); }); }
  // the patch (wwbsd.py): "WWBSD1\0\0", sizes, SHA-256 of base and result, then three gzip streams
  function patch(old, p) {
    var v = new DataView(p.buffer, p.byteOffset, p.byteLength);
    if (String.fromCharCode.apply(null, p.subarray(0, 6)) !== "WWBSD1") throw new Error("patch");
    var ol = v.getUint32(8, true), nl = v.getUint32(12, true), a1 = v.getUint32(16, true), b1 = v.getUint32(20, true), c1 = v.getUint32(24, true);
    if (old.length !== ol) throw new Error("base");
    return sha(old).then(function (h) {
      if (h !== hex(p.subarray(28, 60))) throw new Error("base");
      var o = 92;
      return Promise.all([gunzip(p.subarray(o, o + a1)), gunzip(p.subarray(o + a1, o + a1 + b1)), gunzip(p.subarray(o + a1 + b1, o + a1 + b1 + c1))]);
    }).then(function (s) {
      var ctrl = new DataView(s[0].buffer), diff = s[1], extra = s[2], out = new Uint8Array(nl), np = 0, op = 0, dp = 0, ep = 0;
      for (var i = 0; i + 12 <= ctrl.byteLength; i += 12) {
        var x = ctrl.getInt32(i, true), y = ctrl.getInt32(i + 4, true), z = ctrl.getInt32(i + 8, true);
        if (x < 0 || y < 0 || np + x + y > nl) throw new Error("patch");
        for (var k = 0; k < x; k++) { var q = op + k; out[np + k] = (diff[dp + k] + (q >= 0 && q < ol ? old[q] : 0)) & 255; }
        np += x; dp += x; op += x;
        out.set(extra.subarray(ep, ep + y), np); np += y; ep += y; op += z;
      }
      if (np !== nl) throw new Error("patch");
      return out;
    });
  }
  function fetchParts(n, name) {
    var jobs = [];
    for (var i = 0; i < n; i++) jobs.push(fetch("apk/" + name(i)).then(function (r) { if (!r.ok) throw new Error("part"); return r.arrayBuffer(); }).then(function (b) { got++; label.textContent = "Downloading… " + Math.round((got / (N + PN)) * 100) + "%"; return b; }));
    return Promise.all(jobs).then(join);
  }
  var got = 0;
  a.addEventListener("click", function (e) {
    e.preventDefault();
    if (busy) return;
    busy = true; got = 0; err.textContent = "";
    label.textContent = "Downloading… 0%";
    Promise.all([fetchParts(N, function (i) { return TAG + "-" + pad(i) + ".bin"; }), PN ? fetchParts(PN, function (i) { return PTAG + "-p" + pad(i) + ".bin"; }) : null])
      .then(function (r) { if (!r[1]) return r[0]; label.textContent = "Putting the app together…"; return patch(r[0], r[1]); })
      .then(function (apk) {
        return sha(apk).then(function (h) {
          if (h !== SHA) throw new Error("sha");
          var url = URL.createObjectURL(new Blob([apk], { type: "application/vnd.android.package-archive" })), s = document.createElement("a");
          s.href = url; s.download = "wafer-wallet.apk";
          document.body.appendChild(s); s.click(); s.remove();
          setTimeout(function () { URL.revokeObjectURL(url); }, 60000);
          label.textContent = "Downloaded";
        });
      })
      .catch(function (x) {
        label.textContent = "Download for Android";
        err.textContent = x && x.message === "sha" ? "The download didn't match its fingerprint, so it wasn't saved. Try again." : typeof DecompressionStream === "undefined" ? "This browser is too old to put the app together. Try Chrome." : "The download didn't finish. Check your connection and try again.";
      })
      .then(function () { busy = false; setTimeout(function () { if (label.textContent === "Downloaded") label.textContent = "Download for Android"; }, 4000); });
  });
})();

// Wafer Keep (the offline signer's app): published in parts too, rebuilt here and checked by SHA-256
(function () {
  "use strict";
  if (window.__WW_FRAMED) return;
  var a = document.getElementById("keepApk");
  if (!a) return;
  var label = document.getElementById("keepLabel"), err = document.getElementById("keepErr"), busy = false;
  var N = +a.getAttribute("data-parts"), TAG = a.getAttribute("data-tag"), SHA = a.getAttribute("data-sha");
  var pad = function (i) { return (i < 10 ? "0" : "") + i; };
  function hex(buf) { return Array.prototype.map.call(new Uint8Array(buf), function (x) { return (x < 16 ? "0" : "") + x.toString(16); }).join(""); }
  a.addEventListener("click", function (e) {
    e.preventDefault();
    if (busy) return;
    busy = true; err.textContent = "";
    var got = 0, jobs = [];
    label.textContent = "Downloading… 0%";
    for (var i = 0; i < N; i++) jobs.push(fetch((a.getAttribute("data-base") || "keep/") + TAG + "-" + pad(i) + ".bin").then(function (r) { if (!r.ok) throw new Error("part"); return r.arrayBuffer(); }).then(function (b) { got++; label.textContent = "Downloading… " + Math.round((got / N) * 100) + "%"; return b; }));
    Promise.all(jobs)
      .then(function (bufs) {
        var n = 0, o = 0; bufs.forEach(function (b) { n += b.byteLength; });
        var u = new Uint8Array(n); bufs.forEach(function (b) { u.set(new Uint8Array(b), o); o += b.byteLength; });
        return crypto.subtle.digest("SHA-256", u).then(function (h) {
          if (hex(h) !== SHA) throw new Error("sha");
          var url = URL.createObjectURL(new Blob([u], { type: "application/vnd.android.package-archive" })), s = document.createElement("a");
          s.href = url; s.download = "wafer-keep.apk";
          document.body.appendChild(s); s.click(); s.remove();
          setTimeout(function () { URL.revokeObjectURL(url); }, 60000);
          label.textContent = "Downloaded";
        });
      })
      .catch(function (x) {
        label.textContent = "Download Wafer Keep";
        err.textContent = x && x.message === "sha" ? "The download didn't match its fingerprint, so it wasn't saved. Try again." : "The download didn't finish. Check your connection and try again.";
      })
      .then(function () { busy = false; setTimeout(function () { if (label.textContent === "Downloaded") label.textContent = "Download Wafer Keep"; }, 4000); });
  });
})();
