# Storage (working title)

Co-op horror climb out of a living self-storage building. Design: the GDD (Claude Doc linked
in the owner's notes).

Sessions hand off through `HANDOFF.md` (now), `AGENTS.md` (rules), `OWNER.md` (what waits on the
owner) and `docs/` (roadmap, decisions, code map, Studio notes).

What's here so far:

- `art/unit/` — the storage unit: Blender pipeline, baked textures, the FBX for Studio, and
  its README (start there).
- `src/shared/StorageUnit/` — the roll-up door rig: `RollUpDoor`, `Motion`, `Curtain`,
  `UnitKit`, and the generated `Specs`.
- `src/client/` — renders every unit's door.
- `tests/` — Lune specs; `scripts/check.sh` runs format, lint, strict types, build and tests.

Tooling: `rokit install` (Rojo 7.7.1, Lune, Selene, StyLua, luau-lsp), Blender 5.2.
