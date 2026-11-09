# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 42 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-12a is done** (D-051): the saw. A green cordless reciprocating saw built from code in
  `art/saw/` (the cutters' way: spec in a real saw's inches scaled by `IN`, one baked 1024² set,
  6,168 triangles, FBX, `src/shared/Tools/Specs/Saw.luau` with the blade's tip and the shoe's
  face, four sheets), uploaded (`art/saw/assets.json`), prepared at
  `ReplicatedStorage.Props.Tools.Saw`, and a `Catalog.Saw` row: held low on your left turned in
  26°, blade to the middle, clear of the slots' bar on a phone; carried upright at a friend's
  side; a plastic knock picking it up, a plastic slam dropping it. It stands on its battery
  where it's laid. Floors 1 and 2 already put a saw first out of the bag, so it lies there now.
- `tests/carry.spec.luau` now checks each Catalog row is a dealt tool with a generated Specs.
- **Verified in Studio** (floor 1, seed 7; Galaxy A16 and a computer view): unit 104 dealt the
  saw ("Deals: Unit104 held a tool, Saw"), it stood in the bulb's pool and read from the doorway,
  was picked up (slot 1, its picture in the bar), sat left of the bar in hand, and dropped
  upright crosswise 2.2 studs ahead (`docs/art/L-12a-*.jpg`). Not seen: a friend's view (numbers
  only: upright, blade forward, hip height), the sounds (unheard), real phone taps (`OWNER.md`).
  Studio left in Edit, Play stopped, simulator off; Workspace's `DevFloorNumber` is now 1.
- No owner test results came this session (the overnight run). Save the place (`OWNER.md`):
  `Props.Tools.Saw` lives only in the open place.

## Next task: L-12b1 The crawl hole's art
The moment: you've sawn through and a ragged square of light opens into the next unit, low
enough that you duck through and the Mannequin can't follow. This ticket builds the hole.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's "The hole trap" and how a unit's side walls are built: are two neighbours'
   side walls one shared panel or two (`art/unit/README.md`, `spec.py`, D-031)?
3. Size the hole: a player passes it by a "Crawl through" prompt (L-12b2), so it can be lower
   than a standing player; a keeper (the Mannequin's Specs) must not fit. Write the numbers in
   the unit's spec.
4. Build the holed side wall the unit's way: a low square hole in the corrugated steel, its cut
   edge ragged and bright with bent tabs, the cut panel lying on the far side; the unit's
   texture sets, FBX, generated Specs, look sheets from both sides; `scripts/art.sh` rebuilds it.
5. Import and prepare it; a pure-or-server function swaps one unit's side wall for the holed one
   (both units, if the wall is two panels), tried from a Studio dev command.
6. Judge it from both units on the Galaxy A16, lit and dark.
**Acceptance:** checks green; the art rebuilds from its script; in Studio a hole swapped into a
unit's side wall reads from both sides on the phone; shots in `docs/art/`; owner's checks in
`OWNER.md`. If the wall swap won't fit beside the art, split it off in ROADMAP first.
**Read first:** ROADMAP L-12; the GDD's "The hole trap" (docs tools, never WebFetch);
`art/unit/README.md`; `art/unit/spec.py` (Grep the side walls); DECISIONS D-031;
`art/saw/README.md` (the newest art build to copy).

## Queue (the next run's order, from ROADMAP)
1. L-12b1, L-12b2 (sawing it, crawling through). L-06b the Mannequin hunts **waits on Brix**:
   ENG-07a/b (a chase in a place) aren't built, and this repo never edits Brix; a Brix session
   first. L-12c the hole trap needs L-06b's keepers. Then L-13, L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. **Check, small:** G is both a door's Slam and Drop (ToolView binds G since L-11b): with a tool
   in hand, does G at an open door slam, drop, or both? Give Drop its own key if it clashes.
4. L-06b's keepers stand at `Deals.dealt`'s place, hear doors on `Doors.acted` (a Cut carries 40
   studs), the keypad on `Elevators.acted`, a dropped tool on `Slots.changed`, the saw (L-12b2);
   keepers with eyes see a torch (`Flashlights.switched`, GDD); hand `Deal.open` the awake now.
5. **Check:** floor 1's laying peaked at 13.3 ms in one frame under the simulator (session 42);
   floor 3's 6.4 to 12.2 ms before.
6. Studio traps (docs/STUDIO.md): the test hall and the walked floor share unit names (pick by
   Z); a Client `execute_luau` has its own `require` (edit, sync, Play again); hold a prompt with
   `InputHoldBegin` while on screen; walk a step before a capture or it comes back black; set the
   Device Simulator's device in Edit before Play.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
