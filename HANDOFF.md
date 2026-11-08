# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 24 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-01d is done** (D-031), on the owner's default: crawl holes only between side-by-side units,
  tops along a row. `Floor` records each slot's `left`, `right` and `back` (the slot sharing at
  least 4 studs of that wall, `CrawlWidth`) and the floor's `runs` (a row's slots side by side);
  every plain wall in a run with a unit has `top` set. Rules from 400 seeds: a random plain wall
  never strands a unit; floors 1 and 2 (`teachHoles`) keep the hall from the lobby to the first
  fork free of plain walls, three S units on a back-cornered side. Every floor has 36+ crawl
  pairs; floors 1 and 2 have 4+ before the first fork and none cut off; full floors at most 2.
- **Lids:** `FloorBuilder` puts the unit template's own wire top and floor (with colliders) over a
  lidded plain wall's slot. Verified in Studio (Play, server): floor 3 of seed 7 got 9 lids, each
  at 10.05 and flush with its neighbour's top, Output clean. Not seen on screen: a capture 600
  studs from the player came back as sky (most likely streaming; `docs/STUDIO.md`).
- **Maps:** `scripts/floor-map` marks a unit with no crawl neighbour `x` and prints "The tops"
  (a letter per run); `scripts/floor-survey` prints each measure's spread over many seeds.
- **L-02's doors** (D-030) are as last session: verified with one player; two players, a phone and
  a forged press are untested (`OWNER.md`).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: L-04 What's behind the door (split it first)
The moment: the slow, loud open, and not knowing what's in there: a find to grab, a note with a
digit of the code, nothing, or a keeper standing in the dark. The props come first (real assets).
1. Owner test results first (`OWNER.md`), and any answer on holes and tops (its "Decide" section).
2. Read the GDD's "What's behind the door" (only that section; the keepers' table only if it
   names one that waits in a unit).
3. Split L-04 in `docs/ROADMAP.md`: L-04a the props a unit's contents are made of (boxes, the
   finds, whatever the GDD names), built the unit's way; L-04b a first director dealing each
   unit's contents on open, and which doors start padlocked (`Doors:lock(unit, true)`). The
   sticky note is L-05's; a keeper in a unit waits on L-06, so L-04b deals "a keeper" as a marker.
4. Do L-04a: one Blender script per prop set under `art/`, parts UV-mapped to the unit's texture
   sets where they fit, FBX, a generated Specs module, look sheets; imported and judged at phone
   size inside an open unit, under the hall light and the dark.
**Acceptance:** checks green; the props in the place, judged inside a unit in Studio at phone size;
`OWNER.md` says what to judge and the template paths to save.
**Read first:** `docs/ROADMAP.md` (L-04, L-05); the GDD's "What's behind the door";
`art/unit/README.md`; `docs/STUDIO.md` (Blender 5.2 and the FBX recipe); `scripts/art.sh`.

## Queue (the next run's order, from ROADMAP)
1. Then L-05 to L-08, and L-10 (the map) after L-05. L-05 adds "flash every light" to
   `MotionLights` and builds the lobby and elevator where `FloorBuilder`'s stand-in is; L-06's
   keepers hear doors on `Doors.acted` (each event's `reach`); L-08 lays the next floor during the
   ride.
2. **Before the ladder** (ROADMAP Phase 2): close a run's back (the 16-stud gap, no floor or deck)
   and its ends at a junction's hollow block; a wire top leaves 2.8 studs under the joists.
3. **Polish waiting** (ROADMAP): a door answering before the server's word; tool buttons per
   player; the cutters' snip; a lifted door's grace; a laid floor's draw cost on a phone; the L
   unit; the bolt and padlock moving; a shut door muffling sounds; a less-shake setting; a sound
   mix; a lit tube's hum; fading a far pool; the kit's texture copies; cheaper chain links; a red
   glow round a Seen eye; a haze edge; a client-side door collider; the padlock too small; the
   cursor hint once ever; the junctions' overlapping decks (and crossing lids) seen from the tops.
4. Studio traps (docs/STUDIO.md): a prompt triggers from the MCP only while the camera faces it;
   captures don't draw prompts or far, unstreamed areas; annotate locals and loop variables of
   another module's string unions.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
