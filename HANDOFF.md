# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 12 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The owner judged P0-02h:** the before and after shots look good and Automatic looks decent.
  Three lit fixtures awake at once is fine for now; they judge it once motion lights are built
  (noted on L-03 in ROADMAP).
- **Dust hangs in the air under each lit tube** (P0-02i, done; D-018). `HallLight.light` now adds
  a ParticleEmitter on an attachment 2.5 studs under the tube: Roblox's smoke texture, about six
  slow puffs alive, 4 to 6 studs wide, partly lit by the hall (LightInfluence 0.4) so low graphics
  is only about 1.3x brighter than full quality from the spawn. A weak tube's dust is fainter, a
  dead one's vanishes at once, and a tube coming on throws a burst of five (server `Emit` reaches
  clients already watching). Its numbers are feel numbers in `HallLight` (`Haze*`).
- **Verified in Studio** (Play at Level08 and Level21, spawn and near-tube views; shut in 105 at
  Level08 stays dark with the line under the door, and the hall's lights dim to about 5%):
  `docs/art/P0-02i-haze.jpg`, `P0-02i-inside-105.jpg`.
- The ticket was split for the context budget: the cost counts and phone shots are P0-02j.
- `rojo serve` is running on port 34872; Studio is in Edit, Quality Level back on Automatic.

## Next task: P0-02j The hall's cost and phone shots
The moment: the hall, haze and all, plays smoothly on a cheap Android phone and still looks like
the look sheets at phone size.
1. Owner test results first (`OWNER.md`, "Now: judge P0-02i"). Thicker or fainter haze is
   `HallLight.HazeTransparency`; compare with a fresh burst (docs/STUDIO.md, "Particles in the
   hall").
2. Play; at Level08 and Level21, from the spawn view and under the lit tube, read the hall's
   triangle and draw-call counts (View > Stats, Render; or `Stats` from the MCP if it exposes
   them) with the haze on and off. Note them in docs/STUDIO.md.
3. Phone-size shots in the Device Simulator (the Studio MCP skill `rbx-device-simulator-lua`):
   a mid-range Android phone, landscape, at low and full quality, spawn view.
4. If the haze costs a lot on a phone, fewer puffs (`HazeRate`) before smaller ones.
5. OWNER.md: the shots to judge. Put Quality Level back to Automatic, leave Studio in Edit.
**Acceptance:** checks green; counts noted in docs/STUDIO.md; `docs/art/P0-02j-*.jpg` phone
shots at both qualities; the owner judges.
**Read first:** `docs/ROADMAP.md` (P0-02j); `docs/STUDIO.md` ("Lighting and captures" and
"Tools"); `docs/DECISIONS.md` (D-018); `src/shared/HallLight.luau` (the `Haze` numbers); the
Studio MCP skill `rbx-device-simulator-lua`.

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the
   motion-light fixture, built around `HallLight`'s numbers (the haze must still clear the
   ceiling: `HazeHeight` against the kit's ceiling height).
2. **L-03 Motion lights** (moved up by the owner, Nov 7): fixtures wake as you walk the hall,
   server-owned, set through `HallLight.light` so the fill, the haze and `BehindDoors` follow.
   A lit fixture is two lights (D-017); the owner judges the three-fixture budget once built.
3. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch,
   padlock.
4. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01, L-02, L-04 to L-09);
   L-01 must call `RollUpDoor.fitCollider` on each placed unit, as DevCorridor does; L-02 carries
   the phone prompt layout (five prompts on one point stack into one tap button).
5. **Polish waiting:** the haze starts clear for a late joiner or a fixture streamed in; a faint
   haze edge near the ceiling at low graphics; at low graphics a peeked unit lights evenly; re-run
   `UnitKit.prepare` so the template saves at 1.2 deep; sizes S and L by eye; a client-side door
   collider if the lag feels wrong; the padlock is too small to spot; the cursor hint once ever.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
