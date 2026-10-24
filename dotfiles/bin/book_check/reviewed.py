# Books marked reviewed, remembered by SHA-256 so they unmute when they change.
import hashlib
import os
import sys

from .common import display_path

REVIEWED_LIST = os.path.join(
    os.path.expanduser(os.environ.get("XDG_STATE_HOME") or "~/.local/state"), "book-check", "reviewed"
)
HASH_CHUNK_BYTES = 1024 * 1024


def file_hash(path):
    """SHA-256 of the file, or None when it can't be read."""
    digest = hashlib.sha256()
    try:
        with open(path, "rb") as book_file:
            while chunk := book_file.read(HASH_CHUNK_BYTES):
                digest.update(chunk)
    except OSError as error:
        print(f"book-check: cannot hash {path}: {error}", file=sys.stderr)
        return None
    return digest.hexdigest()


def load_reviewed():
    """Hashes of the books marked reviewed; lines are "<sha256>  <path>"."""
    try:
        with open(REVIEWED_LIST) as reviewed_file:
            return {line.split()[0] for line in reviewed_file if line.strip()}
    except FileNotFoundError:
        return set()


def mark_reviewed(books):
    os.makedirs(os.path.dirname(REVIEWED_LIST), exist_ok=True)
    with open(REVIEWED_LIST, "a") as reviewed_file:
        for book in books:
            digest = file_hash(book)
            if digest is None:
                continue
            reviewed_file.write(f"{digest}  {book}\n")
            print(f"marked reviewed: {display_path(book)}")
