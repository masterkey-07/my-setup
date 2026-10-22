---
name: knowledge-vault
description: Read, search, and write notes in Victor's Obsidian vault at ~/Knowledge. Use whenever the user says "nota", "anotação", "anota isso", "faz uma nota sobre X", "make a note", "write this down", "add to my knowledge base", asks to research a topic into a note, or asks what his notes say about something.
---

# Knowledge vault

The vault is `/home/vjchave/Knowledge`. "Nota", "anotação", "note" and
"knowledge base" always mean this vault, never a folder in the current project.

**Before doing anything in the vault, read `/home/vjchave/Knowledge/AGENTS.md`
and follow it.** It is the single source of truth for the rules (ownership,
language, naming, note template, research contract), shared with other AI tools.

The short version, in case you need it before reading:

- Never edit or delete the user's notes. Only moving is allowed on them.
- Write only in `~/Knowledge/Generated/`, with the `#Generated` tag.
- Files in English, Title Case with spaces; use `[[wikilinks]]`.
- Use `generated_by: Claude` in front-matter.
