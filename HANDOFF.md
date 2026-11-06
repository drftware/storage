# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-05, session 4 · **Checks:** green · **Git:** `storage-unit`, local only (`main` has no commits yet).

## State
- **The corridor plays** (P0-02b, verified in Studio, one player, by key): every door action and refusal at 101 and
  105, Lift from inside, bolt and padlock, plates 101 to 108, the curtain's coil, the slam's bounce, and streaming out
  and back with every door as left. Shots in `docs/art/P0-02b-*.jpg`. No code changed this session.
- **Found: the camera passes through every unit.** Roblox's camera stops only at parts that are CanCollide and under
  0.25 transparent (docs/STUDIO.md, "Camera and prompts"). A prepared unit's colliders are invisible and its meshes
  don't collide, so in the 8-stud hall the camera backs through the shut door behind you into the unit across the
  hall (`docs/art/P0-02b-camera-inside-102.jpg`), and the prompts you face hide because their line of sight starts
  at the camera. **The owner chose first person** (D-011), which keeps the camera at the head: that's P0-02c.
- Studio's place is `storage.rbxl` with the template at `ReplicatedStorage.Units.M`. A `rojo serve` from an earlier
  session was still running (port 34872, this repo); check with `lsof -iTCP:34872` before starting another.

## Next task: P0-02c First person
The moment: you lean into a dark doorway with the door hanging over your head, and it's your eyes, not a camera
behind you, that see the slam coming.
1. Owner verdicts or test results first. Check `lsof -iTCP:34872` for a running Rojo (start `rojo serve` in the
   background if none) and ask the owner to click Connect. Check Studio still has `ReplicatedStorage.Units.M`.
2. Lock first person in `default.project.json`: StarterPlayer `$properties` CameraMode `LockFirstPerson`, with a
   comment on what it does to the player (as in Pressure, D-011). Prove the enum syntax with `rojo build` first.
   Field of view stays Roblox's 70 for now; if it feels wrong, it becomes a commented feel number.
3. Play and probe: the client's camera sits at the head (within about 1 stud of the Head part); facing 101 at
   (-18, 3, -0.3) its five prompts show (track `ProximityPromptService.PromptShown`), and each key still works.
4. Lift through a shut door: stand outside shut 102 at (-18, 3, 3.5) facing it. If Lift@Unit102 shows, the
   prompt's line of sight ignores the invisible DoorCollider: move the Lift point deeper or shorten its reach
   (`LIFT_IN`, `LIFT_REACH` in DevCorridor) and note the rule in STUDIO.md.
5. Up close: stand in 101's open doorway, slam it from the server, and screenshot from the eyes; the door must push
   you out, never pass through your view. Then inside a shut unit, check the view and that Lift shows.
6. Phone: the Device Simulator on a small Android in landscape (MCP skill rbx-device-simulator-lua): look by
   dragging, walk with the thumbstick, tap a prompt. Note anything clumsy; the shots themselves are P0-02d's.
**Acceptance:** checks green; probes 3 to 6 pass in Play with screenshots in `docs/art/P0-02c-*.jpg`; STUDIO.md
updated; OWNER.md's two-player test moved to "Now" with first-person wording.
**Read first:** `default.project.json`; `src/server/DevCorridor.luau` (prompt constants and `addDoorPrompts`);
`docs/STUDIO.md` ("Camera and prompts", "Tools"); `docs/DECISIONS.md` (D-011); OWNER.md (the two-player test).

## Queue (the next run's order, from ROADMAP)
1. **P0-02d The hall measured and lit:** triangle and draw-call counts, phone-size shots, the light level (too
   bright for after hours: the facades read near white).
2. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the motion-light fixture.
3. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch, padlock.
4. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09), then the rest of the game.
5. **Polish waiting:** sizes S and L by eye (they need FBXs and uploads first); a client-side door collider if the
   ~0.1 s lag feels wrong; the padlock is too small to spot from standing height.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
