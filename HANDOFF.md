# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, ENG-29a done (D-474) · **Checks:** green · **Git:** `main`, not pushed; Brix `e4b0dd1` (pinned, not pushed).

## State
- **The owner's priority (D-436):** recipes, egg, incubator and chick first, built so new items join
  by data alone. Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, Part 2 only).
  Order: ENG-29b, then S5-03k1 to k6 (ROADMAP grep `S5-03k`).
- **The book is built** (Brix `Recipes.book`, D-474): every row checked once, faulty ones answered as
  problems; `find(on, held, into)` one lookup, flat to 30,000 rows at 0 bytes. The row shape is fixed
  (D-474 lists it); Switch, Play and Wind fit as press rows with stages and no results.
- **Studio:** `rojo serve` in sync (port 34872), Edit, unsaved. **Brix:** clean at `e4b0dd1`.

## Next task: ENG-29b Records, a recipe under way, in Brix
The moment: you leave the egg warming, log off, come back two hours later, and it's wobbling, as
Stardew Valley's incubator and Grow a Garden's eggs keep time while you're away. In `../engine` by its
AGENTS.md (neutral names, never egg or any find), then the pin moves. Pure; nothing ticks.
The `RecipeRecord` type is ready in `src/Contracts/Recipes.luau`: `recipe`, `stage` (from 1; one past
the last once ended), `began` (the stage's start, game seconds), `done` (presses or gifts so far),
`seed`. Add to the RecipeBook contract and stock book:
1. `start(id, now, seed) -> RecipeRecord?`: nil for an unknown id; a row with no stages starts ended.
2. `due(record) -> number?`: `began + seconds` while the stage ends by time; nil otherwise, or ended.
   A server keeps one due list of these; nothing is stepped.
3. `advance(record, now, happening?, into?) -> RecipeStep`, changing the record in place (a save holds
   it as it is). Happenings: `{ kind = "press", verb }`, `{ kind = "near", thing = Kind }`,
   `{ kind = "given", thing = Kind, verb }`, `{ kind = "event", name }`, matched by kind or tag as
   `find` does. Catch-up: while the stage is `time` and `now` has passed its end, end it and start
   the next at the old end (`began += seconds`, never `= now`), so any offline gap passes exactly as
   many stages as it covers. A press or gift counts toward `count`; a `given` with `useUp` says so in
   the step so the game takes the thing. A happening the stage doesn't want changes nothing.
4. `RecipeStep`: how many stages passed, `ended`, the `results` with each chance resolved (flattened,
   in row order), whether a gift was used up, and `again`: the record restarted at stage 1 from the
   moment it ended, its seed moved on so the next round rolls afresh. Fill `into` when given.
5. Chance from `Brix.Random.new({ seed = record.seed })`: the same record rolls the same after a reload.
6. Suite promises with the suite's own rows (the sprout through all three ends, the music box's
   presses then dawn then again, the shell's chance including "nothing" checked over many seeds
   against its odds, a gap of a week across the charger), proven to fail broken stand-ins; a bench
   advancing 1,000 records at 0 bytes once warm; the module page, CHANGELOG, Brix ROADMAP and its own
   commit (no trailer); then move `vendor/brix`, note it in `docs/FRAMEWORK.md`, tick ENG-29b here.
**Acceptance:** both repos' checks green; no Brix file names a find; a week offline passes stages
exactly; a chance's results match its odds over many seeds; advancing allocates nothing once warm.
**Read first:** `../engine/src/Contracts/Recipes.luau`; `../engine/src/Systems/Recipes.luau`;
`../engine/tests/conformance/Recipes.luau` (the rows); `../engine/docs/modules/Random.md`;
`../engine/docs/ROADMAP.md` (grep `ENG-29`); D-474.

## Queue (next sessions, the owner's ticket order)
0. After ENG-29b: S5-03k1 to k6. **The shelf's cubby finds stand off the shelf** (D-470): two drawn
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
