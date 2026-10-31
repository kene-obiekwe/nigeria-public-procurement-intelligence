"""
NOCOPO — Link Preview Image
===========================
Phase 14: Landing Page and Link Previews
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Draw web/og-image.png, the 1200 x 630 image that LinkedIn and other sites show
for a link to the web dashboard (og:image), from python/web/og_card.html with
a headless Microsoft Edge or Google Chrome. The figures on the card are
verified by python/web/check_web_data.py (section 6); run it after any change
to the card.

Usage
-----
    python python/web/make_og_image.py
    python python/web/make_og_image.py --browser "C:/Program Files/Google/Chrome/Application/chrome.exe"

Exit code 1 if the image is not 1200 x 630 or is 300 KB or larger.
"""

import argparse
import os
import pathlib
import shutil
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CARD = os.path.join(ROOT, "python", "web", "og_card.html")
OUTPUT = os.path.join(ROOT, "web", "og-image.png")
WIDTH, HEIGHT, MAX_BYTES = 1200, 630, 300 * 1024
BROWSERS = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "microsoft-edge", "google-chrome", "chromium",
]


def find_browser():
    for b in BROWSERS:
        if os.path.exists(b) or shutil.which(b):
            return b
    sys.exit("No Edge or Chrome found; pass --browser")


def png_size(path):
    with open(path, "rb") as fh:
        head = fh.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    return struct.unpack(">II", head[16:24])


def main():
    parser = argparse.ArgumentParser(description="Draw web/og-image.png from python/web/og_card.html.")
    parser.add_argument("--browser", help="path to msedge or chrome (default: the first one found)")
    args = parser.parse_args()
    browser = args.browser or find_browser()

    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as profile:
        subprocess.run([browser, "--headless", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
                        "--force-device-scale-factor=1", f"--user-data-dir={profile}",
                        f"--window-size={WIDTH},{HEIGHT}", f"--screenshot={OUTPUT}", pathlib.Path(CARD).as_uri()],
                       check=True, capture_output=True, timeout=120)

    w, h = png_size(OUTPUT)
    size = os.path.getsize(OUTPUT)
    print(f"{os.path.relpath(OUTPUT, ROOT)}: {w} x {h}, {size / 1024:.1f} KB")
    if (w, h) != (WIDTH, HEIGHT) or size >= MAX_BYTES:
        sys.exit(f"FAIL: expected {WIDTH} x {HEIGHT} and under {MAX_BYTES // 1024} KB")


if __name__ == "__main__":
    main()
