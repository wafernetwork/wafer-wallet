# About Wafer Wallet

Summary of the official pages [wallet.wafer.page](https://wallet.wafer.page/) and [wallet.wafer.page/download](https://wallet.wafer.page/download/), written from the on-chain export (v6). The official pages are the authority; this is a backup of the key facts.

**Tagline:** "The wallet nobody can switch off." Described as the first wallet hosted on BNB Chain.

## What it is
A free, self-custody wallet for **Android, Windows and Mac**. No account, no email. An iPhone app is not available yet. The wallet runs only as an app, not as a web wallet: an app can check its code against BNB Chain, keep secrets in the device's secure hardware and work without any website.

## Networks and assets
- Ethereum, BNB Chain, Base, Arbitrum, Polygon, OP Mainnet, Avalanche and 20+ more Ethereum-style networks, plus any network you add.
- Bitcoin (a Bitcoin address; change goes to a new wallet address, never back to one whose public key a spend has exposed).
- Solana, with SOL, USDC and USDT.
- One set of recovery words covers all of them.

## Features
- **Self-custody:** only you hold the keys; Wafer has no server that sees keys, balances or history.
- **Recovery:** your 12 words (or 24) are the only backup. Install the app anywhere, choose Restore, type the words, choose a PIN.
- **Unlock:** 6-digit PIN or fingerprint (Touch ID on Mac), also required for every send. Three wrong PINs trigger increasing waits. The PIN is tied to the device's secure hardware (phone security chip, Mac Keychain, Windows protected storage). A forgotten PIN can't be reset; remove the wallet and restore from the words.
- **Swap and bridge:** through LI.FI inside Discover; every transaction returns to the wallet's own review screen before signing. Wafer adds no fee.
- **dApp browser (Discover):** PancakeSwap, Uniswap, 1inch, THENA, Aave, Venus, Compound, Lido, Lista DAO, Rocket Pool, Stargate, Across, LI.FI, OpenSea, Revoke.cash, DeBank, DEX Screener, and on Solana Jupiter, Raydium, Orca, Kamino, Marinade, Jito, Magic Eden, Tensor, or any site you type in.
- **Own node:** add your own node address for any network if public nodes don't answer.
- **Wafer Shield (private payments):** a private balance next to the public one, on BNB Chain and Ethereum, for BNB, ETH, USDT and USDC. Shield, send privately, unshield. Zero-knowledge proofs are made on your device. Moving funds in costs 0.5%. The contracts are described as unpauseable and unchangeable. Check that private payments are allowed where you live. Also available on the web at https://shield.wafer.page/.
- **Wafer Keep support:** pair with an offline phone to sign everything. See [ABOUT-KEEP.md](ABOUT-KEEP.md).

## Security design (per Wafer)
- Plain, decoded review screens for transfers, approvals and signatures.
- Each transaction is simulated on several independent nodes before approval.
- Tapjacking protection: send/approve buttons wait a moment each time they appear.
- Refuses to run inside another page (clickjacking); screenshots and screen recordings blocked on Android; recovery words shown only in parts.
- Warnings for unlimited token approvals, "approve all" NFT access and look-alike site names.
- Local data sealed with AES-256 and SHA-256; Keep link uses ML-KEM-768 with P-256. Network signatures themselves are up to each network.

## Hosted on BNB Chain
- Every file of the wallet is stored in a BNB Chain contract under the name `wallet.circuit`.
- Storage contract: `0x946f41c84661C066d22F9d106C1a6CCF050FBc2b` ([BscScan](https://bscscan.com/address/0x946f41c84661C066d22F9d106C1a6CCF050FBc2b)).
- Site manifest ID: `0xee6d50e52020adfc9f2a307f042e5253eb19aa0e29c0be2a6441203fcb4e82f4` (store page `wafer.network/store/<id>`, stored by `jian4944.circuit`).
- At each start the app reads the wallet from several independent nodes and checks every file against its on-chain fingerprint. Any mismatch means nothing runs. A newly published version is used only after you agree.
- The app keeps a checked copy, so it starts offline and works if the website is down.

## Downloads (version 1.7 of the Android app)
| Platform | Details |
|---|---|
| Android | Android 9+. APK is stored in parts on chain; the page rebuilds it from a base version plus a patch and checks SHA-256 before saving. If you have version 1.5 or older, write down your words, uninstall, install 1.7 and restore (1.7 is signed with a new key and can't install over it). Play Protect may warn because it isn't from the Play Store. |
| Android (Termux) | `curl -fsSL https://wallet.wafer.page/android.sh \| sh` rebuilds and verifies the APK. |
| Mac | macOS 12+, Apple silicon or Intel, Touch ID. `curl -fsSL https://wallet.wafer.page/install.sh \| sh` builds and installs "Wafer Wallet" into Applications (about 110 MB: Electron from its official GitHub releases, checked by fingerprint). |
| Windows | Windows 10/11 64-bit, Intel/AMD/Arm. `irm https://wallet.wafer.page/win.txt \| iex` installs for your account only, without administrator rights (about 120 MB). |

The desktop installers take the app files from the website or, if it can't be reached, straight from BNB Chain, and check the same fingerprint either way. **If the website is gone, see [INSTALL-WITHOUT-DOMAIN.md](INSTALL-WITHOUT-DOMAIN.md).**

## Fees
The app is free. You pay network fees when you send. Swaps/bridges are charged by the dApp you use. Wafer Shield takes 0.5% when you move funds in.

## Safety
Never share your recovery phrase. Wafer says it will never ask for it.
