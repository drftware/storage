# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-06, session 10 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **A shut unit is dark on every phone** (P0-02g, done; D-016). Below graphics quality about 10
  the hall's lights cast no shadows at all (thick walls change nothing), so `BehindDoors` now
  scales every light tagged `HallLight.Tag` by `ShutIn.light` for whoever is shut in: 6% shut,
  about half at a friend's peek, full when open, cut as fast as a slam falls. The line under the
  door is a thin neon strip on the hall floor (`HallLight.UnderDoorColour`), faded out as the door
  lifts and drawn only where a lit tube reaches the door.
- **Verified in Studio** (Play, Level08 and Level21, camera pinned inside 105, a server Peek):
  `docs/art/P0-02g-inside.jpg` and `-peek.jpg`. `tests/shutin.spec.luau` covers `ShutIn.light`.
- The owner approved P0-02d's look ("Looks good"), so its OWNER.md items and the 6-light budget
  default are taken as accepted. Lighting still has no `Grade` in Studio: Rojo needs a reconnect.
- **Not done:** the low-graphics hall still looks flat (`docs/art/P0-02g-hall.jpg`), the haze,
  counts and phone shots: all moved to P0-02h. The owner saw the light "change oddly": that's
  Automatic quality switching levels mid-Play (`docs/art/P0-02g-open-101.jpg`); they prefer the
  low-graphics open unit, dimly readable inside, to full quality's black one.
- `rojo serve` was running on port 34872 (`lsof -iTCP:34872`); Studio's Quality Level is back on
  Automatic.

## Next task: P0-02h The hall on every phone
The moment: on a cheap phone the hall still feels like the posters, with pools of cold light,
dark between, and a grey haze glowing under each lit fixture.
1. Owner test results first (`OWNER.md`, "Now: judge P0-02g"). Check Rojo; confirm Lighting has
   `Grade`.
2. Low graphics, in Play with `settings().Rendering.QualityLevel` at Level08 from the MCP (Client),
   from the spawn camera in docs/STUDIO.md ("Lighting and captures"; the long view is (-28, 4.6,
   1.5) looking at (30, 4.4, -0.5), FOV 55). Geometry and range don't steer it (STUDIO.md, "Low
   graphics ignores geometry"); try the lights only: brightness, a second dim fill instead of one
   strong tube, the tube's colour. Goal: the two levels close enough that Automatic switching
   between them is barely seen, with an open unit dimly readable inside at both (the owner's
   pick). Check the shut-in dark still holds.
3. The sheets' haze near a fixture: try a soft glow part, slow dust particles (Roblox's built-in
   smoke texture, few particles, no per-frame code), or bloom. Judge it at both levels and keep its
   cost small: low-end Android pays for big see-through particles.
4. Count the hall's triangles and draw calls (View > Stats, Render) at both levels; note them in
   docs/STUDIO.md. Phone-size shots in the Device Simulator at low and high quality.
5. OWNER.md: the shots to judge. Put Quality Level back to Automatic.
**Acceptance:** checks green; `docs/art/P0-02h-*.jpg` at low and high quality; counts noted; the
owner judges.
**Read first:** `docs/ROADMAP.md` (P0-02h); `docs/DECISIONS.md` (D-015, D-016);
`docs/STUDIO.md` ("Lighting and captures"); `src/shared/HallLight.luau`;
`src/server/DevCorridor.luau` (`fixture`, `building`, `HALL_FIXTURES`).

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the
   motion-light fixture, built around `HallLight`'s numbers.
2. **L-03 Motion lights** (moved up by the owner, Nov 7): fixtures wake as you walk the hall,
   server-owned, set through `HallLight` so `BehindDoors` can still dim them for a player shut in.
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
