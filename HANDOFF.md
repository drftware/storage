# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 46 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13a is done** (D-055): the tops closed. `Floor` (pure) now lists `lids`, an S unit's wire
  top over every junction corner square a run reaches (blocks of wall, a corner's outside square),
  so a run turns the corner (`Run.lids`), and `panels`, the kit's plain-wall panel from the cap up
  through the deck at every other drop off the tops, found as 4-stud stretches and closed line by
  line (rows' backs, the step beside an 8-deep unit, a run's end at the lobby, a lid over an empty
  slot); `bare` panels turn their bare sheet and the wall's trim to a pit with no wall of its own.
  `tests/floor.spec.luau` proves over 400 floors on a 2-stud raster that no edge is left open, no
  panel blocks the tops or hangs in a hall, none is bare inside a unit. `CorridorKit.panel` lays
  one (sheet on the face's line, collider cap to deck); `FloorBuilder` lays lids and panels with
  their hall piece. The tops map shows lids as `=`.
- **Verified in Studio** (Play, floor 1 of seed 7): 78 panels (19 bare) and 13 lids laid, matching
  the data; 702 of 702 rays from the tops hit a panel, every lid point lands on a wire top;
  frictionless blocks slid into every panel and across every lid four ways, none fell. Lit on the
  client for screenshots: the backs closed to the deck, the step flush, corners closed, through a
  corner's lid the junction's concrete and sheet walls (it showed the night sky before the bare
  panels). A standing avatar teleported onto a lid wedges (3.9 studs to the deck), doesn't fall.
  Laying: 72 ms over 15 frames. Studio left in Edit, Play stopped. No owner results came.

## Next task: L-13b1 The ladder's art, carried and dropped
The moment (for L-13b2): the team hears a keeper, one friend drags the long ladder to a unit, and
they go up out of reach. First the ladder must exist and be a heavy, visible thing to carry.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's Tools section (the ladder) only; read how the saw was built and brought in
   (`art/saw/`, its README, D-051) and its `Tools/Catalog` row.
3. Build the ladder the unit's way (`art/unit/README.md`): an aluminium extension ladder that
   leans on a unit's front and reaches the wire top (10 studs), rungs at a real pitch, scuffed
   rails, its own small texture set or the TrimSheet; FBX, a generated Specs module, look sheets.
4. Upload (`scripts/upload_art.luau`), insert and prepare it at `ReplicatedStorage.Props.Tools`
   (the owner saves the place: add it to OWNER.md's save item).
5. A `Tools/Catalog` row: carried in both hands, low and slow (Lethal Company's extension ladder),
   laid where the deal puts it, picked up and dropped with its sounds.
**Acceptance:** checks green; in Studio the ladder lies where dealt and by the spawn, is picked
up, carried and dropped with sound; judged at phone size (Galaxy A16).
**Read first:** ROADMAP L-13b1; DECISIONS D-051 (the saw's art) and D-050 (tools on the floor);
`art/saw/README.md`; `src/shared/Tools/Catalog.luau` (the Saw row); GDD Tools (the ladder).

## Queue (the next run's order, from ROADMAP)
1. L-13b1, then L-13b2 (lean, climb, crawl the tops; default crawl-only, OWNER.md). L-06b the
   Mannequin hunts **waits on Brix**: ENG-07a/b (a chase in a place) aren't built, and this repo
   never edits Brix; a Brix session first. L-12c needs L-06b's keepers. Then L-14; L-07, L-08,
   L-10, L-09.
2. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
   Take either, as CrawlView's `joint()`; check with two players.
3. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
4. **Check, small:** G is both a door's Slam and Drop (ToolView binds G since L-11b): with a tool
   in hand, does G at an open door slam, drop, or both? Give Drop its own key if it clashes.
5. L-06b's keepers stand at `Deals.dealt`'s place, hear doors on `Doors.acted`, the keypad on
   `Elevators.acted`, a dropped tool on `Slots.changed`, the saw on `Saws.sawing` (200 studs), a
   crawl on `Crawls.crawled` (35); keepers with eyes see a torch (`Flashlights.switched`); a
   keeper's path treats a holed wall as solid; keepers can't reach the tops (`Floor.runs`, lids).
6. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not in our code; find what asks for it (the place, a plugin).
7. Studio traps (docs/STUDIO.md): the tops are black on screen (light the Client to judge them);
   the test hall and the walked floor share unit names (pick by Z); physics probes spawned on one
   spot fling each other.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
