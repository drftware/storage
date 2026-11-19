# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j2a2 done: the hand seen in Studio (D-449) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; its feedback table is under "Every action answers"). Order now: S5-03j2b, j3 to j7,
  ENG-29, k1 to k6.
- **The hand is seen in Studio Play** (S5-03j2a2, D-449; `docs/art/s5-03j2a-*.png`): drag lands,
  blocked hops free, a card over the tray floats back, tap-Turn-tap lands turned.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits. Hooks:
  `ArrangeTest` ("size", "place", ...), `CameraTest` (client), `GrowTest` "cash".
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j2b Select, turn, riders
The moment: tap the lamp, it lifts a hair with round buttons round it; Turn clicks it a quarter
round; a second finger twists the table you drag; what stands on it rides and bounces.
1. Read ROADMAP's S5-03j2b and the doc's matching lines (search "Another" and "Free").
2. Pure first: the round buttons' layout round a thing's screen box (kept on screen, clear of the
   thumb) as a small pure module with Lune specs; the free turn's sum (twist angle plus quarter
   turns) in `src/shared/Home`, specs first.
3. A tap selects (lifts a hair): round icon buttons Turn, Put away, Another (one more of the same
   from your box, The Sims' eyedropper; hidden when the box has none); a tap on the room clears.
   The old verbs bar leaves ArrangeView (`showVerbs`; hidden while carried already, D-449).
4. Turn: a quarter turn with a ratchet click and a little overshoot. While dragging, a second
   finger's twist turns freely (`intent`'s "twist" with a target reaches `ArrangeHand.intent`);
   R or the wheel while held. Alt, or a Free switch in a corner, places off the grid at any
   angle: check Arranging and the judge take any angle first; widen them with a spec if not.
5. Riders (D-338) move with the piece and settle with a little bounce as it lands.
6. Studio Play at A16, Medium home: tap, Turn, Another (a twist goes in OWNER.md's phone steps).
   Capture to `docs/art/s5-03j2b-*.png`. A drag through the MCP must be one call (STUDIO.md).
**Acceptance:** seen in Studio at A16 size and captured; specs for the pure parts; check green.
Won't fit? Split it in ROADMAP first (j2b1 pure + select, j2b2 twist, Free, riders).
**Read first:** ROADMAP's S5-03j2b (grep it); D-448 and D-449 in DECISIONS; `ArrangeHand.luau`'s
`intent` and `turnNow` (grep); ArrangeView's `showVerbs` and its verbs bar (grep `verbs`);
STUDIO.md's "A drag must be one `user_mouse_input` call".

## Queue (next sessions, the owner's ticket order)
0. After S5-03j2: at the view Arrange opens with, a crate is about 16 points across on a Medium
   home (D-449): the camera's fit may want to open closer; the wheel zooms the eye through the
   unit's facade (`Colliders.FacadeRight`; STUDIO.md). The yellow sliver at Arrange's right edge
   is the minimap's "You" marker shown while its window is away (D-447): hide it. Drop the unread
   `ArrangeCamera.Room.slot` and `slotBox` (D-443); rename `BuildView.eyeBox` (D-444). Anything
   else that projects from `ViewportSize` by hand lands 10 points low on a notched phone: give it
   `lens`'s screen (D-446). Arrange reopens on the last tab (the door shot): does the doc want
   that? After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting (D-353):
   cross-legged on the blanket needs our own animation; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; a lifted lit piece's light; a grow while Arrange is open closes it (D-356);
   Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused cubby place
   (D-352). A taken-out find comes out whole even when the save has it cracked.
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
