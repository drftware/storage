# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 26 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-04b is done** (D-034): every unit hangs a caged bulb on a short cord under its wire top
  (`Bulb`, a corridor kit piece, 518 triangles; `CorridorKit.hangBulb`, hung by
  `FloorBuilder.unit`). Wired to the door like a fridge's light (`ShutIn.bulb`): it clicks and
  stutters on as the door starts up, is out the frame the door lands. `UnitLights` (client) draws
  it from the door's replicated motion; the 3 nearest lit bulbs throw light and hum. Numbers in
  `src/shared/UnitLight.luau` (0.6 strong, 11 reach, warm amber; the guard casts no shadow).
- **Verified in Studio** (Galaxy A16 view, Play, Level01 and 21): 92 of 92 units hung; 101 open
  with the L-04a boxes reads dim and warm, back corners dark (`docs/art/L-04b-open.jpg`); a peek
  lets a warm band out under the door (`L-04b-peek.jpg`); a slam goes dark on landing and stays
  dark through the bounce; with five open only the three nearest threw light; shut in 103 at
  Level01, 101's lit bulb was dimmed to 0.036 on that screen. Not heard (no one here can listen).
- The `Bulb` template is in the place at `ReplicatedStorage.Corridor.Bulb`, unsaved until the
  owner saves (`OWNER.md`). Studio is back in Edit, Device Simulator off, Quality Automatic.
- `rojo serve` runs on port 34872.

## Next task: L-04c The first finds
The moment: the door goes up, the bulb stutters on, and there's something in there worth taking.
1. Owner test results first (`OWNER.md`), and any answer on the bulb or the guard's shadows.
2. Read the GDD's "What's behind the door" and its finds (the 1980s bedroom set, dust and mimics,
   rarity's look) only. If more than a session, split L-04c in ROADMAP first.
3. Art, built the boxes' way (`art/boxes/` is the model): a handful of the bedroom set's finds,
   each one MeshPart on one shared atlas, dusty, light in triangles; FBX, Specs, look sheets;
   upload with `scripts/upload_art.luau` and import.
4. A `Finds` module beside `Boxes` (`prepare`, `clone`), templates at `ReplicatedStorage.Props`.
5. Judge on the Galaxy A16 view at Level01 and 21: finds set among 101's boxes, seen from the
   doorway under its bulb; each readable for what it is at phone size.
**Acceptance:** checks green; finds readable from the doorway under the bulb, judged in Studio at
phone size; `OWNER.md` says what to judge and the templates to save.
**Read first:** `docs/ROADMAP.md` (L-04c); the GDD's finds section; `art/boxes/README.md`;
`art/boxes/spec.py`; `src/shared/Boxes/init.luau`; `docs/DECISIONS.md` (D-032).

## Queue (the next run's order, from ROADMAP)
1. L-04d the director, then L-05 to L-08, and L-10 (the map) after L-05. L-05 adds "flash every
   light" to `MotionLights` and builds the lobby and elevator where `FloorBuilder`'s stand-in is;
   L-06's keepers hear doors on `Doors.acted` (each event's `reach`); L-08 lays the next floor
   during the ride.
2. **Before the ladder** (ROADMAP Phase 2): close a run's back (the 16-stud gap, no floor or deck)
   and its ends at a junction's hollow block; a wire top leaves 2.8 studs under the joists.
3. **Polish waiting** (ROADMAP): a unit's bulb swinging after a slam; the guard's bars as a soft
   stripe; the boxes' second look and the wardrobe's bar; a door answering before the server's
   word; tool buttons per player; the cutters' snip; a lifted door's grace; a laid floor's draw
   cost on a phone; the L unit; the bolt and padlock moving; a shut door muffling sounds; a
   less-shake setting; a sound mix; a lit tube's hum; fading a far pool; the kit's texture
   copies; cheaper chain links; a red glow round a Seen eye; a haze edge; a client-side door
   collider; the padlock too small; the cursor hint once ever; the junctions' overlapping decks.
4. Studio traps (docs/STUDIO.md): a prompt triggers from the MCP only while the camera faces it;
   captures don't draw prompts or far, unstreamed areas; standing still lets the hall go dark
   in 7.5 s; CollisionFidelity won't set from the MCP; set the Device Simulator's device before
   its orientation; a capture's camera across the hall can land inside the opposite unit.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
