// Points the install commands on these pages at THIS site instead of wallet.wafer.page.
// It changes only on-page text; it does not touch any app file.
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
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fix); else fix();
})();
