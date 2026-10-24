# The printed report and the desktop notification.
import subprocess
import sys

from .common import CLEAN, DANGER, REVIEW, VERDICT_NAMES, display_path
from .reviewed import file_hash

NOTIFY_TIMEOUT_MS = 15000


def report(results, reviewed):
    """Print the flagged books, worst first, then a summary; returns the
    number of books per verdict, not counting books marked reviewed."""
    counts = {CLEAN: 0, REVIEW: 0, DANGER: 0}
    muted = 0
    verdicts = {book: max((v for v, _ in findings), default=CLEAN) for book, findings in results.items()}
    for book in sorted(results, key=lambda book: (-verdicts[book], book)):
        if verdicts[book] != CLEAN and file_hash(book) in reviewed:
            muted += 1
            continue
        counts[verdicts[book]] += 1
        if verdicts[book] == CLEAN:
            continue
        print(f"{VERDICT_NAMES[verdicts[book]]:<7} {display_path(book)}")
        for verdict, message in sorted(results[book], reverse=True):
            print(f"        {VERDICT_NAMES[verdict].lower()}: {message}")
    summary = f"{len(results)} books: {counts[CLEAN]} clean, {counts[REVIEW]} to review, {counts[DANGER]} dangerous"
    print(summary + (f", {muted} marked reviewed" if muted else ""))
    return counts


def notify(counts):
    if not counts[REVIEW] and not counts[DANGER]:
        return
    urgency = "critical" if counts[DANGER] else "normal"
    message = f"{counts[DANGER]} dangerous, {counts[REVIEW]} to review. Run book-check for details."
    command = ["notify-send", "-u", urgency, "-t", str(NOTIFY_TIMEOUT_MS), "-i", "dialog-warning", "Books", message]
    try:
        subprocess.run(command, check=True)
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"book-check: could not send the notification: {error}", file=sys.stderr)
