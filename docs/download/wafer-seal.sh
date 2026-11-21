#!/usr/bin/env bash
# Wafer Seal: turns an old Android phone into a Wafer Keep signer that can't go online again.
#
# Run it once, from a Mac, with the phone on USB:
#   curl -fsSL https://wallet.wafer.page/download/wafer-seal.sh -o wafer-seal.sh && bash wafer-seal.sh
# It downloads Wafer Keep 1.7 from wallet.wafer.page (published on BNB Chain in parts) and checks
# it against the fingerprint below. Or put wafer-keep.apk next to this script, or pass its path.
#
# Before you start, on the phone:
#   1. Factory reset it. During setup, skip everything: no Wi-Fi, no Google account, no SIM card.
#   2. Take out the SIM card.
#   3. Settings > About phone > tap "Build number" 7 times; then Developer options > USB debugging on.
#   4. Connect the USB cable and tap "Allow" on the phone.
# Mac: install adb first with   brew install android-platform-tools
#
# What it does: turns Wi-Fi and Bluetooth off, airplane mode on, installs Wafer Keep, and makes it
# the phone's owner. Wafer Keep then locks Wi-Fi, Bluetooth, mobile networks, factory reset,
# USB file transfer, app installs and USB debugging, and runs as the only app on the phone.
# To undo it: Wafer Keep > Settings > Unseal this phone (needs your PIN).
set -euo pipefail

PKG=network.wafer.keep
ADMIN=$PKG/.SealAdmin
# the Wafer Keep signing certificate (SHA-256): the installed app must carry exactly this
CERT=aacda08d3434e30f529a2d54b9ab8d35b3b2b1215bbadc209f3fdefa7e3c22cd
HERE="$(cd "$(dirname "$0")" && pwd)"
APK="${1:-$HERE/wafer-keep.apk}"
[ -z "${1:-}" ] || [ -f "$1" ] || { printf '\nSTOPPED: %s\n' "There's no file at $1." >&2; exit 1; }
# the Wafer Keep app on wallet.wafer.page: its parts, and the SHA-256 of the whole file
KEEP_TAG=c9e927a2165f
KEEP_PARTS=13
KEEP_SHA=c9e927a2165f02b5bca38296e50ff590dbc14bdf5438fd54d243aa6687ed3c45
KEEP_URL=${WAFER_KEEP_URL:-https://wallet.wafer.page/download/keep}

say() { printf '\n== %s\n' "$*"; }
die() { printf '\nSTOPPED: %s\n' "$*" >&2; exit 1; }
sh_() { adb shell "$@" 2>/dev/null | tr -d '\r'; }

command -v adb >/dev/null || die "adb isn't installed. On a Mac: brew install android-platform-tools"
sha256() { if command -v shasum >/dev/null; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }
LOCAL=1
if [ ! -f "$APK" ]; then
  LOCAL=0
  say "Downloading Wafer Keep"
  APK="$(mktemp -d)/wafer-keep.apk"
  for i in $(seq 0 $((KEEP_PARTS - 1))); do
    part=$(printf '%s/%s-%02d.bin' "$KEEP_URL" "$KEEP_TAG" "$i")
    curl -fsSL "$part" >> "$APK" || die "Couldn't download Wafer Keep. Check your internet connection and try again."
  done
fi
# The app is checked BEFORE anything is installed: either it is exactly the published file
# (SHA-256), or it is a local file signed with the Wafer Keep certificate (needs apksigner).
got=$(sha256 "$APK")
if [ "$got" = "$KEEP_SHA" ]; then echo "Wafer Keep checked: SHA-256 $got"
elif [ "$LOCAL" = "0" ]; then die "The download didn't match its fingerprint, so it wasn't installed. Try again."
elif command -v apksigner >/dev/null 2>&1; then
  sig=$(apksigner verify --print-certs "$APK" 2>/dev/null | sed -n 's/.*SHA-256 digest: //p' | head -1 || true)
  [ "$sig" = "$CERT" ] || die "This wafer-keep.apk isn't signed by Wafer, so it wasn't installed. Download it from wallet.wafer.page."
  echo "Signature checked: $CERT"
else die "This wafer-keep.apk isn't the published version and apksigner isn't installed to check its signature. Move it away and run this script again: it downloads and checks the published app."; fi

say "Looking for the phone"
adb start-server >/dev/null 2>&1 || true
n=$(adb devices | awk 'NR>1 && $2=="device"' | wc -l | tr -d ' ')
if [ "$n" = "0" ]; then
  adb devices | grep -q unauthorized && die "Tap \"Allow\" on the phone's USB debugging prompt, then run this again."
  die "No phone found. Check the cable and that USB debugging is on."
fi
[ "$n" = "1" ] || die "More than one phone is connected. Connect only the one to seal."
MODEL="$(sh_ getprop ro.product.manufacturer) $(sh_ getprop ro.product.model)"
SDK=$(sh_ getprop ro.build.version.sdk)
echo "Phone: $MODEL (Android API $SDK)"
[ "${SDK:-0}" -ge 28 ] || die "Wafer Keep needs Android 9 or newer."

say "Checking the phone is ready"
sh_ dumpsys device_policy | grep -q "$PKG" && die "This phone is already sealed by Wafer Keep."
accts=$(sh_ dumpsys account | grep -c "Account {" || true)
[ "${accts:-0}" = "0" ] || die "The phone has $accts account(s) on it (Google, Samsung...). Factory reset it and skip signing in during setup."
users=$(sh_ pm list users | grep -c "UserInfo{" || true)
[ "${users:-1}" -le 1 ] || die "The phone has more than one user. Factory reset it first."
sim=$(sh_ getprop gsm.sim.state)
case "$sim" in
  ""|ABSENT|"ABSENT,ABSENT"|NOT_READY|"NOT_READY,NOT_READY"|"ABSENT,NOT_READY"|"NOT_READY,ABSENT") ;;
  *) die "A SIM card seems to be inserted ($sim). Take it out first." ;;
