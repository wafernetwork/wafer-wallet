// Wafer Wallet: refuse to run inside a frame (clickjacking protection; a <meta> CSP can't set frame-ancestors).
(function () {
  "use strict";
  // "/download" and "/keep" (no trailing slash) are answered with the wallet page; send them to their pages
  if (/\/(download|keep)$/.test(location.pathname)) {
    location.replace(location.pathname + "/");
    return;
  }
  // In the Wafer Wallet app (Android, Mac, Windows) this page is the wallet. In a browser it is the site
  // about the app (the web wallet is retired); a wallet still kept in this browser can be opened
  // once more from there, for this tab only.
  var root = document.documentElement, web = false;
  try { web = sessionStorage.getItem("ww.web") === "1"; } catch (e) {}
  if (window.CircuitNative || web) root.classList.add("ww-app");
  else if (/^#bridge=/.test(location.hash)) root.classList.add("ww-bridge");
  var framed = false;
  try {
    framed = window.top !== window.self;
  } catch (e) {
    framed = true;
  }
  if (framed) {
    window.__WW_FRAMED = true;
    document.documentElement.style.display = "none";
    try {
      window.top.location = window.self.location.href;
    } catch (e) {}
  }
})();
