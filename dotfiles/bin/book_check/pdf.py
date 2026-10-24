# PDF: only object dictionaries are searched (the file body and the inflated
# object streams), never page or image data, where random bytes spell names
# like /JS. Inflating is capped per stream, so a decompression bomb only costs
# this much memory
import re
import zlib

from .common import DANGER, REVIEW, is_executable, is_unsafe_member_path, shorten

PDF_STREAM_INFLATE_LIMIT = 64 * 1024 * 1024
PDF_EOF_SEARCH_BYTES = 1024
PDF_OBJECT = re.compile(rb"(\d+)\s+\d+\s+obj\b(.*?)endobj", re.DOTALL)
PDF_STREAM = re.compile(rb"stream(?:\r\n|\r|\n)(.*?)endstream", re.DOTALL)
PDF_REFERENCE = re.compile(rb"(\d+)\s+\d+\s+R")
PDF_NAME_HEX_ESCAPE = re.compile(rb"#([0-9A-Fa-f]{2})")
PDF_NAME_END = rb"(?![A-Za-z0-9])"
PDF_JAVASCRIPT_ACTION = re.compile(rb"/S\s*/JavaScript" + PDF_NAME_END + rb"|/JS" + PDF_NAME_END)
# The /JavaScript entry of the catalog's /Names: scripts run when the file opens
PDF_DOCUMENT_JAVASCRIPT = re.compile(rb"/JavaScript\s*(?:\d+\s+\d+\s+R|<<)")
PDF_LAUNCH_ACTION = re.compile(rb"/S\s*/Launch" + PDF_NAME_END)
PDF_FILE_NAME = re.compile(rb"/(?:F|UF)\s*\(([^)]*)\)")
# Per-platform launch parameters (/Win <</F (cmd.exe) /P (args)>>)
PDF_PLATFORM_LAUNCH = re.compile(rb"/(?:Win|Unix|Mac)\s*<<")
PDF_PROGRAM_SUFFIXES = (
    ".exe", ".bat", ".cmd", ".com", ".scr", ".ps1", ".vbs", ".js", ".jar",
    ".sh", ".py", ".msi", ".lnk", ".app", ".desktop",
)
PDF_VALUE_PEEK_BYTES = 2048
PDF_REVIEW_KEYWORDS = {
    "EmbeddedFile": "embedded file",
    "RichMedia": "rich media (Flash/video)",
    "XFA": "XFA form",
    "SubmitForm": "form that submits data",
    "ImportData": "imports external data",
    "GoToR": "link that opens another file",
}


def check_pdf(path):
    with open(path, "rb") as pdf_file:
        data = pdf_file.read()
    findings = []
    if b"%%EOF" not in data[-PDF_EOF_SEARCH_BYTES:]:
        findings.append((REVIEW, "malformed: no %%EOF at the end (truncated or appended data)"))
    objects, unreadable_object_streams, has_executable = parse_pdf_objects(data)
    if has_executable:
        findings.append((DANGER, "contains an embedded executable program"))
    if unreadable_object_streams:
        findings.append((
            REVIEW,
            f"{unreadable_object_streams} object streams not inspected (encrypted or unsupported filter)",
        ))
    return findings + pdf_javascript_findings(objects) + pdf_launch_findings(objects) + pdf_keyword_findings(objects)


def parse_pdf_objects(data):
    """({object number: dictionary}, object streams that could not be read,
    whether any stream holds an executable)."""
    objects = {}
    unreadable_object_streams = 0
    has_executable = False
    for match in PDF_OBJECT.finditer(data):
        body = match.group(2)
        stream = PDF_STREAM.search(body)
        dictionary = normalize_names(body[:stream.start()] if stream else body)
        objects[int(match.group(1))] = dictionary
        if not stream:
            continue
        # Only Flate is inflated; other filters are rare outside images
        inflated = inflate(stream.group(1))
        has_executable = has_executable or is_executable(stream.group(1)) or is_executable(inflated or b"")
        if b"/ObjStm" not in dictionary:
            continue
        contained = parse_object_stream(dictionary, inflated) if inflated else None
        if contained is None:
            unreadable_object_streams += 1
        else:
            objects.update(contained)
    return objects, unreadable_object_streams, has_executable


def inflate(raw):
    """Flate-decoded stream (at most PDF_STREAM_INFLATE_LIMIT bytes), or None
    when the stream isn't Flate."""
    try:
        return zlib.decompressobj().decompress(raw, PDF_STREAM_INFLATE_LIMIT)
    except zlib.error:
        return None


