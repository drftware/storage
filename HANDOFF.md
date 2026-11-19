# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, ENG-29b done (D-475) · **Checks:** green · **Git:** `main`, not pushed; Brix `0b8c775` (pinned, not pushed).

## State
- **The owner's priority (D-436):** recipes, egg, incubator and chick first, built so new items join
  by data alone. Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, Part 2 only).
  Order: S5-03k1 to k6 (ROADMAP grep `S5-03k`).
- **Brix's recipes are whole** (ENG-29, D-474, D-475): `Brix.Recipes.book` checks rows and `find`s;
  `book:start(id, now, seed)` answers a record and a step, `book:due(record)`, `book:advance(record,
  now, happening?, into?)` catches up any gap, counts a happening, rolls chances from the record's
  seed and restarts `again` rows, at 0 bytes. Nothing in the game uses them yet.
- **Studio:** `rojo serve` in sync (port 34872), Edit, unsaved. **Brix:** clean at `0b8c775`.

## Next task: S5-03k1 Recipe rows and the save
The moment: the egg you carried home from a climb fits the incubator, and a new egg later joins the
hatch by one tag on its catalog row, with no code (Stardew Valley's 1.6 machine data). Pure; no screen.
1. Tags on finds: add a `tags` field to `art/finds/rows.py`'s `ROW` (a list of plain words, checked)
   and carry it into the generated finds module (never hand-edit generated files; rebuild by the
   script). Give the egg finds the `egg` tag (D-436 names which; if no egg find exists yet, the tag
   waits for S5-03k3 and the spec uses its own kinds). The incubator is a furniture piece (S5-03k3
   builds it): name its kind `Incubator` in the kinds table the module builds.
2. One data module (e.g. `src/shared/Home/RecipeRows.luau`, a header saying what it is) holding the
   game's rows, its looks table (names of motions only for now: `warming`, `wobbling`), and a
   `kinds()` built from the finds' tags plus the furniture pieces. Only the hatch ships: on
   `{ kind = "Incubator" }`, held `{ tag = "egg" }`, `put`, verb "Place", stages Warming
   (`time` 7200) and Wobbling (`time` 600), results `become` of "in" into "Chick", given back
   `beside`. Check the plan doc's Part 2 for the exact row; the doc wins over this list.
3. Lune spec `tests/reciperows.spec.luau`: the shipped rows make a book with no problems (check.sh
   fails on any); a bad row is caught (an unknown find, an unknown look, a stage that can't end);
   test-only rows (in the spec, never shipped) use every word of the vocabulary through the game's
   kinds and looks and pass with no code written for them.
4. **The no-names check** (run rules): a Lune spec or check.sh step that fails if any recipe code
   file (the rows module's code part, and every later recipe system or view file) names a find id.
   Only data rows may. Every later recipe session keeps it green.
5. A money report: what the hatch is worth per hour of incubator against a ceiling in Config (each
   feel number commented), and a spec that fails above it.
6. The save's next version (after 15) keeps each recipe in progress under its spot's id as a plain
   `RecipeRecord`, with a migration and its spec in `tests/save.spec.luau`; `Save.luau`'s header
   and CODEMAP updated.
7. Suggest other recipes (a seed in a pot, a battery on a charger) in OWNER.md as new design;
   never ship them.
**Acceptance:** check.sh green; the hatch row files with no problems; a bad row fails a spec; the
no-names check fails when a recipe code file names a find (prove it once, then revert); a v15 save
loads into the new version with no recipes under way; nothing outside data names "egg" or "Chick".
**Read first:** the plan doc, Part 2 (docs tools, search its heading); ROADMAP grep `S5-03k1`;
D-474 and D-475; `art/finds/rows.py` lines 30-45 and 171-240; `src/shared/Save.luau` lines 780-830
(the last versions and `format`); `../engine/docs/modules/Recipes.md`.

## Queue (next sessions, the owner's ticket order)
0. After S5-03k1: k2 to k6. **The shelf's cubby finds stand off the shelf** (D-470): two drawn
   8 and 12 studs in front of Medium's shelf (`Shelves`' `spotAt`?). The held-find view hides the
   crates at phone size. Pallet and camp bed cards float back in Small (D-461). Hide the minimap's
   "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox` (D-443); rename
   `BuildView.eyeBox` (D-444). Hand projections: use `lens` (D-446). `ToolView.luau` ~1293 reads
   on-screen as "ahead" (D-451). A blocked let-go may be judged blocked again (D-456). One lamp
   drag tocked three times (D-457). Sit and Open hide a held find's kept spot; a cubby find can't
   be held to open Arrange (D-466). After S5-03k: S5-03g2b's "Polish:" lines, g3b, then the
   climb run on hold (S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06). Home and Brix leftovers: ROADMAP's polish "Home leftovers (from HANDOFF, Nov 19)".

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
