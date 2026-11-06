# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-06, session 7 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **A shut door hides whoever is behind it** (P0-02e, done; D-013). The run animation keeps swinging
  a hand through the door while you push into it (1.25 studs through the old collider, 0.8 through
  the new one; docs/STUDIO.md, "Arms through a shut door"). So the collider is now 1.2 deep
  (`RollUpDoor.ColliderDepth`; `fitCollider` applies it at placement because the saved template
  still says 0.4), and each client's new `BehindDoors` system stops drawing anyone a shut door
  stands between it and. The rule is the pure `ShutIn` module, with Lune tests.
- **Verified in Studio** (solo Play): collider 1.2 deep; prompt points 0.7 either side of the
  curtain; 101's five prompts show mid-hall and pressed to the door, Lift hidden from the hall and
  shown inside; a slam from the doorway pushes you out or shuts you in, never stuck; the hiding
  rule gives hidden/hidden/drawn for a friend inside, deep inside and in the hall. **Untested:**
  actually hiding a second player (needs two clients): waits on `OWNER.md`. No new screenshots:
  solo Play can't show it.
- The cursor key half of the old ticket is now P0-02f.
- Studio's place is `storage.rbxl`; `rojo serve` was running on port 34872 (`lsof -iTCP:34872`).

## Next task: P0-02f The cursor key
The moment: a computer player lets go of the mouse to grab a screenshot or answer a message, then
drops straight back into looking around.
1. Owner verdicts or test results first (OWNER.md's two-player check of BehindDoors). Check
   `lsof -iTCP:34872` for Rojo (start `rojo serve` in the background if none); ask for Connect.
2. Verify on create.roblox.com that a visible GuiButton with `Modal = true` frees the mouse under
   `LockFirstPerson`; note what you learn in docs/STUDIO.md ("Camera and prompts").
3. Build a client system beside `DoorView` and `BehindDoors` (Brix has no input piece) that
   toggles a free cursor on Left Alt for mouse players only (`UserInputService.MouseEnabled`, not
   on touch or gamepad), plus one short first-time hint ("Alt: cursor") that fades. Feel numbers
   (hint time, fade) as commented constants.
4. In Play: `UserInputService.MouseBehavior` flips to Default and back; the view doesn't turn while
   the cursor is free; prompt keys (E, F, Q, R) still work; Alt again returns to look.
5. OWNER.md: fill in "After P0-02f" with the key and exact steps.
**Acceptance:** checks green; the toggle works both ways in Play; the hint shows once; nothing on
touch; a shot in `docs/art/P0-02f-*.jpg`.
**Read first:** `docs/ROADMAP.md` (P0-02f); `src/client/init.client.luau`; `src/client/DoorView.luau`
(the system shape); `docs/STUDIO.md` ("Camera and prompts").

## Queue (the next run's order, from ROADMAP)
1. **P0-02d The hall lit like the look sheets** (D-012): match `art/sheets/unit-hall.png` and
   friends in Studio captures, starting from the lights in `art/unit/build.py`; triangle and
   draw-call counts; phone shots.
2. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the
   motion-light fixture.
3. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch,
   padlock.
4. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09); L-01 must call
   `RollUpDoor.fitCollider` on each placed unit, as DevCorridor does; L-02 carries the phone
   prompt layout (five prompts on one point stack into one tap button).
5. **Polish waiting:** re-run `UnitKit.prepare` on the template so it saves at 1.2 deep (harmless
   until then); sizes S and L by eye; a client-side door collider if the ~0.1 s lag feels wrong;
   the padlock is too small to spot from standing height; touch look speed may want a feel number.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
