# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 13 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The hall is cheap to draw** (P0-02j, done): about 61,000 triangles and 25 draw calls from the
  spawn, the units almost all of it; the haze adds 24 triangles and 3 draw calls at both
  qualities, so its puffs stay. Full numbers in docs/STUDIO.md, "The hall's render cost".
- **Found and fixed: the haze was nearly gone on low graphics.** Roblox thins an emitter's steady
  puffs to about (graphics level ÷ 21) of its Rate, so a cheap phone held under one puff per tube.
  The P0-02i shots hid it (fresh bursts aren't thinned). Now the server leaves each haze emitter's
  Rate at 0 and tags it `HallLight.HazeTag`; the new client system `HallHaze` emits each lit
  tube's puffs on a steady beat (`Pace`, a small pure module with a Lune spec), and bursts a
  tube already lit when the player first gets it, so a late joiner's air isn't clear (D-019).
- **Verified in Studio:** about 11 puffs under the two lit tubes at Level01, Level08 and Level21
  alike (Play, counted from `Stats.RenderBreakdown`); phone shots on a simulated Galaxy A16,
  `docs/art/P0-02j-phone.jpg`.
- Owner's judging is in `OWNER.md`, "Now: judge the haze" (P0-02i's and P0-02j's shots together).
- `rojo serve` is running on port 34872; Studio is in Edit, Quality Level on Automatic, the
  Device Simulator off.

## Next task: P0-03 The corridor kit
The moment: the hall stops being a test strip and becomes the building: a real floor and
ceiling, corners you can't see round, a dead end you back out of, and the fixture that will
watch you (L-03 lights it).
1. Owner test results first (`OWNER.md`). Thicker or fainter haze is `HallLight.HazeTransparency`.
2. Read the GDD's tile set and Lights sections (the docs tools, not WebFetch). The ticket is big:
   split it in ROADMAP before building (for example the straight piece with floor and ceiling,
   then corner, T, cross and dead end, then the motion-light fixture), and do only the first.
3. Build it the unit's way (art/unit/README.md): a Blender 5.2 script with one spec for the
   numbers, shared texture sets, baked PBR maps, an FBX, a generated `Specs` module, look sheets.
4. The ceiling height must keep the haze clear of it: `HallLight.HazeHeight` (9.6) with puffs up
   to 3 studs above it, against today's ceiling at 13.4. The tube hangs at `HallLight.Height`.
5. Place it in `DevCorridor` and judge it at phone size at Level01 and Level21 (the Device
   Simulator steps in docs/STUDIO.md, "Tools").
**Acceptance:** checks green; the piece imported and placed; phone-size shots in
`docs/art/P0-03*-*.jpg`; the owner judges.
**Read first:** `docs/ROADMAP.md` (P0-03, L-03); the GDD's tile set and Lights sections;
`art/unit/README.md`; `src/shared/HallLight.luau` (the top numbers); `src/server/DevCorridor.luau`;
`docs/STUDIO.md` ("Getting assets into Roblox").

## Queue (the next run's order, from ROADMAP)
1. **L-03 Motion lights** (moved up by the owner, Nov 7): fixtures wake as you walk the hall,
   server-owned, set through `HallLight.light` so the fill, the haze and `BehindDoors` follow.
   A lit fixture is two lights (D-017); the owner judges the three-fixture budget once built.
   A fixture relit in front of a player gets the server's burst; one streamed in already lit
   gets `HallHaze`'s.
2. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch,
   padlock.
3. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01, L-02, L-04 to L-09);
   L-01 must call `RollUpDoor.fitCollider` on each placed unit, as DevCorridor does; L-02 carries
   the phone prompt layout (five prompts on one point stack into one tap button).
4. **Polish waiting:** a faint haze edge near the ceiling at low graphics; at low graphics a
   peeked unit lights evenly; re-run `UnitKit.prepare` so the template saves at 1.2 deep; sizes S
   and L by eye; a client-side door collider if the lag feels wrong; the padlock is too small to
   spot; the cursor hint once ever.
5. **Check other particles the same way:** any emitter added later (keepers, dust from a door)
   is thinned on low graphics too; judge it in its steady state (docs/STUDIO.md).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
