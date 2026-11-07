# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 11 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The hall looks nearly the same at both qualities** (P0-02h, done; D-017). Measured, low
  graphics lit upright walls 2 to 3 times brighter than full quality while floors matched. Each
  fixture is now the tube (shadowed, 14-stud reach, brightness 1.2) for the pool on the floor,
  plus a shadowless fill 5 studs up (`HallLight.FillHeight`, 0.9, 20 studs) that lights the walls
  and an open unit's inside at both. Low graphics is now about 1.7x full quality (was 1.9x in the
  hall, 2.35x in open 101, which was black at full quality).
- **Verified in Studio** (Play at Level08 and Level21, pinned spawn and 101 views; shut in 105 at
  Level08 stays black with the line under the door): `docs/art/P0-02h-*.jpg`. Brightness per
  region: `python3 -I scripts/brightness.py a.jpg b.jpg`.
- Lighting had no `Grade` (Rojo misses project-file changes over a running serve), so it was
  added by hand in Studio to match `default.project.json`; code syncs fine.
- A lit fixture is now two real lights: the 6-light budget holds three (OWNER.md asks).
- `rojo serve` is running on port 34872; Studio's Quality Level is back on Automatic.

## Next task: P0-02i The hall's haze, cost and phone shots
The moment: under each lit fixture the air itself glows grey, as in the look sheets, so a lit
stretch of hall reads as a place you could be seen in, on a cheap phone as much as a good one.
1. Owner test results first (`OWNER.md`, "Now: judge P0-02h"). If they want the two looks
   closer still, shift light from the tube to the fill before the haze.
2. Haze near a fixture, at Level08 and Level21 from the spawn view (docs/STUDIO.md, "Lighting and
   captures"): try a few slow, large dust particles around each lit tube (Roblox's built-in smoke
   texture, LightInfluence 1 so they dim with the light, go dark with a dead fixture and with
   `BehindDoors`), else a soft glow part, else bloom. No per-frame code; few particles. Build it
   in `HallLight.light` so the corridor kit and motion lights get it.
3. Check the shut-in dark still holds (camera in 105, character inside, Level08).
4. Count the hall's triangles and draw calls (View > Stats, Render) at both levels; note them in
   docs/STUDIO.md. Phone-size shots in the Device Simulator at low and full quality (the Studio
   MCP skill `rbx-device-simulator-lua`).
5. OWNER.md: the shots to judge. Put Quality Level back to Automatic.
**Acceptance:** checks green; `docs/art/P0-02i-*.jpg` at both levels with the haze; counts noted;
the owner judges.
**Read first:** `docs/ROADMAP.md` (P0-02i); `docs/DECISIONS.md` (D-017); `docs/STUDIO.md`
("Lighting and captures"); `src/shared/HallLight.luau`; `src/server/DevCorridor.luau`
(`fixture`, `HALL_FIXTURES`).

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the
   motion-light fixture, built around `HallLight`'s numbers.
2. **L-03 Motion lights** (moved up by the owner, Nov 7): fixtures wake as you walk the hall,
   server-owned, set through `HallLight` so `BehindDoors` can still dim them for a player shut in.
   A lit fixture is two lights now (D-017).
3. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch,
   padlock.
4. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01, L-02, L-04 to L-09);
   L-01 must call `RollUpDoor.fitCollider` on each placed unit, as DevCorridor does; L-02 carries
   the phone prompt layout (five prompts on one point stack into one tap button).
5. **Polish waiting:** at low graphics a peeked unit lights evenly, not from the floor up; re-run
   `UnitKit.prepare` on the template so it saves at 1.2 deep; sizes S and L by eye; a client-side
   door collider if the ~0.1 s lag feels wrong; the padlock is too small to spot from standing
   height; touch look speed may want a feel number; the cursor hint once ever (needs the saved
   profile) and "Option" on a Mac.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
