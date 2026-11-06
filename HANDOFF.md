# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-06, session 6 · **Checks:** green · **Git:** `main`, local only (no remote; `storage-unit` became
`main` and `third-person-walls` was deleted on the owner's word).

## State
- **The game plays in first person** (P0-02c, verified in Studio): the camera locks at the head, door prompts sit on
  the door at eye height, Lift hides behind a shut door, and a slam from the doorway shuts you in or pushes you out.
- **The owner's two-player test passed** except two things, now ticket P0-02e: an arm shows through a shut door
  (`docs/art/P0-02e-arm-through-door.png`, dimmed by the pause menu, the only way to free the mouse today), and
  first person traps the mouse with no key to free it.
- **The owner approved the unit's look** and wants the game lit like the look sheets (D-012). The MCP's captures
  are accurate (the owner's dark shot was dimmed by the pause menu); in them the hall reads flat and near white
  next to the sheets: P0-02d.
- Streaming settings are confirmed in Studio. Studio's place is `storage.rbxl`; `rojo serve` was running on port
  34872 (`lsof -iTCP:34872`).

## Next task: P0-02e What the two-player test found
The moments: a friend shut in a unit is a sound behind the door, never a hand through it; and a computer player
can let go of the mouse to grab a screenshot, then drop straight back into looking.
1. Owner verdicts or test results first. Check `lsof -iTCP:34872` for a running Rojo (start `rojo serve` in the
   background if none) and ask the owner to click Connect.
2. Measure in Play: shut the player inside 101 and hold walk into the door; every RenderStepped, record how far each
   character part and accessory Handle reaches past the curtain plane (`RollUpDoor.frame`; the slats sit within
   about 0.1 of it). Repeat from the hall side. Try a bulky avatar too if one loads.
3. Thicken the door's collider: the 0.4 depth is hard-coded in `RollUpDoor.placeCollider` and in `UnitKit.prepare`.
   Make it one shared feel number with a comment, deep enough that the step 2 overshoot stays behind the slats with
   margin (from outside, about 1.2 keeps you flush with the facade). Re-run the Lune tests.
4. Move `PROMPT_OUT` and `LIFT_IN` (DevCorridor) to just outside the thicker collider: a point inside it loses its
   sight line and hides. Re-run P0-02c's probes: 101's prompts show mid-hall and pressed to the door, Lift hidden
   from the hall and shown inside, a slam from the doorway.
5. The cursor key: check Brix (`docs/FRAMEWORK.md`) for an input piece first. Verify on create.roblox.com that a
   visible GuiButton with `Modal = true` frees the mouse in first person (note it in STUDIO.md). Build a client
   controller beside `DoorView` that toggles it on Left Alt for mouse players only, with one short first-time hint
   ("Alt: cursor"). In Play: MouseBehavior flips to Default and back, the view doesn't turn while free, prompt keys
   still work.
6. OWNER.md: fill in the re-check under "After P0-02e" with the key's name and exact steps.
**Acceptance:** checks green; overshoot numbers in STUDIO.md; no character part past the slats in Play; P0-02c's
probes still pass; the cursor toggles both ways in Play; shots in `docs/art/P0-02e-*.jpg`.
**Read first:** `docs/ROADMAP.md` (P0-02e); `src/shared/StorageUnit/RollUpDoor.luau` (`placeCollider`);
`src/shared/StorageUnit/UnitKit.luau` (the DoorCollider in `prepare`); `src/server/DevCorridor.luau` (prompt
constants); `src/client/init.client.luau`; `docs/STUDIO.md` ("Camera and prompts").

## Queue (the next run's order, from ROADMAP)
1. **P0-02d The hall lit like the look sheets** (D-012): match `art/sheets/unit-hall.png` and friends in Studio
   captures, starting from the lights in `art/unit/build.py`; triangle and draw-call counts; phone shots.
2. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the motion-light fixture.
3. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch, padlock.
4. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09); L-02 carries the phone prompt
   layout (five prompts on one point stack into one tap button).
5. **Polish waiting:** sizes S and L by eye (they need FBXs and uploads first); a client-side door collider if the
   ~0.1 s lag feels wrong; the padlock is too small to spot from standing height; touch look speed may want a feel
   number.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
