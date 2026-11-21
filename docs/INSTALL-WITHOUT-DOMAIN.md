# Installing if wallet.wafer.page no longer works

The official one-line commands point at `wallet.wafer.page`. If it is gone, use the local copies in this repo instead. Always check fingerprints first (`sha256sum -c SHA256SUMS` from the repo root; `shasum -a 256 -c SHA256SUMS` on macOS).

First unpack the export once:
```bash
unzip source/wallet_circuit-v6.zip      # creates wallet.circuit-v6/
```

## Android wallet
Copy `apk/wafer-wallet.apk` to the phone, allow your file manager/browser to install apps, open it, tap Install.
Check: SHA-256 `8051ca6f46e1ee8872c659d4b0b73b3488df35ca75105cd188daa7d18d9a0a33`.
Signing certificate (SHA-256): `eaeaeeb407914a670f203ebbc44a9363594006270879ea2ca29cceed1c5dc985`.
(The `android.sh` Termux script downloads from the website, so it won't work without it. Use the APK directly.)

## Wafer Keep
Copy `apk/wafer-keep.apk` next to `wallet.circuit-v6/download/wafer-seal.sh`, then:
```bash
bash wafer-seal.sh                    # uses the local wafer-keep.apk, checks its SHA-256, then seals the phone
```
Check: SHA-256 `c9e927a2165f…ed3c45`, signing certificate `aacda08d3434e30f529a2d54b9ab8d35b3b2b1215bbadc209f3fdefa7e3c22cd`.
The script can also check a local APK's signing certificate if `apksigner` is installed. Follow [ABOUT-KEEP.md](ABOUT-KEEP.md) for the phone preparation steps.

## Mac
```bash
sh wallet.circuit-v6/install.sh        # run from a local copy, not curl
```
The script falls back to reading the app files from BNB Chain through public nodes (bsc-dataseed.bnbchain.org, bsc-rpc.publicnode.com, 1rpc.io/bnb) when the website is unreachable, and checks the same fingerprint. It downloads the Electron engine (about 110 MB) from GitHub, so it needs GitHub and an RPC to be reachable. Both installers read the environment variable `WW_FROM` (default `https://wallet.wafer.page`), so you can point them at your own host for the files, e.g. `WW_FROM=https://your-host sh install.sh`. If that host is unreachable they use BNB Chain.
Script fingerprint: `install.sh` `4b2df95b466117a1a194fb702ff287e20bb4f5609d920e8a503bc7dcfd753070`.

## Windows
Run `wallet.circuit-v6/win.txt` in PowerShell as a local file (rename to `win.ps1` and run it), after reading it. It also honours `$env:WW_FROM` and has the same chain fallback and downloads Electron from GitHub (about 120 MB).
Script fingerprint: `win.txt` `3cd12b03b178d2603f2b223de3d2f847eaa2f449bce48305fa41f97b399f93d3`.

## Checking against the chain
The wallet itself loads from BNB Chain contract `0x946f41c84661C066d22F9d106C1a6CCF050FBc2b` (name `wallet.circuit`) and verifies each file. For manual comparison, `release/wafer-manifest.json` lists every file's on-chain hash. Treat these local copies as a backup, and verify against the chain whenever you can.

## Not tested
I rebuilt and fingerprint-checked both APKs, and verified that both APK signing certificates match the ones published on the Wafer pages. I did **not** run the installers or install the APKs on a device. Test on a spare device before relying on this for real funds.
