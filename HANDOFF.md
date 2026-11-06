# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-06, session 6 · **Checks:** green · **Git:** `storage-unit`, local only (`main` has no commits yet).

## State
- **The game plays in first person** (P0-02c, verified in Studio, one player): `default.project.json` locks
  `StarterPlayer.CameraMode` to LockFirstPerson (D-011, which the owner confirmed again this session). From the
  eyes every key works at 101 with both refusals; Lift stays hidden behind a shut door and shows from inside; a
  slam from the doorway shuts you in or pushes you out without the slats crossing your eyes.
- **Door prompts moved onto the door at eye height** (`PROMPT_OUT`, `PROMPT_HEIGHT`, `LIFT_IN` in DevCorridor):
  in first person a prompt shows only while its point is on screen, and the old chest-height point 1.5 studs out
  vanished under your chin when you walked up to a door.
- **Phone, Galaxy A16 landscape in the Device Simulator:** the thumbstick walks and a drag looks. The five prompts
  on a door draw on top of each other as 138×72 tap buttons, so a phone can't pick one; that's written into L-02
  (offer only what the door's state allows, spaced with `UIOffset`). The simulator is back to default.
- **It reads too bright:** a shut unit's inside and the open doorway both light near white
  (`docs/art/P0-02c-inside-101.jpg`, `P0-02c-lean-in-101.jpg`). That's the next task.
- Studio's place is `storage.rbxl`; `rojo serve` was still running on port 34872 (`lsof -iTCP:34872`).

## Next task: P0-02d The hall measured and lit
The moment: you stand in a hall lit in cold pools under the tubes, and an open unit is a black mouth you have to
step into. Right now the units glow from inside and the facades read near white, so the dark never lands.
1. Owner verdicts or test results first. Check `lsof -iTCP:34872` for a running Rojo (start `rojo serve` in the
   background if none) and ask the owner to click Connect.
2. Find out why a shut unit's inside is lit: probe light by light (the tubes' SurfaceLights in DevCorridor,
   Lighting's Ambient and EnvironmentDiffuseScale, the Atmosphere) with Edit captures from inside 102.
3. Tune for after hours, every number commented with what it does to the player: the hall in pools under the
   tubes, a shut or open unit's back wall near black, never pure black on a phone. Lighting lives in
   `default.project.json`; the tubes are `TUBE_*` in `src/server/DevCorridor.luau`.
4. Measure: the hall's triangle count from `Specs.Triangles` (budget 8.6k a unit, `art/unit/README.md`) and
   draw calls with the rbx-scene-analysis or rbx-perf-profiling Studio skill. Compare against the GDD tech plan's
   phone budget (read only that section) and note the numbers in `art/unit/README.md`.
5. Phone shots: Device Simulator, Samsung Galaxy A16 in landscape (set the device, then the orientation, then
   Play; docs/STUDIO.md). Shots: the hall from spawn, facing 101, leaning into open 101, inside shut 102. Save as
   `docs/art/P0-02d-*.jpg` (captures land under the session's tool-results folder; copy them).
**Acceptance:** checks green; light numbers commented; counts recorded against the budget; four phone shots;
OWNER.md's look-judging item points at the new shots.
**Read first:** `default.project.json` (Lighting); `src/server/DevCorridor.luau` (the `TUBE_*` lights and the
function that builds them); `art/unit/README.md` (Budget); `docs/STUDIO.md` ("Camera and prompts", "Tools");
the GDD's tech plan section; `docs/DECISIONS.md` (D-007, the look).

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the motion-light fixture.
2. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch, padlock.
3. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09); L-02 now carries the phone
   prompt layout.
4. **Polish waiting:** sizes S and L by eye (they need FBXs and uploads first); a client-side door collider if the
   ~0.1 s lag feels wrong; the padlock is too small to spot from standing height; touch look speed (a 120-point
   drag turned about 120° in the simulator, unmeasured on a real phone) may want a feel number.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
