# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-06, session 7 (owner's test added) · **Checks:** green · **Git:** `main`, local only (no remote).

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
  rule gives hidden/hidden/drawn for a friend inside, deep inside and in the hall.
- **The owner's two-player test passed** (Nov 6): nothing shows through the door and stopping a
  stud back doesn't feel like an invisible wall. One miss: the hidden player's name tag still
  floats over the door (`docs/art/P0-02e-name-tag-through-door.png`). It and the cursor key are
  P0-02f.
- Studio's place is `storage.rbxl`; `rojo serve` was running on port 34872 (`lsof -iTCP:34872`).

## Next task: P0-02f The hidden friend's name tag, and the cursor key
The moments: a friend shut in a unit is a sound behind the door, never a name hanging in the air;
and a computer player lets go of the mouse to grab a screenshot, then drops straight back in.
1. Owner verdicts or test results first. Check `lsof -iTCP:34872` for Rojo (start `rojo serve` in
   the background if none); ask for Connect.
2. Name tag: on create.roblox.com, check that a client's write to another player's
   `Humanoid.DisplayDistanceType` changes only its own view, and what `NameOcclusion` does. In
   `BehindDoors.hide`, hide the Humanoid's name (keep the old value), and restore it exactly in
   `show` and `stop`. Note the finding in docs/STUDIO.md ("Hiding a character...").
3. Cursor: verify on create.roblox.com that a visible GuiButton with `Modal = true` frees the mouse
   under `LockFirstPerson`; note it in docs/STUDIO.md ("Camera and prompts").
4. Build a client system beside `DoorView` and `BehindDoors` (Brix has no input piece) that
   toggles a free cursor on Left Alt for mouse players only (`UserInputService.MouseEnabled`, not
   touch or gamepad), plus one short first-time hint ("Alt: cursor") that fades. Feel numbers
   (hint time, fade) as commented constants.
5. In Play: `MouseBehavior` flips to Default and back; the view doesn't turn while free; prompt
   keys (E, F, Q, R) still work; Alt again returns to look.
6. OWNER.md: fill in "After P0-02f" with the key and exact steps.
**Acceptance:** checks green; the name stays hidden in code paths for hide, show and stop (the
owner checks it with two players); the cursor toggles both ways in Play; the hint shows once;
nothing on touch; a shot in `docs/art/P0-02f-*.jpg`.
**Read first:** `docs/ROADMAP.md` (P0-02f); `src/client/BehindDoors.luau`;
`src/client/init.client.luau`; `docs/STUDIO.md` ("Camera and prompts").

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
