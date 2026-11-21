#!/usr/bin/env python3
"""Rebuild and verify Wafer Wallet / Wafer Keep APKs from the on-chain site export.

Usage:  python3 rebuild.py [source/wallet_circuit-v6.zip] [output_dir]

Mirrors what the Wafer download page does in the browser:
  * Keep   = the 13 parts joined together
  * Wallet = base version (53 parts joined) + a 3-part patch (WWBSD1 format)
Each result is checked against the SHA-256 published on the download page.
Only needs Python 3 (the optional signature check needs `pip install cryptography`).
"""
import base64, gzip, hashlib, re, struct, sys, zipfile, os

zpath = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "source", "wallet_circuit-v6.zip")
out = sys.argv[2] if len(sys.argv) > 2 else "rebuilt"
os.makedirs(out, exist_ok=True)
z = zipfile.ZipFile(zpath)
root = z.namelist()[0].split("/")[0] + "/"
rd = lambda p: z.read(root + p)
sha = lambda b: hashlib.sha256(b).hexdigest()

# 1. every file against the signed list in release.txt
rel = rd("release.txt")
bad = 0
for line in rel.decode().splitlines()[2:]:
    if "  " not in line:
        continue
    h, p = line.split("  ", 1)
    p = "well-known/assetlinks.json" if p == ".well-known/assetlinks.json" else p
    if sha(rd(p)) != h:
        bad += 1
        print("MISMATCH", p)
print("release.txt check:", "OK" if not bad else f"{bad} FILES DO NOT MATCH")

# 2. optional signature check (ECDSA P-256 / SHA-256 over release.txt)
try:
    from cryptography.hazmat.primitives.serialization import load_der_public_key
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives import hashes
    key = load_der_public_key(base64.b64decode(rel.split(b"\n")[1].split(b" ", 1)[1]))
    key.verify(base64.b64decode(rd("release.sig").strip()), rel, ec.ECDSA(hashes.SHA256()))
    print("release.sig check: VALID (compare the key in release.txt with the one on-chain)")
except ImportError:
    print("release.sig check: skipped (pip install cryptography)")
except Exception:
    print("release.sig check: INVALID"); sys.exit(1)

# 3. read expected fingerprints and part counts from the download pages
dl = rd("download/index.html").decode()
m = re.search(r'id="apk"[^>]*data-parts="(\d+)"[^>]*data-tag="(\w+)"[^>]*data-patch-parts="(\d+)"[^>]*data-patch-tag="(\w+)"[^>]*data-sha="(\w+)"', dl)
n, tag, pn, ptag, wallet_sha = int(m[1]), m[2], int(m[3]), m[4], m[5]
km = re.search(r'id="keepApk"[^>]*data-parts="(\d+)"[^>]*data-tag="(\w+)"[^>]*data-sha="(\w+)"', rd("keep/index.html").decode())
kn, ktag, keep_sha = int(km[1]), km[2], km[3]

# 4. Wafer Keep
keep = b"".join(rd(f"download/keep/{ktag}-{i:02d}.bin") for i in range(kn))
assert sha(keep) == keep_sha, "Wafer Keep fingerprint mismatch"
open(os.path.join(out, "wafer-keep.apk"), "wb").write(keep)
print("wafer-keep.apk   OK", keep_sha)

# 5. Wafer Wallet (base + patch)
base = b"".join(rd(f"download/apk/{tag}-{i:02d}.bin") for i in range(n))
patch = b"".join(rd(f"download/apk/{ptag}-p{i:02d}.bin") for i in range(pn))
assert patch[:6] == b"WWBSD1"
ol, nl, a1, b1, c1 = struct.unpack("<5I", patch[8:28])
assert len(base) == ol and hashlib.sha256(base).digest() == patch[28:60], "base mismatch"
o = 92
ctrl = gzip.decompress(patch[o:o + a1]); diff = gzip.decompress(patch[o + a1:o + a1 + b1]); extra = gzip.decompress(patch[o + a1 + b1:o + a1 + b1 + c1])
new = bytearray(nl); np_ = op = dp = ep = 0
for i in range(0, len(ctrl) - 11, 12):
    x, y, zz = struct.unpack_from("<3i", ctrl, i)
    assert x >= 0 and y >= 0 and np_ + x + y <= nl
    for k in range(x):
        q = op + k
        new[np_ + k] = (diff[dp + k] + (base[q] if 0 <= q < ol else 0)) & 255
    np_ += x; dp += x; op += x
    new[np_:np_ + y] = extra[ep:ep + y]; np_ += y; ep += y; op += zz
assert np_ == nl and sha(new) == wallet_sha, "Wafer Wallet fingerprint mismatch"
open(os.path.join(out, "wafer-wallet.apk"), "wb").write(bytes(new))
print("wafer-wallet.apk OK", wallet_sha)
print("Done. Files are in:", out)
