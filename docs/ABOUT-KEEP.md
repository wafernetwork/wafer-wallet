# About Wafer Keep

Summary of [wallet.wafer.page/#keep](https://wallet.wafer.page/#keep) and [wallet.wafer.page/keep/](https://wallet.wafer.page/keep/), written from the on-chain export (v6). The official pages are the authority.

## What it is
A free Android app that turns an old phone into an offline hardware wallet. The phone never goes online and holds the keys. **Wafer Wallet** (on your everyday phone or computer) prepares each payment; **Wafer Keep** shows exactly what it does and signs it with your PIN. They talk only through **encrypted QR codes**. Keep has no internet permission at all. No device to buy.

Signs for: Ethereum-style networks (BNB Chain, Ethereum, etc., with tokens such as USDT/USDC), Bitcoin (native SegWit `bc1q…`) and Solana (SOL, USDC, USDT). dApps and swaps in Wafer Wallet are signed on Keep too, including moving funds into Wafer Shield.
It works **only** with Wafer Wallet, not with MetaMask or other wallets.

## What you need (about 10 minutes)
- An old Android phone, **Android 9 or newer, with a locked bootloader**. Everything on it is erased.
- A USB cable.
- A Mac with Terminal (for the one-command setup).
- Paper and pen for the recovery words (the only backup of the keys).

## Set up the phone
1. **Reset the phone.** Factory reset; skip everything in setup (no Wi-Fi, no Google account); remove the SIM.
2. **Turn on USB debugging.** Settings → About phone → tap Build number 7 times; Settings → Developer options → USB debugging on.
3. **Install Android's USB tool on your Mac** (once): `brew install android-platform-tools`
4. **Connect and run the setup command.** Plug in the phone, tap Allow. Run:
   `curl -fsSL https://wallet.wafer.page/download/wafer-seal.sh -o wafer-seal.sh && bash wafer-seal.sh`
   It downloads Wafer Keep, checks its fingerprint, installs it and seals the phone. Type `SEAL` when asked.
   *Without the website:* put `wafer-keep.apk` next to `wafer-seal.sh` and run `bash wafer-seal.sh` (see [INSTALL-WITHOUT-DOMAIN.md](INSTALL-WITHOUT-DOMAIN.md)).
5. **Create your keys.** Unplug the phone. In Wafer Keep tap Create new keys, write the **24 words** on paper, choose a PIN.

You don't have to seal the phone: you can install the app on any phone with airplane mode on and no SIM. Sealing adds locks and is safer for a phone kept as a wallet.

## What sealing locks
Wi-Fi, Bluetooth, mobile data and SIM, airplane mode stays on, factory reset and safe mode, USB file transfer, installing other apps and USB debugging. Still working: the screen, the camera (to read QR codes) and the power button.
To reuse the phone later: Wafer Keep → Settings → **Unseal this phone** (asks for your PIN).

## Use it with Wafer Wallet
**Connect once:**
1. In Wafer Wallet's opening screen tap **Connect Wafer Keep** (or in an existing wallet: Menu → Wafer Keep).
2. In Wafer Keep: **Pair with Wafer Wallet** and hold the camera on the wallet's code.
3. Scan Wafer Keep's code with the wallet the same way.
4. Check that both screens show the same **10 digits**.

**Sending:** send as usual in Wafer Wallet; in Wafer Keep tap **Scan to sign**, check amount and address, enter your PIN; scan Keep's answer with the wallet, which checks the signature and sends.

## Security design (per Wafer)
- **Encryption:** every code uses AES-256. Pairing uses ML-KEM-768 with P-256 (post-quantum).
- **Only Wafer Wallet:** Keep opens requests only from paired wallets; the wallet accepts signatures only from its Keep and checks each one.
- **Guarded keys:** encrypted with your PIN and sealed by the phone's secure hardware. **Ten wrong PINs in a row erase the keys**; your paper words bring them back.
- **Nothing signed ahead:** never signs account delegations (EIP-7702) or Solana transactions that never expire; remembers the last nonce per network and stops transactions signed ahead.
- **Refuses what it can't read** (contract calls of most apps, new contracts, other programs' Solana instructions) unless you allow them in settings.
- **Your own limits (optional):** trusted addresses only; a daily maximum per coin. Kept on the offline phone, changed only with your PIN.

## FAQ
- *Forgot the PIN?* After 10 wrong tries the keys are erased. Restore with your words and choose a new PIN. Funds are on the blockchain, not the phone.
- *Phone lost or broken?* Set up another phone, restore with your words, pair again. A finder still needs the PIN and gets ten tries.
- *Write your recovery words on paper. Never type them into a phone or computer that goes online.*

## Files (version 1.7, 298 KB)
| File | SHA-256 |
|---|---|
| `wafer-keep.apk` | `c9e927a2165f02b5bca38296e50ff590dbc14bdf5438fd54d243aa6687ed3c45` |
| Signing certificate | `aacda08d3434e30f529a2d54b9ab8d35b3b2b1215bbadc209f3fdefa7e3c22cd` |
| `wafer-seal.sh` | `8d6493afcfa49b120faaa8332666cc434a8258b85c37615b59a7b5e289f405bd` |
