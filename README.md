# Wafer Wallet & Wafer Keep: unofficial backup mirror (v6)

**This is an unofficial personal backup, not the official source.** The official app is published on BNB Chain by the Wafer team (name `wallet.circuit`).
Do **not** trust this repo on its own. Always check the fingerprints below against the on-chain manifest and the signed `release/release.txt`.

## Why this exists
Wafer Wallet's downloads were served from `wallet.wafer.page`. If that domain stops working, this repo keeps a copy of the files and a way to rebuild and check them without it.

## What's here
| Path | What it is |
|---|---|
| `source/wallet_circuit-v6.zip` | Full export of the on-chain site: all parts, install scripts, Mac/Windows `desktop-app.tgz`, Keep sealing script |
| `apk/wafer-wallet.apk` | Android Wafer Wallet, rebuilt from the on-chain parts |
| `apk/wafer-keep.apk` | Android Wafer Keep (offline signer), rebuilt from the on-chain parts |
| `release/release.txt`, `release.sig` | The release's SHA-256 list and its signature (ECDSA P-256) |
| `release/wafer-manifest.json` | The on-chain file manifest |
| `docs/` | Wallet and Keep details, and install steps without the website |
| `rebuild.py` | Rebuilds and verifies both APKs from the zip |
| `SHA256SUMS` | Fingerprints of the files in this repo |

## About the apps
- **Wafer Wallet:** free self-custody wallet for Android, Windows and Mac (Bitcoin, Ethereum, BNB Chain, Solana, Base, 25+ more networks, private payments with Wafer Shield, swaps and dApps). Its code is stored on BNB Chain as `wallet.circuit` and checked before every run. Details: [docs/ABOUT-WALLET.md](docs/ABOUT-WALLET.md). Official site: https://wallet.wafer.page/
- **Wafer Keep:** turns an old Android phone into an offline hardware wallet that signs through encrypted QR codes. Details and setup: [docs/ABOUT-KEEP.md](docs/ABOUT-KEEP.md). Official page: https://wallet.wafer.page/#keep
- **Domain gone?** Follow [docs/INSTALL-WITHOUT-DOMAIN.md](docs/INSTALL-WITHOUT-DOMAIN.md).

## Fingerprints (SHA-256), version 1.7
```
wafer-wallet.apk   8051ca6f46e1ee8872c659d4b0b73b3488df35ca75105cd188daa7d18d9a0a33
wafer-keep.apk     c9e927a2165f02b5bca38296e50ff590dbc14bdf5438fd54d243aa6687ed3c45
install.sh (Mac)   4b2df95b466117a1a194fb702ff287e20bb4f5609d920e8a503bc7dcfd753070
win.txt (Windows)  3cd12b03b178d2603f2b223de3d2f847eaa2f449bce48305fa41f97b399f93d3
android.sh         aec605910775d94f2e2a58ac24d67e5422c081b59c4a056bd917bbc35ef15635
desktop-app.tgz    96417808833bdab8e4e836a63df01efc517c95733811f12fd21cfea91876d72d
wafer-seal.sh      8d6493afcfa49b120faaa8332666cc434a8258b85c37615b59a7b5e289f405bd
```
APK signing certificates (SHA-256), which I checked against both APKs:
```
wafer-wallet.apk   eaeaeeb407914a670f203ebbc44a9363594006270879ea2ca29cceed1c5dc985
wafer-keep.apk     aacda08d3434e30f529a2d54b9ab8d35b3b2b1215bbadc209f3fdefa7e3c22cd
```

## On-chain references
- Network: BNB Smart Chain
- Site manifest ID: `0xee6d50e52020adfc9f2a307f042e5253eb19aa0e29c0be2a6441203fcb4e82f4`
- Storage contract: `0x946f41c84661C066d22F9d106C1a6CCF050FBc2b` ([BscScan](https://bscscan.com/address/0x946f41c84661C066d22F9d106C1a6CCF050FBc2b))
- Version: v6 (exported 2026-11-21)

## Verify
```bash
sha256sum -c SHA256SUMS              # Linux  (macOS: shasum -a 256 -c SHA256SUMS)
python3 rebuild.py                   # rebuilds both APKs from the zip into ./rebuilt and checks them
```
The rebuilt APKs must be byte-identical to the ones in `apk/`.
For a stronger check, compare the manifest ID and file hashes in `release/wafer-manifest.json` with what the BNB Chain contract returns.

## Safety
- Install only an APK whose SHA-256 matches the values above **and** the on-chain data.
- Never enter your recovery words in anything you have not verified.
- Your 12/24 recovery words are your real backup. Keep them on paper, offline.
- Android needs "install unknown apps" enabled for the installer you use.

## Licence / ownership
I do not own Wafer Wallet or Wafer Keep. Wafer describes the project as open source. The files I checked say the desktop app is **MIT**, the bundled QR library is **Apache-2.0** and the fonts are **SIL OFL**. See [`NOTICE.md`](NOTICE.md). The Android APKs do not state a licence, so confirm the exact terms with Wafer and add their official `LICENSE` file if they give you one.