def parse_object_stream(dictionary, inflated):
    """{object number: dictionary} for the objects packed in an object
    stream, or None when its header doesn't parse. The header is pairs of
    (object number, offset) ending at /First."""
    first = re.search(rb"/First\s+(\d+)", dictionary)
    if not first:
        return None
    start = int(first.group(1))
    try:
        numbers = [int(token) for token in inflated[:start].split()]
    except ValueError:
        return None
    pairs = list(zip(numbers[0::2], numbers[1::2]))
    ends = [offset for _, offset in pairs[1:]] + [len(inflated) - start]
    return {
        number: normalize_names(inflated[start + offset:start + end])
        for (number, offset), end in zip(pairs, ends)
    }


def normalize_names(data):
    # Names may hide behind hex escapes: /J#61vaScript is /JavaScript
    if b"#" not in data:
        return data
    return PDF_NAME_HEX_ESCAPE.sub(lambda match: bytes([int(match.group(1), 16)]), data)


def pdf_javascript_findings(objects):
    """DANGER when JavaScript runs by itself (on open, or on page/field
    events); REVIEW when it only sits behind links or form buttons."""
    if not any(PDF_JAVASCRIPT_ACTION.search(dictionary) for dictionary in objects.values()):
        return []
    triggers = set()
    for dictionary in objects.values():
        names = value_of(objects, dictionary, b"Names")
        if names and PDF_DOCUMENT_JAVASCRIPT.search(names):
            triggers.add("document-level script")
        open_action = value_of(objects, dictionary, b"OpenAction")
        if open_action and is_javascript_action(objects, open_action):
            triggers.add("/OpenAction")
        additional_actions = value_of(objects, dictionary, b"AA")
        if additional_actions and is_javascript_action(objects, additional_actions):
            triggers.add("/AA page or field event")
    if triggers:
        return [(DANGER, "JavaScript that runs by itself: " + ", ".join(sorted(triggers)))]
    return [(REVIEW, "JavaScript in links or forms (runs only when used)")]


def value_of(objects, dictionary, key):
    """The value of /key in a dictionary, following an indirect reference;
    inline dictionaries are cut at their closing >>."""
    match = re.search(rb"/" + key + PDF_NAME_END, dictionary)
    if not match:
        return None
    rest = dictionary[match.end():].lstrip()
    reference = PDF_REFERENCE.match(rest)
    if reference:
        return objects.get(int(reference.group(1)), b"")
    if rest.startswith(b"<<"):
        return inline_dictionary(rest)
    return rest[:PDF_VALUE_PEEK_BYTES]


def inline_dictionary(text):
    depth = 0
    for index in range(len(text) - 1):
        pair = text[index:index + 2]
        depth += (pair == b"<<") - (pair == b">>")
        if depth == 0:
            return text[:index + 2]
    return text


def is_javascript_action(objects, action):
    """An action, or a dictionary of actions (/AA), that is or references a
    JavaScript action. /Next chains aren't followed."""
    if PDF_JAVASCRIPT_ACTION.search(action):
        return True
    return any(
        PDF_JAVASCRIPT_ACTION.search(objects.get(int(reference.group(1)), b""))
        for reference in PDF_REFERENCE.finditer(action)
    )


def pdf_launch_findings(objects):
    """/Launch actions: DANGER when they can start a program, REVIEW when
    they open a file next to the book (books converted from CHM link their
    chapters this way)."""
    targets = []
    is_program_launch = False
    for dictionary in objects.values():
        if not PDF_LAUNCH_ACTION.search(dictionary):
            continue
        file_spec = value_of(objects, dictionary, b"F") or b""
        names = [name.decode("latin-1") for name in PDF_FILE_NAME.findall(dictionary + file_spec)]
        targets.extend(names or ["(unknown target)"])
        is_program_launch = (
            is_program_launch
            or not names
            or PDF_PLATFORM_LAUNCH.search(dictionary) is not None
            or any(is_program_target(name) for name in names)
        )
    if not targets:
        return []
    if is_program_launch:
        return [(DANGER, "/Launch action that can start a program: " + shorten(targets))]
    return [(REVIEW, "/Launch action opening a file next to the book: " + shorten(targets))]


def is_program_target(name):
    """A program, or a path leaving the book's folder."""
    return (
        name.lower().endswith(PDF_PROGRAM_SUFFIXES)
        or name.startswith(("/", "\\"))
        or is_unsafe_member_path(name)
    )


def pdf_keyword_findings(objects):
    findings = []
    for keyword, description in PDF_REVIEW_KEYWORDS.items():
        pattern = re.compile(rb"/" + keyword.encode() + PDF_NAME_END)
        if any(pattern.search(dictionary) for dictionary in objects.values()):
            findings.append((REVIEW, f"/{keyword}: {description}"))
    return findings