esac
echo "No accounts, no SIM card, not managed by anyone: good."

say "Checking the phone's software can be trusted"
# A phone whose bootloader is unlocked, or that runs a debug build or root, can be made to read
# anything: it can't be a signer. Verified Boot: green = the maker's software, yellow = a locked
# phone running a system with its own key (GrapheneOS, CalyxOS), orange = unlocked.
vb=$(sh_ getprop ro.boot.verifiedbootstate); fl=$(sh_ getprop ro.boot.flash.locked); ds=$(sh_ getprop ro.boot.vbmeta.device_state)
[ "$vb" = "orange" ] || [ "$fl" = "0" ] || [ "$ds" = "unlocked" ] && die "This phone's bootloader is unlocked, so its software can't be trusted to keep keys. Lock the bootloader (this erases the phone), then run this again."
case "$vb" in
  green) echo "Verified Boot: green (the maker's own software, bootloader locked)." ;;
  yellow) echo "Verified Boot: yellow (bootloader locked, running a system with its own signing key)." ;;
  *) echo "This phone doesn't report its Verified Boot state, so the script can't check that its bootloader is locked."
     read -r -p "Continue only if you know it is locked. Type LOCKED to continue: " vbok </dev/tty
     [ "$vbok" = "LOCKED" ] || die "Cancelled. Nothing was changed." ;;
esac
[ "$(sh_ getprop ro.debuggable)" = "1" ] && die "This phone runs a debug build of Android (ro.debuggable=1). Use a phone with its normal software."
sh_ getprop ro.build.tags | grep -q test-keys && die "This phone's system is signed with test keys. Use a phone with its maker's software."
[ -n "$(sh_ 'command -v su || ls /system/xbin/su /system/bin/su /sbin/su 2>/dev/null')" ] && die "This phone is rooted (su was found). Use a phone that isn't rooted."
[ "$(sh_ getprop ro.boot.veritymode)" = "disabled" ] && die "dm-verity is switched off on this phone. Use a phone with its normal software."
echo "Bootloader locked, normal build, not rooted: good."

echo
echo "This will seal the phone: it becomes a Wafer Keep signer and nothing else."
echo "Wi-Fi, Bluetooth, mobile data, factory reset and USB debugging get locked until you unseal it in Wafer Keep."
read -r -p "Type SEAL to continue: " ans </dev/tty
[ "$ans" = "SEAL" ] || die "Cancelled. Nothing was changed."

say "Turning the radios off"
sh_ svc wifi disable >/dev/null || true
sh_ svc bluetooth disable >/dev/null || sh_ cmd bluetooth_manager disable >/dev/null || true
if [ "$SDK" -ge 30 ]; then sh_ cmd connectivity airplane-mode enable >/dev/null || true
else sh_ settings put global airplane_mode_on 1 >/dev/null || true; sh_ am broadcast -a android.intent.action.AIRPLANE_MODE >/dev/null || true; fi
sleep 2
air=$(sh_ settings get global airplane_mode_on)
[ "$air" = "1" ] && echo "Airplane mode: on" || echo "Note: couldn't switch airplane mode on from here. Turn it on by hand on the phone (it gets locked in the state it's in)."

say "Installing Wafer Keep"
adb install -r "$APK" >/dev/null || die "Install failed."
path=$(sh_ pm path $PKG | sed -n 's/^package://p' | head -1)
[ -n "$path" ] || die "Wafer Keep didn't install."
sh_ pm grant $PKG android.permission.CAMERA >/dev/null || true

say "Sealing"
out=$(adb shell dpm set-device-owner "$ADMIN" 2>&1 | tr -d '\r')
echo "$out"
echo "$out" | grep -qi "success" || die "Android refused to seal the phone. Most often: an account is still on it, or it wasn't factory reset. Reset it, skip all sign-ins, and try again."

say "Starting Wafer Keep"
sh_ am start -n $PKG/.MainActivity >/dev/null || true
sleep 3
echo
echo "Done: the phone is sealed. Wafer Keep is now its only app, and USB debugging switches itself off."
echo "Unplug the phone, and set up your keys in Wafer Keep: Create new keys, write the words on paper."
echo "To use the phone for anything else later: Wafer Keep > Settings > Unseal this phone."
