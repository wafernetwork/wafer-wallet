#!/bin/sh
# Wafer Wallet for Mac: installer.
#   Install or update:  curl -fsSL https://wallet.wafer.page/install.sh | sh
#   Or, with the file:  sh install.sh
#   Uninstall:          sh install.sh --uninstall   (your wallet data stays; see the end of this note)
#
# Builds the Wafer Wallet app on your own Mac and puts it in your Applications folder.
#  - The app window is Electron 44.7.0 (the open-source engine many desktop apps use), downloaded
#    from Electron's official GitHub releases and checked against its published SHA-256.
#  - Inside it go Wafer Wallet's own app files (desktop-app.tgz, 25276 bytes, the same for Mac
#    and Windows): a loader that reads the wallet from BNB Chain ("wallet.circuit") and checks every
#    byte against its on-chain fingerprint, and a small bridge for Touch ID, saving files, printing
#    and your own nodes. They are fetched from wallet.wafer.page or, if that can't be reached,
#    straight from BNB Chain, and checked against the SHA-256 below either way. So this installer
#    works even if the website is down, and the app then starts offline from the copy it keeps.
#  - It is signed on this Mac (an "ad-hoc" signature), so macOS opens it without a warning.
# No sudo, no background service, nothing added to your shell.
# The wallet's data is kept in ~/Library/Application Support/Wafer Wallet (delete that folder to
# remove it too; first make sure you have your recovery kit and password, or your 12 words).
set -eu

VERSION=1.7.0
# the app's own files: their SHA-256, and where they are on BNB Chain (CircuitStore, blob hash)
APP_SHA=96417808833bdab8e4e836a63df01efc517c95733811f12fd21cfea91876d72d
APP_BLOB=0x73e541dc73010d6024afbbe44d7b1cd9e8df58291dc526c303f712440979267a
STORE=0x946f41c84661C066d22F9d106C1a6CCF050FBc2b
FROM="${WW_FROM:-https://wallet.wafer.page}"

if [ "$(uname -s)" != "Darwin" ]; then echo "This installer is for macOS. On Windows, see https://wallet.wafer.page/download/" >&2; exit 1; fi
EV=44.7.0
case "$(uname -m)" in
  arm64) ARCH=arm64; SUM=e04e411b58a0a14375dd21b0ab4a378fd38930a702e4e20e322fee4849404c0b ;;
  x86_64) ARCH=x64; SUM=4fe494a7159b10a81e2098dab388719582065e99e604c4510bb117e282213566 ;;
  *) echo "This Mac's processor ($(uname -m)) isn't supported." >&2; exit 1 ;;
