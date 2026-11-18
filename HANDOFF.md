# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j1a the build camera, built (D-439) · **Checks:** green · **Git:** `main`, not pushed; Brix `0b2230c`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order: S5-03j1b, ENG-26c, j2 to j7, ENG-29, k1 to k6.
- **S5-03j1a done** (D-439), passes checks, untested in Studio: `src/client/ArrangeCamera.luau`
  (Brix Gestures into Brix OrbitCamera; swoop in and out; front tab's swing and dip; the eye kept
  in the lobby slot and 5 studs into the hall; the home's walls fade), pure sums in
  `src/shared/Home/BuildView.luau` (Lune spec), feel in `Arrange.Camera`. ArrangeView only wires it
  (`buildCam.open/show/close/destroy`, `takenAt`); its old camera code is gone.
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`. Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww.
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j1b The build camera, seen and tuned
The moment: Arrange swoops up out of your eyes; drag, wheel and right-drag move it; it glides and
settles; the walls nearest you melt away as it turns. Nothing new to build: see it, fix, tune.
1. Studio Play, A16 (STUDIO.md "Picking the A16 from the shell"), Unit1 (Medium). Open Arrange
   (the button failed from the MCP before, STUDIO.md ~line 3201: try `caffeinate -d -u -t 600 &`
   and Studio brought forward, else the job box's Set out, which calls ArrangeView's `hold`).
2. Check the swoop, then the wheel (sign: up zooms in), right-drag (drag right should look
   right), a left drag on empty floor (the floor stays under the cursor), WASD, a double click
   (glides home). Fix signs in `Arrange.Camera`; tune `Settle`, `Drift`, `FarPast` by feel.
3. Turn all the way round: the door's wall, both sides and the back fade and return, never pop;
   furniture and the lamp never fade; the eye never shows a neighbour's unit or the lobby's
   insides. `ArrangeTest` "size" to Small and back to check a smaller room.
4. The front tab (swing to the door and back) and a card chip's hall dip; Done swoops back into
   your eyes and your camera is yours again.
5. Capture the home view and a turned, faded view to `docs/art/` at half scale.
6. OWNER.md: phone steps (one finger slides, pinch, twist, two-finger tilt, flick, double tap),
   a gamepad step (left stick slides, the body doesn't walk; right stick; triggers), and the
   default picked in D-439 (the eye under the ceiling, inside the slot; XL's walls don't fade).
**Acceptance:** seen in Studio Play at A16 size, captured; walls fade from every side; check green.
**Read first:** ROADMAP's S5-03j1b (grep `S5-03j1b`); D-439 in `docs/DECISIONS.md`;
`src/client/ArrangeCamera.luau`; `Arrange.Camera` in `src/shared/Home/Arrange.luau` (grep
`Arrange.Camera =`); STUDIO.md's "The Arrange screen on the Galaxy A16" section.

## Queue (next sessions, the owner's ticket order)
0. After S5-03j and k: the home's three "Polish:" lines under S5-03g2b (the hand-over's shade,
   D-326, D-327; the mirror keeping the old look; the floor's wipe under the tray, D-328), then
   g3b's plate swapping in plays (ROADMAP's "Polish (g3b)").
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting's leftovers
   (D-353): cross-legged on the blanket needs our own animation; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; Arrange shows the job box's "Open" and the door's buttons; a lifted lit
   piece's light; a grow while Arrange is open closes it (D-356); Robux unit and gift cards
   unseen; the XL limit bar; Take through a wall; a refused cubby place (D-352). A taken-out
   find comes out whole even when the save has it cracked. Several of these may fall out of
   S5-03j's rebuild: check each against it before building.
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 361.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
