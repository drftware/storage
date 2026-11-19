# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, ENG-26c done (D-441) · **Checks:** green · **Git:** `main`, not pushed; Brix `b8f5d71`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now: S5-03j1b, j2 to j7, ENG-29, k1 to k6.
- **Studio has tonight's code** (Rojo connected; checked late Nov 18 from Edit). Recheck the
  tells in STUDIO.md's "Arrange's build camera, first try in Play" before Play.
- **The build camera** (S5-03j1a, D-439): `src/client/ArrangeCamera.luau`, `Home/BuildView`,
  `Arrange.Camera`; never yet seen in Studio.
- **Brix's nearest free spot and guide lines** (ENG-26c, D-441): `placements:nearestFree`,
  `Brix.PlacementSearch.grid`, `placements:align`; pure, j2 and j3 wire them (FRAMEWORK.md).
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`.
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j1b The build camera, seen and tuned
The moment: Arrange opens with a swoop up from your eyes into a dollhouse view, and the room turns,
slides and zooms under your fingers like The Sims' build mode, the near walls fading away.
1. `get_studio_state`; from a Client or Edit `execute_luau`, check the two tells (above). If either
   is missing, paste the files in by STUDIO.md's recipe for that section.
2. Studio Play at Galaxy A16 size (685 by 338). Open Arrange (the button near (681, 37) of the
   window). The simulator's MCP mouse is touch: no wheel or right button, so switch the device to a
   desktop for wheel, right-drag and WASD, and back for one-finger slides.
3. Check each: the opening swoop; right-drag turns; the wheel zooms; a left drag on empty floor
   slides; WASD slides; double click resets; the walls fade from the door's side, both sides and the
   back as it turns, in a Small home then a Medium; the front tab's swing and the hall dip; closing
   swoops back. Tune `Arrange.Camera`'s signs and numbers by feel; question D-439's "an XL home's
   side walls don't fade" once seen (D-440).
4. Capture to `docs/art/` at half scale (crop the window first; full-window shots cost context:
   `sips --cropOffset 360 356 -c 314 672` gave the phone view). Stop Play; never save the place.
5. OWNER.md: exact phone and gamepad steps (pinch, twist, two-finger tilt, sticks, triggers).
**Acceptance:** seen in Studio Play at A16 size, captured; walls fade from every side; numbers
tuned and noted in DECISIONS; check green. Edge follow is j2's, with the drag.
**Read first:** ROADMAP's S5-03j1b (grep `S5-03j1b`); STUDIO.md's "Arrange's build camera, first
try in Play"; `src/client/ArrangeCamera.luau` (by grep and line ranges); `Arrange.Camera` in
`src/shared/Home/Arrange.luau`; D-439 and D-440 in DECISIONS.

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