esac
DEST="${WW_DEST:-/Applications}"
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"
APP="$DEST/Wafer Wallet.app"
quit_app() { osascript -e 'tell application id "network.wafer.wallet" to quit' >/dev/null 2>&1 || true; }
# the earlier Wafer Wallet launcher (it only opened the website) had the same name: replace it
OLD="$HOME/Applications/Wafer Wallet.app"
is_launcher() { [ -f "$1/Contents/Info.plist" ] && /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Contents/Info.plist" 2>/dev/null | grep -q '^page\.wafer\.wallet\.launcher$'; }

if [ "${1:-}" = "--uninstall" ]; then
  quit_app
  for a in "/Applications/Wafer Wallet.app" "$HOME/Applications/Wafer Wallet.app"; do [ -d "$a" ] && rm -rf "$a" && echo "Removed $a"; done
  echo "Your wallet's data is still in ~/Library/Application Support/Wafer Wallet."
  exit 0
fi

W=$(mktemp -d "${TMPDIR:-/tmp}/wafer-wallet.XXXXXX")
trap 'rm -rf "$W"' EXIT
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
# the app's files: from the website, else from BNB Chain (CircuitStore.read), checked either way
get_app() {
  if curl -fsSL -o "$W/app.tgz" "$FROM/download/desktop-app.tgz" </dev/null 2>/dev/null && [ "$(sha "$W/app.tgz")" = "$APP_SHA" ]; then return 0; fi
  for RPC in https://bsc-dataseed.bnbchain.org https://bsc-rpc.publicnode.com https://1rpc.io/bnb; do
    curl -fsS -m 60 -X POST -H 'content-type: application/json' \
      --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_call\",\"params\":[{\"to\":\"$STORE\",\"data\":\"0x61da1439${APP_BLOB#0x}\"},\"latest\"]}" \
      -o "$W/r.json" "$RPC" </dev/null 2>/dev/null || continue
    HEX=$(sed -n 's/.*"result" *: *"0x\([0-9a-fA-F]*\)".*/\1/p' "$W/r.json")
    [ "${#HEX}" -gt 128 ] || continue
    LEN=$(printf '%d' "0x$(printf %s "$HEX" | cut -c65-128)")
    printf %s "$HEX" | cut -c129-$((128 + LEN * 2)) | xxd -r -p > "$W/app.tgz"
    [ "$(sha "$W/app.tgz")" = "$APP_SHA" ] && return 0
  done
  return 1
}
echo "1/4  Downloading the app window (Electron $EV for $ARCH, about 110 MB)..."
curl -fL --progress-bar -o "$W/e.zip" "https://github.com/electron/electron/releases/download/v$EV/electron-v$EV-darwin-$ARCH.zip" </dev/null
echo "2/4  Checking the download, and getting Wafer Wallet's own files..."
if [ "$(sha "$W/e.zip")" != "$SUM" ]; then echo "The download doesn't match Electron's published fingerprint, so nothing was installed." >&2; exit 1; fi
if ! get_app; then echo "Wafer Wallet's files couldn't be fetched (or didn't match their fingerprint), so nothing was installed. Check your connection and try again." >&2; exit 1; fi
echo "3/4  Building Wafer Wallet..."
mkdir "$W/x"; ditto -x -k "$W/e.zip" "$W/x" </dev/null
A="$W/x/Electron.app"; R="$A/Contents/Resources"
rm -f "$R/default_app.asar"
mkdir -p "$R/app"
tar -xzf "$W/app.tgz" -C "$R/app"
mv "$R/app/AppIcon.icns" "$R/electron.icns"
P=/usr/libexec/PlistBuddy; PL="$A/Contents/Info.plist"
$P -c "Set :CFBundleName Wafer Wallet" -c "Set :CFBundleDisplayName Wafer Wallet" -c "Set :CFBundleIdentifier network.wafer.wallet" \
   -c "Set :CFBundleShortVersionString $VERSION" -c "Set :CFBundleVersion 8" "$PL" </dev/null
$P -c "Set :NSCameraUsageDescription Wafer Wallet uses the camera only to scan the QR code of your recovery kit." "$PL" </dev/null >/dev/null 2>&1 || true
$P -c "Add :LSApplicationCategoryType string public.app-category.finance" "$PL" </dev/null >/dev/null 2>&1 || true
$P -c "Add :NSHumanReadableCopyright string Wafer Network" "$PL" </dev/null >/dev/null 2>&1 || true
xattr -cr "$A" </dev/null 2>/dev/null || true
codesign --force --deep --sign - "$A" </dev/null >/dev/null 2>&1
echo "4/4  Putting it in ${DEST}..."
quit_app
if is_launcher "$OLD"; then rm -rf "$OLD"; fi
# wait (up to 15 s) until the running app has really quit before its files are replaced
i=0; while pgrep -f "$APP/Contents/MacOS/" >/dev/null 2>&1 && [ $i -lt 30 ]; do sleep 0.5; i=$((i + 1)); done
if [ -d "$APP" ]; then rm -rf "$APP"; fi
ditto "$A" "$APP" </dev/null
echo "Done. Wafer Wallet $VERSION is in ${DEST}. Opening it..."
open "$APP" </dev/null
exit 0
