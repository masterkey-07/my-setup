# EPUB: sizes come from the zip's central directory, checked before reading
import posixpath
import re
import zipfile

from .common import (
    DANGER,
    MAGIC_BYTES_READ,
    REVIEW,
    is_executable,
    is_unsafe_member_path,
    shorten,
)

EPUB_MIMETYPE = b"application/epub+zip"
EPUB_TOTAL_SIZE_LIMIT = 2 * 1024 * 1024 * 1024
EPUB_BOMB_RATIO = 100
EPUB_BOMB_MIN_SIZE = 10 * 1024 * 1024
EPUB_TEXT_READ_LIMIT = 50 * 1024 * 1024
EPUB_TEXT_SUFFIXES = (
    ".xhtml",
    ".html",
    ".htm",
    ".svg",
    ".xml",
    ".opf",
    ".ncx",
    ".css",
    ".smil",
)
EPUB_EXECUTABLE_SUFFIXES = (
    ".exe",
    ".dll",
    ".so",
    ".dylib",
    ".sh",
    ".bat",
    ".cmd",
    ".ps1",
    ".vbs",
    ".js",
    ".mjs",
    ".jar",
    ".msi",
    ".com",
    ".scr",
    ".py",
)
# (verdict, what, pattern) checked on every text member. Plain <a href>
# links are fine: they only load when clicked
EPUB_SCRIPT = re.compile(r"<script\b([^>]*?)(?:/>|>(.*?)</script\s*>)", re.IGNORECASE | re.DOTALL)
EPUB_SCRIPT_SOURCE = re.compile(r"\bsrc\s*=\s*[\"']([^\"']*)", re.IGNORECASE)
EPUB_URL_SCHEME = re.compile(r"^[a-z][a-z0-9+.-]*:", re.IGNORECASE)
EPUB_TEXT_RULES = [
    (DANGER, "javascript: URL", re.compile(r"javascript\s*:", re.IGNORECASE)),
    (DANGER, "XML entity declaration (XXE)", re.compile(r"<!ENTITY", re.IGNORECASE)),
    (
        REVIEW,
        "event handler attribute (on...=)",
        re.compile(r"<[a-z][^>]*\son[a-z]+\s*=", re.IGNORECASE),
    ),
    (
        REVIEW,
        "<iframe>/<object>/<embed>/<form>",
        re.compile(r"<(?:iframe|object|embed|form)\b", re.IGNORECASE),
    ),
    (
        REVIEW,
        "remote resource loaded on open",
        re.compile(
            r"\bsrc\s*=\s*[\"']\s*https?:"
            r"|<(?:link|item|image)\b[^>]*\bhref\s*=\s*[\"']\s*https?:"
            r"|url\(\s*[\"']?\s*https?:"
            r"|@import\s+[\"']\s*https?:",
            re.IGNORECASE,
        ),
    ),
    (REVIEW, "file:// reference", re.compile(r"file://", re.IGNORECASE)),
]


def check_epub(path):
    try:
        with zipfile.ZipFile(path) as epub:
            members = epub.infolist()
            findings = epub_structure_findings(epub, members)
            if any(verdict == DANGER for verdict, _ in findings):
                # Don't decompress a zip bomb or follow traversal paths
                return findings
            return findings + epub_content_findings(epub, members)
    except (
        zipfile.BadZipFile,
        zipfile.LargeZipFile,
        NotImplementedError,
        RuntimeError,
    ) as error:
        return [(REVIEW, f"malformed zip: {error}")]


def epub_structure_findings(epub, members):
    findings = []
    if not is_mimetype_entry(epub, members[0] if members else None):
        findings.append((REVIEW, "malformed: mimetype is not the first entry"))
    unsafe_paths = [m.filename for m in members if is_unsafe_member_path(m.filename)]
    if unsafe_paths:
        findings.append((DANGER, "path traversal: " + shorten(unsafe_paths)))
    total_size = sum(m.file_size for m in members)
    if total_size > EPUB_TOTAL_SIZE_LIMIT:
        findings.append((DANGER, f"zip bomb: unpacks to {total_size // 2**20} MiB"))
    bombs = [
        m.filename
        for m in members
        if m.file_size > EPUB_BOMB_MIN_SIZE
        and m.file_size > EPUB_BOMB_RATIO * max(m.compress_size, 1)
    ]
    if bombs:
        findings.append(
            (
                DANGER,
                f"zip bomb: over {EPUB_BOMB_RATIO}x compression in " + shorten(bombs),
            )
        )
    return findings


def is_mimetype_entry(epub, member):
    # Size checked first: a huge "mimetype" would be read whole
    return (
        member is not None
        and member.filename == "mimetype"
        and member.file_size <= len(EPUB_MIMETYPE) + 2
        and epub.read(member).strip() == EPUB_MIMETYPE
    )


def epub_content_findings(epub, members):
    """Executables, scripts and the EPUB_TEXT_RULES matches, each listing
    the members it was found in."""
    member_names = {member.filename for member in members}
    found = {}
    for member in members:
        if member.is_dir():
            continue
        name = member.filename.lower()
        with epub.open(member) as member_file:
            head = member_file.read(MAGIC_BYTES_READ)
            if name.endswith(EPUB_EXECUTABLE_SUFFIXES) or is_executable(head):
                found.setdefault((DANGER, "executable or script file"), []).append(
                    member.filename
                )
            if not name.endswith(EPUB_TEXT_SUFFIXES):
                continue
            text = (head + member_file.read(EPUB_TEXT_READ_LIMIT)).decode(
                "utf-8", "replace"
            )
        for verdict, what in script_findings(text, member.filename, member_names):
            found.setdefault((verdict, what), []).append(member.filename)
        for verdict, what, pattern in EPUB_TEXT_RULES:
            if pattern.search(text):
                found.setdefault((verdict, what), []).append(member.filename)
    return [
        (verdict, f"{what} in {shorten(names)}")
        for (verdict, what), names in found.items()
    ]


def script_findings(text, member_name, member_names):
    """(verdict, what) for each kind of <script> in a member. Store copies
    (Kobo) reference scripts the file doesn't ship, which can't run."""
    findings = set()
    for script in EPUB_SCRIPT.finditer(text):
        source = EPUB_SCRIPT_SOURCE.search(script.group(1))
        if not source:
            if (script.group(2) or "").strip():
                findings.add((DANGER, "inline <script>"))
            continue
        url = source.group(1).strip()
        if EPUB_URL_SCHEME.match(url):
            findings.add((DANGER, "remote <script>"))
        elif (
            posixpath.normpath(posixpath.join(posixpath.dirname(member_name), url))
            in member_names
        ):
            findings.add((DANGER, "<script> shipped in the book"))
        else:
            findings.add(
                (
                    REVIEW,
                    "<script> pointing at a file the book doesn't ship (can't run)",
                )
            )
    return findings
