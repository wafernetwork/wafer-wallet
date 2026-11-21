// Backup-site helper: points the install commands at THIS site instead of wallet.wafer.page,
// and shows a notice. It changes only on-page text; it does not touch any app file.
(function () {
  "use strict";
  var me = document.currentScript;
  if (!me || !me.src) return;
  var ROOT = new URL(".", me.src).href.replace(/\/$/, "");
  var cmds = [
    [/wafer-seal\.sh/, "curl -fsSL " + ROOT + "/download/wafer-seal.sh -o wafer-seal.sh && WAFER_KEEP_URL=" + ROOT + "/download/keep bash wafer-seal.sh"],
    [/install\.sh/, "curl -fsSL " + ROOT + "/install.sh | WW_FROM=" + ROOT + " sh"],
    [/android\.sh/, "curl -fsSL " + ROOT + "/android.sh | WW_SITE=" + ROOT + " sh"],
    [/win\.txt/, "$env:WW_FROM='" + ROOT + "'; irm " + ROOT + "/win.txt | iex"]
  ];
  function fix() {
    Array.prototype.forEach.call(document.querySelectorAll(".cmd code"), function (c) {
      var t = c.textContent;
      for (var i = 0; i < cmds.length; i++) if (cmds[i][0].test(t)) { c.textContent = cmds[i][1]; break; }
    });
    var b = document.createElement("div");
    b.className = "mirror-note";
    b.setAttribute("role", "note");
    b.textContent = "Wafer Network's GitHub copy of the Wafer Wallet site (v6), for when wallet.wafer.page is unavailable. The install commands on this page use this copy. Before installing, check the SHA-256 fingerprints against the on-chain manifest and the signed release.txt.";
    document.body.insertBefore(b, document.body.firstChild);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fix); else fix();
})();
