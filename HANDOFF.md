# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-06, session 8 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The hidden friend's name tag and the cursor key** (P0-02f, done; D-014). When `BehindDoors`
  hides a friend behind a shut door, this client's copy of their Humanoid's `DisplayDistanceType`
  goes to None, and the old value comes back on show and on stop. A new client system,
  `FreeCursor`, frees the mouse on Left Alt for mouse players (a visible `Modal` button) and shows
  an "Alt Cursor" hint once a session (`docs/art/P0-02f-cursor-hint.jpg`).
- **Verified in Studio** (solo Play): a client's `DisplayDistanceType` write stays on the client
  (the server still read Viewer); Alt toggles the button both ways; with the cursor free, E, F, Q
  and R opened, closed, peeked and locked 102; the hint fades in, holds, fades out and is gone.
- **Not seen here:** the mouse actually going free and the view holding still (Studio doesn't
  lock the mouse while its window is out of focus; docs/STUDIO.md, "Freeing the mouse"), and the
  name tag with two players. Both wait on `OWNER.md`.
- Studio's place is `storage.rbxl`; `rojo serve` was running on port 34872 (`lsof -iTCP:34872`).

## Next task: P0-02d The hall lit like the look sheets
The moment: you step into the hall and it already looks like the posters. Doors catch the tube
light with real depth and the dark between tubes swallows the far end, instead of the flat, near
white facades and unit insides Studio shows today (D-012).
1. Owner test results first (`OWNER.md`, "Now: test P0-02f"). Check `lsof -iTCP:34872` for Rojo
   (start `rojo serve` in the background if none); ask for Connect.
2. Look at `art/sheets/unit-hall.png`, `unit-hero.png` and `unit-inside.png`. Read how they're lit:
   the hall's area lights and the exit glow in `art/unit/render.py` (around line 190), the shot
   lights in `art/unit/build.py` (around lines 219 and 308).
3. In Play, capture Studio's view from the sheets' camera spots with today's Lighting and the
   tubes in `src/server/DevCorridor.luau`. Write down what differs: brightness, falloff between
   tubes, colour, contrast on the facades, the inside of an open unit.
4. Tune Lighting (`default.project.json`) and the tube lights (`DevCorridor`) until the captures
   match. Every number gets a comment on what it does to the player. Stay inside the GDD's cap on
   real light instances for low-end Android.
5. Count the hall's triangles and draw calls and note them in docs/STUDIO.md. Take phone-size
   shots in the Device Simulator.
6. OWNER.md: the side-by-side shots to judge, and what to look for.
**Acceptance:** checks green; side-by-side shots, sheet next to capture, in `docs/art/P0-02d-*.jpg`
for the hall, hero and inside views; light count within the cap; phone shots; the owner judges the
match.
**Read first:** `docs/ROADMAP.md` (P0-02d); `docs/DECISIONS.md` (D-012, D-007);
`art/unit/render.py` (hall lights); `src/server/DevCorridor.luau` (tubes); `default.project.json`
(Lighting); `docs/STUDIO.md` (capture notes at the end of "Camera and prompts").

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the
   motion-light fixture.
2. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch,
   padlock.
3. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09); L-01 must call
   `RollUpDoor.fitCollider` on each placed unit, as DevCorridor does; L-02 carries the phone
   prompt layout (five prompts on one point stack into one tap button).
4. **Polish waiting:** re-run `UnitKit.prepare` on the template so it saves at 1.2 deep (harmless
   until then); sizes S and L by eye; a client-side door collider if the ~0.1 s lag feels wrong;
   the padlock is too small to spot from standing height; touch look speed may want a feel
   number; the cursor hint once ever (needs the saved profile) and "Option" on a Mac.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
