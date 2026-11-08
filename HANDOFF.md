# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 28 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-04c2 is done** (D-036): the bedroom set's four finds (boombox, TV, teddy, roller skates)
  are uploaded (Bedroom, asset 71042192514864), prepared into `ReplicatedStorage.Props.Finds`
  (anchored, Box for the boombox and TV, Hull for the teddy and skates, all four maps each), and
  judged in Play from 101's doorway on the Galaxy A16 view at Level01 and 21:
  `docs/art/L-04c-finds.jpg`. All four read for what they are.
- **Finds read only behind the unit's bulb:** between the bulb (the unit's middle) and the door
  they show the doorway their unlit side. The director must deal them deeper, facing the door.
- **The skates were re-posed** (`art/finds/spec.py` `pair`): the fallen one now lies in front,
  wheels to the door. The pair is placed after the bake, so the atlas is unchanged.
- **The place is unsaved:** the finds' templates live only in the open place until the owner
  saves it (`OWNER.md`, first item). Studio is in Edit, Device Simulator off; `rojo serve` runs
  on port 34872.

## Next task: L-04d The deal
The moment: every door is a gamble: the next one could be the TV you came for, nothing, or
something that's been waiting. This ticket is the rules alone, pure and Lune-tested; L-04e lays
them on the floor.
1. Owner test results first (`OWNER.md`): any swap among the finds, the set's other pieces.
2. Read the GDD's "What's behind the door" (and what it says on padlocked units and keepers'
   odds). Gaps get a default and an `OWNER.md` line; name each rule's hit-game precedent.
3. A pure module (in `src/shared/`) that, from a floor's seed and its laid units (`Floor`), deals
   each unit: a find (which), a tool, nothing, or a keeper; padlocked doors (the best finds, the
   worst odds); and where its boxes and find stand for its size, in the door's frame: the find
   deeper than the bulb, facing the door within a small turn (D-036), the boxes behind and beside.
4. Lune specs: the same seed deals the same; the shares land in their ranges over many seeds;
   padlocked units hold better finds; nothing overlaps or leaves the unit; every find is behind
   the bulb. A `scripts/` printout of one floor's deal for the owner to read, like `floor-map`.
**Acceptance:** checks green; the deal is pure, seeded and tested; the owner can read one floor's
deal in a terminal; `OWNER.md` lists the defaults chosen for the GDD's gaps.
**Read first:** the GDD's "What's behind the door" (docs tools, that section only);
`docs/ROADMAP.md` (L-04d, L-04e); `src/shared/Floor.luau`; `src/shared/Finds/init.luau`;
`src/shared/Boxes/init.luau`; `docs/DECISIONS.md` (D-036).

## Queue (the next run's order, from ROADMAP)
1. L-04e the deal on the floor, then L-05 to L-08, and L-10 (the map) after L-05. L-05 adds
   "flash every light" to `MotionLights` and builds the lobby and elevator where `FloorBuilder`'s
   stand-in is; L-06's keepers hear doors on `Doors.acted`; L-08 lays the next floor during the
   ride.
2. **Before the ladder** (ROADMAP Phase 2): close a run's back (the 16-stud gap, no floor or deck)
   and its ends at a junction's hollow block; a wire top leaves 2.8 studs under the joists.
3. **Polish waiting** (ROADMAP): the finds' printed words; the bedroom set's other pieces; a
   mimic's clean finds; the teddy's fuzz and the atlas's room; a unit's bulb swinging after a
   slam; the guard's bars as a soft stripe; the boxes' second look and the wardrobe's bar; a door
   answering before the server's word; tool buttons per player; the cutters' snip; a lifted
   door's grace; a laid floor's draw cost on a phone; the L unit; the bolt and padlock moving; a
   shut door muffling sounds; a less-shake setting; a sound mix; a lit tube's hum; fading a far
   pool; the kit's texture copies; cheaper chain links; a red glow round a Seen eye; a haze edge;
   a client-side door collider; the padlock too small; the cursor hint once ever; the junctions'
   overlapping decks.
4. Studio traps (docs/STUDIO.md): a prompt triggers from the MCP only while the camera faces it;
   captures don't draw prompts or far, unstreamed areas; standing still lets the hall go dark
   in 7.5 s; CollisionFidelity reads back Default in the call that sets it (it took; check in the
   next); set the Device Simulator's device before its orientation; a capture's camera across the
   hall can land inside the opposite unit; a find in front of a unit's bulb reads dark.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
