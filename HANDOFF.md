# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j7b2 done and the room editor (S5-03j) closed (D-473) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** the room editor is closed; the recipes now, egg, incubator
  and chick first, built so new items join by data alone. Plan:
  https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools; this brief quotes what ENG-29a
  needs). Order: ENG-29a, ENG-29b, S5-03k1 to k6 (ROADMAP grep `S5-03k`).
- **Arrange:** wiring only (D-472); leftovers in ROADMAP's polish "The room editor's leftovers".
- **Studio:** `rojo serve` in sync (port 34872), Edit, unsaved. **Brix:** clean at `cea1259`.

## Next task: ENG-29a The recipe book, in Brix (rows in, checked, filed, one lookup)
The moment: carry an egg near the incubator and its lamp brightens (Stardew Valley's incubator,
Grow a Garden's eggs); this is the book that knows the egg goes in. In `../engine` by its
AGENTS.md (neutral names; never egg, chick or any find), then the pin moves. Pure, nothing ticks.
The plan's vocabulary, quoted (Part 2, "The fixed vocabulary"):
- "What starts it: you hold one thing and press its verb on another; you press something with
  empty hands; you set one thing down on or beside another."
- "What moves a stage on: real time passing, counted while you're offline too; a number of
  presses ("wind it five times"); something nearby: a lit lamp within reach of it, a thing of a kind
  next to it; something given: hold the watering can and press Water; something done elsewhere:
  after your next climb, as Adopt Me's eggs hatch from tasks."
- "What happens: become: what's inside turns into another find; make: new finds appear, beside
  it or in your box; use up: what went in is gone; give back: what went in returns to your box;
  chance: one of several results, odds shown on the thing before you start; again: the recipe
  starts over by itself."
- "How each stage looks: a motion from the find's own art kit, a glow, a sound, and whether it
  grows toward the end. No numbers, no countdowns."
1. Read `../engine/AGENTS.md`, then model the module on Placements (its contract, suite, page).
2. A `Recipes` contract: the closed vocabulary as frozen name lists (starts: `put`, `use`,
   `press`; stage ends: `time`, `presses`, `near`, `given`, `event`; results: `become`, `make`,
   `useUp`, `giveBack`, `chance`, `again`; looks: a stage names a look by key, checked against a
   looks table the game passes in). A row: what it's used on (a kind or a tag), what's held (a
   kind, a tag, or nothing), its start, its stages (each one end and one look), its results.
3. `Recipes.book(rows, catalog, looks)`: checks every row once (an unknown word, an unknown kind
   or tag, a stage that can't end, a chance whose odds don't sum to 1, a result naming nothing)
   and returns the problems as a list (never throws mid-game); files rows by what they're used on,
   then what's held, kind before tag. `book:find(onKind, onTags, heldKind?, heldTags?)` is the one
   lookup: no scan of all rows, allocation-free on the hot path (fill a list passed in).
4. The suite carries test-only rows that use every word (a seed in a pot through three stages, a
   battery on a charger, two things combined into one, a chance result, one that repeats, an
   empty-handed press), plus a bench of a few thousand rows proving the lookup's cost is flat.
   Records (start, advance, due, chance's seed) are ENG-29b: leave the types ready for them.
5. Module page, Brix ROADMAP (ENG-29a ticked, b promoted), its checks, its own commit; then move
   `vendor/brix` and note it in `docs/FRAMEWORK.md` in the game commit.
**Acceptance:** both repos' checks green; no Brix file names a find; every word used by a
test-only row; the lookup filed (not scanned) and benched.
**Read first:** `../engine/AGENTS.md`; `../engine/src/Contracts/Placements.luau` (shape of a
contract); `../engine/docs/modules/Placements.md`; `../engine/docs/ROADMAP.md` lines 756-800
(ENG-26's split, where ENG-29 goes); ROADMAP's ENG-29 lines here (grep `ENG-29`); D-436.

## Queue (next sessions, the owner's ticket order)
0. After ENG-29: S5-03k1 to k6. **The shelf's cubby finds stand off the shelf** (D-470): two drawn
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
