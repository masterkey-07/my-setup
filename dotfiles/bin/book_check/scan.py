# Finding the books and sending each one to the check for its real type.
import os

from .common import DANGER, MAGIC_BYTES_READ, REVIEW, is_executable
from .epub import check_epub
from .pdf import check_pdf

BOOK_TYPES = {".pdf": "pdf", ".epub": "zip"}
TYPE_DESCRIPTIONS = {"pdf": "a PDF", "zip": "a zip archive", "unknown": "neither PDF nor EPUB"}


def scan_paths(paths):
    """Real paths of the books: files given directly, and the PDFs/EPUBs
    under the folders (hidden folders like .stfolder skipped)."""
    for path in paths:
        if not os.path.isdir(path):
            yield os.path.realpath(path)
            continue
        for root, dirs, files in os.walk(path):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for name in files:
                if name.lower().endswith(tuple(BOOK_TYPES)):
                    yield os.path.realpath(os.path.join(root, name))


def check_book(path):
    """Findings for one book, as (verdict, message) pairs."""
    try:
        with open(path, "rb") as book_file:
            head = book_file.read(MAGIC_BYTES_READ)
        file_type = detect_type(head)
        extension = os.path.splitext(path)[1].lower()
        expected = BOOK_TYPES.get(extension)
        if file_type == "executable":
            return [(DANGER, "is an executable program, not a book")]
        if expected and file_type != expected:
            return [(DANGER, f"content is {TYPE_DESCRIPTIONS[file_type]}, not {extension}")]
        if file_type == "pdf":
            return check_pdf(path)
        if file_type == "zip":
            return check_epub(path)
        return [(REVIEW, "not a PDF or EPUB")]
    except OSError as error:
        return [(REVIEW, f"unreadable: {error}")]


def detect_type(head):
    # Readers accept the PDF header anywhere in the first KB
    if b"%PDF-" in head:
        return "pdf"
    if head.startswith(b"PK\x03\x04"):
        return "zip"
    if is_executable(head):
        return "executable"
    return "unknown"
