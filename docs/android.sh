#!/bin/sh
# Wafer Wallet for Android, installed from Termux:
#
#   curl -fsSL https://wallet.wafer.page/android.sh | sh
#
# It downloads the app's parts from wallet.wafer.page (they are stored on BNB Chain), puts the APK
# together, checks it against the fingerprint below and opens Android's installer. Running it again
# updates the app. It changes nothing else, apart from installing Python in Termux the first time.
set -eu

SITE="${WW_SITE:-https://wallet.wafer.page}"
APK_VERSION="1.7"
APK_SHA="8051ca6f46e1ee8872c659d4b0b73b3488df35ca75105cd188daa7d18d9a0a33"
PKG="network.wafer.wallet"

say() { printf '%s\n' "$*"; }

case "${PREFIX:-}" in
  */com.termux/*) ;;
  *) say "Run this in Termux on your Android phone. Get Termux from F-Droid: https://f-droid.org/packages/com.termux/"; exit 1 ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  say "Installing Python in Termux (needed once to put the app together, about 30 MB)…"
  pkg install -y python >/dev/null 2>&1 || { say "Couldn't install Python. Run: pkg update && pkg install python, then this command again."; exit 1; }
fi

WORK="$HOME/.wafer-wallet-download"
OUT="$HOME/wafer-wallet-$APK_VERSION.apk"
rm -rf "$WORK"; mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

say "Downloading Wafer Wallet $APK_VERSION from $SITE…"
curl -fsSL --retry 3 "$SITE/download/index.html" -o "$WORK/page.html" || { say "Couldn't reach $SITE. Check the connection and try again."; exit 1; }

python3 -I - "$WORK" "$SITE" "$APK_SHA" "$OUT" <<'PY'
import concurrent.futures, gzip, hashlib, os, re, struct, subprocess, sys
work, site, want, out = sys.argv[1:5]
html = open(os.path.join(work, "page.html"), encoding="utf8").read()
tag = re.search(r'<a class="btn" id="apk"[^>]*>', html)
if not tag:
    sys.exit("The download page has no Android app. Try again later.")
attr = dict(re.findall(r'([\w-]+)="([^"]*)"', tag.group(0)))
if attr.get("data-sha") != want:
    sys.exit("The download page lists a different version than this installer (the site may be updating). Try again in a minute.")
n, t, pn, pt = int(attr["data-parts"]), attr["data-tag"], int(attr.get("data-patch-parts") or 0), attr.get("data-patch-tag")
names = [f"{t}-{i:02d}.bin" for i in range(n)] + ([f"{pt}-p{i:02d}.bin" for i in range(pn)] if pn else [])

def get(name):
    path = os.path.join(work, name)
    r = subprocess.run(["curl", "-fsSL", "--retry", "3", f"{site}/download/apk/{name}", "-o", path])
    if r.returncode:
        raise RuntimeError(name)
    return path

done = 0
with concurrent.futures.ThreadPoolExecutor(6) as ex:
    futs = {ex.submit(get, x): x for x in names}
    for f in concurrent.futures.as_completed(futs):
        try:
            f.result()
        except Exception:
            sys.exit(f"Couldn't download {futs[f]}. Check the connection and try again.")
        done += 1
        print(f"\r  {done}/{len(names)} parts", end="", flush=True)
print()
read = lambda xs: b"".join(open(os.path.join(work, x), "rb").read() for x in xs)
apk = base = read(names[:n])
if pn:
    p = read(names[n:])
    if p[:6] != b"WWBSD1":
        sys.exit("The update part is damaged. Try again.")
    ol, nl, a1, b1, c1 = struct.unpack_from("<5I", p, 8)
    if len(base) != ol or hashlib.sha256(base).digest() != p[28:60]:
        sys.exit("The parts don't fit together. Try again.")
    o = 92
    ctrl = gzip.decompress(p[o:o + a1]); diff = gzip.decompress(p[o + a1:o + a1 + b1]); extra = gzip.decompress(p[o + a1 + b1:o + a1 + b1 + c1])
    buf = bytearray(nl); np = op = dp = ep = 0
    for i in range(0, len(ctrl) - 11, 12):
        x, y, z = struct.unpack_from("<3i", ctrl, i)
        if x < 0 or y < 0 or np + x + y > nl:
            sys.exit("The update part is damaged. Try again.")
        seg = bytearray(diff[dp:dp + x])
        s = max(op, 0); old = base[s:max(op + x, 0)]; off = s - op  # bytes outside the base add nothing
        for k in range(len(old)):
            seg[off + k] = (seg[off + k] + old[k]) & 255
        buf[np:np + x] = seg
        np += x; dp += x; op += x
        buf[np:np + y] = extra[ep:ep + y]; np += y; ep += y; op += z
    if np != nl:
        sys.exit("The update part is damaged. Try again.")
    apk = bytes(buf)
got = hashlib.sha256(apk).hexdigest()
if got != want:
    sys.exit(f"Fingerprint check failed: got {got}, expected {want}. Nothing was installed.")
open(out, "wb").write(apk)
print(f"Checked: SHA-256 {got}")
PY

if cmd package list packages 2>/dev/null | grep -qx "package:$PKG"; then
  say ""
  say "Wafer Wallet is already on this phone. If Android says \"App not installed\", it's an older version"
  say "signed with the old key (1.5 or older): have your recovery kit at hand, uninstall it, run this again,"
  say "then restore your wallet in the new app."
fi

say ""
if command -v termux-open >/dev/null 2>&1 && termux-open "$OUT" 2>/dev/null; then
  say "Android's installer is opening. If asked, allow Termux to install apps, then tap Install."
else
  say "Saved as $OUT. Open it with a file manager to install it."
fi
say "Play Protect may say it doesn't know the app, because it isn't from the Play Store. That's expected."
