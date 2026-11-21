# Host the site on GitHub Pages

The folder `docs/` is a ready-to-publish copy of the on-chain Wafer Wallet site (v6): the landing page, download page, Keep page, the app parts and the install scripts. Once published, the install commands work from your own address instead of `wallet.wafer.page`.

## Publish it
1. Upload this whole repo to GitHub (see the README).
2. Repo **Settings → Pages**.
3. Under **Build and deployment**: Source = **Deploy from a branch**, Branch = **main**, Folder = **/docs**. Click **Save**.
4. Wait 1-2 minutes. Your site is at `https://YOUR-USERNAME.github.io/REPO-NAME/`.

**Free accounts need a public repo for Pages.** Private-repo Pages needs a paid GitHub plan. The repo is MIT-licensed (see `LICENSE`), so a public repo is fine.

## What works
The pages rewrite their own install commands to your address. Open `https://YOUR-USERNAME.github.io/REPO-NAME/download/` and copy the commands from there. They look like this (replace `ROOT` with your site address, no trailing slash):

| Task | Command |
|---|---|
| Android in Termux | `curl -fsSL ROOT/android.sh \| WW_SITE=ROOT sh` |
| Mac | `curl -fsSL ROOT/install.sh \| WW_FROM=ROOT sh` |
| Windows (PowerShell) | `$env:WW_FROM='ROOT'; irm ROOT/win.txt \| iex` |
| Wafer Keep (Mac + phone on USB) | `curl -fsSL ROOT/download/wafer-seal.sh -o wafer-seal.sh && WAFER_KEEP_URL=ROOT/download/keep bash wafer-seal.sh` |

The "Download for Android" and "Download Wafer Keep" buttons also work: they rebuild the APK in the browser from the parts and check the SHA-256 before saving.

## What I changed in the site copy
Only these, so the rest is byte-identical to the export:
- `index.html`, `download/index.html`, `keep/index.html`: one line added to load `mirror.css` and `mirror.js`.
- Added `mirror.js` (rewrites the command text), `mirror.css` (unused now, harmless), and `.nojekyll` (so GitHub serves every file as-is).
- Left out `_headers` (server rules for Wafer's gateway; GitHub Pages ignores them), `well-known/assetlinks.json` (for the original domain only) and the manifest copy (it is in `release/`).
The original, untouched export is in `source/wallet_circuit-v6.zip`.
`SITE-SHA256SUMS` lists the fingerprint of every file in `docs/`.

## What I tested
Served `docs/` under a sub-path like GitHub Pages does, then:
- the Termux install script's own download-and-rebuild code produced the exact wallet APK (SHA-256 `8051ca6f…9a0a33`);
- the Keep download loop produced the exact Keep APK (`c9e927a2…ed3c45`);
- the Mac installer script and the desktop app archive were served with the expected fingerprints;
- the command rewriting produced the four commands above.

**Not tested:** the real GitHub Pages deployment, actually running the Mac/Windows installers, `wafer-seal.sh` against a phone, or installing on a device. Do a dry run on a spare device first.

## Limits and safety
- GitHub Pages is another single host. Keep the offline copies and the verification steps from the README.
- People who run `curl … | sh` from this site are trusting this site. Never edit the scripts or APK parts, and point people to the fingerprints and the on-chain manifest.
- Don't let git change line endings: `.gitattributes` turns conversion off. If you upload with the GitHub website you're fine.
- GitHub Pages has size and bandwidth limits (about 1 GB site size, 100 GB/month). This site is a few MB.
