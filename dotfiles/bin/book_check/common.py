# Verdicts and helpers shared by the PDF and EPUB checks and the report.
import os
import re

SHELF = os.path.realpath(os.path.expanduser(os.environ.get("BOOKS_DIR") or "~/Books"))
CLEAN, REVIEW, DANGER = 0, 1, 2
VERDICT_NAMES = {CLEAN: "CLEAN", REVIEW: "REVIEW", DANGER: "DANGER"}
MAGIC_BYTES_READ = 1024
MEMBERS_SHOWN = 3


def is_executable(data):
    """ELF or Windows PE (MZ header pointing at a PE signature)."""
    if data.startswith(b"\x7fELF"):
        return True
    if not data.startswith(b"MZ") or len(data) < 0x40:
        return False
    pe_offset = int.from_bytes(data[0x3C:0x40], "little")
    return data[pe_offset:pe_offset + 4] == b"PE\0\0"


def is_unsafe_member_path(name):
    normalized = name.replace("\\", "/")
    return (
        normalized.startswith("/")
        or re.match(r"^[A-Za-z]:", normalized) is not None
        or ".." in normalized.split("/")
    )


def shorten(names):
    shown = ", ".join(names[:MEMBERS_SHOWN])
    hidden = len(names) - MEMBERS_SHOWN
    return f"{shown} (+{hidden} more)" if hidden > 0 else shown


def display_path(path):
    return os.path.relpath(path, SHELF) if path.startswith(SHELF + os.sep) else path
