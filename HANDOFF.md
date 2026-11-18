# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, ENG-28 OrbitCamera in Brix (D-438) · **Checks:** green · **Git:** `main`, not pushed; Brix `0b2230c`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order: S5-03j1, ENG-26c, j2 to j7, ENG-29, k1 to k6.
- **ENG-28 done** (D-438): `Brix.OrbitCamera` circles a point on the floor on springs that never
  swing past, drifts after a flick, stops softly (focus in any Zone, near, far, the tilt's ends),
  keeps the eye under an optional ceiling, follows a drag to the screen's edge, and answers
  `floorAt` and `cutaway` (the walls' fade). With ENG-27's `Brix.Gestures`, pinned, unused yet.
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`. Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww.
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j1 The build camera (The Sims' camera in Arrange)
The moment: Arrange swoops up out of your eyes; one finger slides, two pinch, twist and tilt; it
glides and settles; the walls nearest you melt away. Its own client module; ArrangeView shrinks.
1. `ArrangeCamera.luau`: one `Brix.Gestures` and one `Brix.OrbitCamera` while Arrange is open.
   Feed Gestures from UserInputService (touch, mouse, wheel, gamepad; WASD as a per-frame slide),
   map intents: drag on empty floor or slide -> `slide` (+ `flick` on its end), pinch -> `zoom`,
   twist with no thing -> `turn`, tilt -> `tilt`, double tap on empty floor -> `reset`. `pick` asks
   what's under a point (empty floor = nil for now; j2 adds things). Step on RenderStepped, write
   `CFrame.lookAt(eye, look, up)`; on close disconnect all and `gestures:cancel()`.
2. The room: `Zone.box` turned to the room's face with a floor pathing; focus in the room's middle
   about 3 studs up; a home view like today's corner view (`view` in ArrangeView ~line 1291). Decide
   the `ceiling` (hide the ceiling while open, or keep the eye under it) and say which in DECISIONS.
3. Walls (and what hangs on them) fade by `cutaway`, tweened, never snapping.
4. Opening swoops from your eyes to the orbit's view over `Feel.Rise`; closing swoops back. The
   front tab's door view and hall dip still work. The old camera code leaves ArrangeView.
5. Feel numbers in Config, commented; mouse and stick signs tuned by feel.
6. Studio Play at 685 by 338: slide, pinch (two fingers can't be faked: use mouse wheel and right-
   drag), reset; capture to `docs/art/` at half scale. Phone-only steps go in OWNER.md.
**Acceptance:** seen in Studio Play at A16 size, captured; walls fade from every side; check green.
**Read first:** ROADMAP's S5-03j1 (grep `S5-03j1`); the doc's camera list (block
`mmpnpe7tg17.2368`); `vendor/brix/docs/modules/OrbitCamera.md`; `vendor/brix/docs/modules/Gestures.md`;
`src/client/ArrangeView.luau` lines 1285 to 1480 (the camera today); `src/shared/Home/Arrange.luau`'s
Feel (grep `Rise`).

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
