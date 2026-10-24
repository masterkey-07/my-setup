# ClamAV with its default signatures only: its PUA heuristics flag ordinary
# PDFs, and it misses a lot of malware, so a hit means REVIEW.
import shutil
import subprocess
import sys

from .common import REVIEW

CLAMSCAN_COMMAND = ["clamscan", "--no-summary", "--infected", "--stdout", "--"]
CLAMSCAN_FOUND_SUFFIX = " FOUND"
CLAMSCAN_RETURN_ERROR = 2


def run_clamav(books):
    """(book, finding) for every ClamAV signature hit, scanning all books in
    one run since loading the signature database takes a while."""
    if not books:
        return
    if not shutil.which("clamscan"):
        print("book-check: clamscan not installed, skipping the ClamAV scan", file=sys.stderr)
        return
    clamscan = subprocess.run(CLAMSCAN_COMMAND + books, capture_output=True, text=True, check=False)
    if clamscan.returncode == CLAMSCAN_RETURN_ERROR:
        print(f"book-check: clamscan failed: {clamscan.stderr.strip()}", file=sys.stderr)
    for line in clamscan.stdout.splitlines():
        if not line.endswith(CLAMSCAN_FOUND_SUFFIX):
            continue
        book, _, signature = line.removesuffix(CLAMSCAN_FOUND_SUFFIX).rpartition(": ")
        yield book, (REVIEW, f"ClamAV: {signature}")
