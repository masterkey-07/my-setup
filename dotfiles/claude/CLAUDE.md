# Global notes

- My notes / knowledge base is the Obsidian vault at `~/Knowledge`; use the
  `knowledge-vault` skill. Never edit my own notes there unless I explicitly
  ask; Claude writes only in `~/Knowledge/Generated/` with the `#Generated` tag.

# Clean code

Write code clean and organized, scaled to its lifespan: one-liners and
throwaway scripts just need to be readable; code that will be kept gets the
full treatment below.

- **Consistency first**: follow the existing project's style, formatter, and
  idioms; the rules below apply only where they don't conflict with it.
- **Scope**: organize the code you write or change. Flag problems in nearby
  code instead of fixing them; don't rewrite unrelated code without asking.
- **Names**: descriptive and intention-revealing; no cryptic abbreviations.
  Booleans read as questions (`isValid`, `hasAccess`).
- **Small, focused functions** with flat control flow (early returns/guard
  clauses); no duplication; no magic values — use named constants.
- **Structure**: group related code; order top-down (entry point first,
  details below).
- **Comments explain *why*, not *what***; no commented-out code.
- **Error handling**: handle errors explicitly and close to the source; never
  silently swallow exceptions.
