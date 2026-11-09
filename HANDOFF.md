# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 43 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-12b1 is done** (D-052): the crawl hole's art. `art/hole/` builds a unit's side wall with a
  low ragged hole sawn through it (each size, each side, in the unit's own wall texture), the
  bright strip of bare steel round the cut, tongues of steel bent away from the saw, and the
  cut-out panel flat on its ribs on the far side, both ways round; one 512² Hole bake; FBX,
  `src/shared/StorageUnit/CrawlHole/Specs.luau`, five sheets (`art/sheets/hole-*.png`). The hole
  opens at the same place in every unit: `crawl_*` in `art/unit/spec.py` (3.75 to 6.75 along,
  0.3 to 2.9 up). Uploaded (`art/hole/assets.json`), prepared at `ReplicatedStorage.Props.CrawlHole`.
- `CrawlHole.saw(from, into)` (shared, run on the server) finds the wall two units in a row
  share, swaps it for the holed one, lays `CrawlEdge` and `CrawlPanel`, marks the wall's
  `CrawlHole` attribute ("Pos"/"Neg"), and splits its collider into four round the hole
  (`CrawlHole.Boxes`, pure; `tests/crawlhole.spec.luau`). The test hall saws 101 into 103 and
  104 into 102 as it's laid.
- **Verified in Studio** (test hall; a computer view and the Galaxy A16): both holes cut where
  they should, the panel in the unit it fell into, the colliders split; from 101's and 103's
  doorways the hole reads at once, lit and with the neighbour shut (`docs/art/L-12b1-*.jpg`).
  Not seen: a friend's view (it's all server-built parts, so it replicates as the units do).
  Studio left in Edit, Play stopped, simulator off. Save the place (`OWNER.md`). No owner
  results came this session (the overnight run).

## Next task: L-12b2 Sawing it
The moment: you hold Saw at the wall, the motor screams through the whole floor, a bright line
crawls round the cut, and the panel clangs down on the other side. Everything heard it.
1. Owner test results first (`OWNER.md`).
2. Read how Cut is held at a door (Door.Holds, Doors' checks and `acted`, the cutters' `use`
   pose in `Catalog`) and decide where Saw lives: a button inside a unit at its side wall's hole
   spot (`CrawlHole.Specs` From/To), only where a neighbour in the same row shares the wall
   (`CrawlHole`'s `between` logic: export it).
3. Server: range, saw in hand (else "Hold the saw"), rate, the wall not holed yet; on the hold's
   end `CrawlHole.saw(yourUnit, theirUnit)`; an event keepers can hear floor-wide (L-06b).
4. Feel: the saw's `use` pose out at the wall, the motor's whine and the blade's chatter (loud,
   Pro Sound Effects by loudness, as the cutters' snap), a growing bright line round the cut as
   you hold, a jolt of your view, the panel's clang on the far side.
5. `DealSpot`: keep a dealt tool or find off the hole's spot on both sides of a side wall.
6. Drop the test hall's ready-cut holes only in L-12b3 (crawling); keep them for now.
**Acceptance:** checks green; in Studio, holding Saw in 101 at its right wall cuts the hole into
103 with the sound and the line, refused without the saw; Lune checks for any new pure rule;
owner's checks in `OWNER.md`.
**Read first:** ROADMAP L-12; `src/shared/StorageUnit/CrawlHole/init.luau`;
`src/shared/StorageUnit/Door.luau` (Holds, decide); `src/server/Doors.luau` (Cut's path);
`src/shared/Tools/Catalog.luau` (the Saw row, the cutters' `use`); `src/shared/DealSpot.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-12b2, L-12b3 (crawling through). L-06b the Mannequin hunts **waits on Brix**: ENG-07a/b (a
   chase in a place) aren't built, and this repo never edits Brix; a Brix session first. L-12c
   the hole trap needs L-06b's keepers. Then L-13, L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. **Check, small:** G is both a door's Slam and Drop (ToolView binds G since L-11b): with a tool
   in hand, does G at an open door slam, drop, or both? Give Drop its own key if it clashes.
4. L-06b's keepers stand at `Deals.dealt`'s place, hear doors on `Doors.acted` (a Cut carries 40
   studs), the keypad on `Elevators.acted`, a dropped tool on `Slots.changed`, the saw (L-12b2);
   keepers with eyes see a torch (`Flashlights.switched`, GDD); hand `Deal.open` the awake now.
5. **Check:** floor 1's laying peaked at 59 ms in a frame this session (13.3 ms in session 42).
6. Studio traps (docs/STUDIO.md): the test hall and the walked floor share unit names (pick by
   Z); a Client `execute_luau` has its own `require` (edit, sync, Play again); `insert_asset`
   turns a model (square it by a part's CFrame); walk a step before a capture or it's black; set
   the Device Simulator's device in Edit before Play.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
