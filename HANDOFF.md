# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j1d3b done: the build camera seen whole (D-447) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now: S5-03j2a, j2b, j3 to j7, ENG-29, k1 to k6.
- **The build camera is done** (S5-03j1, D-439 to D-447), seen whole at A16 size
  (`docs/art/s5-03j1d3b-*.png`). S5-03j2 is split in a and b (D-447).
- **Studio has tonight's code**, `rojo serve` (port 34872) connected: restart Play to run edits.
- Studio hooks: `ArrangeTest` ("size", "place", ...), `CameraTest` (client), `GrowTest` "cash".
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j2a The hand: drag it, let go
The moment: you put your thumb on the mat and drag; it lifts with a little stretch and a whoosh,
hangs just above your thumb with its shadow on the floor, and the moment you let go it's down.
Drop it on the shelf's spot and it slides aside to the nearest free floor instead of sitting red.
Steps are ROADMAP's S5-03j2a 1 to 6 (grep it); in short:
1. New `src/client/ArrangeHand.luau`: move the lifted state and every function that moves it out
   of ArrangeView (the list is in ROADMAP); ArrangeView keeps gui, tray, tabs, verbs and wires.
   Move first with no behaviour change, `scripts/check.sh` green, then change behaviour.
2. One Gestures reader: ArrangeCamera's `pick` answers the hand's `pickAt` thing; intents with
   a target go to a new `Options.hand`. ArrangeView's room `InputBegan`/`Changed`/`Ended` go; a
   tray card's drag keeps its gui input and hands moves and release to the hand.
3. Let go places at once; blocked uses `r.placements:nearestFree(...)` with
   `Brix.PlacementSearch.grid` (replaces `freeSpot`); nil or a refusal floats back.
4. Thumb offset, stretch, whoosh and one shadow part; numbers in shared `Arrange` with comments.
5. A tapped card lifts to the drawn screen's middle (`ArrangeCamera.lens`), not `ViewportSize/2`.
6. Studio Play at A16 (Medium home): drag a placed find to free floor, onto a blocked spot, and a
   card out of the tray dropped off the floor; capture each (STUDIO.md's "Tapping a placed find").
**Acceptance:** each seen and captured; ArrangeView shorter by the hand; check green.
**Read first:** ROADMAP's S5-03j2a (grep it); the doc's "Moving things" list (block
`mmpnpe7tg17.3575`, `payload={"kind":"view","parentId":"mmpnpe7tg17.3575"}` on node
`70f24726-b214`); `../engine/src/Contracts/Gestures.luau` (promises 2 to 5, `Intent`); the
Placements contract's `nearestFree` (grep `../engine/src/Contracts`); ArrangeView's hand (grep
"local function rides" to "local function answered", and "local function pickAt" to the end of
`ended`); ArrangeCamera's `Brix.Gestures.new` and `local function apply` (grep).

## Queue (next sessions, the owner's ticket order)
0. After S5-03j2: the yellow sliver at Arrange's right edge is the minimap's "You" marker (gui
   742, 58) shown while its window is away (D-447): hide it too. Drop the unread
   `ArrangeCamera.Room.slot` and `slotBox` (D-443); rename `BuildView.eyeBox` (D-444). Anything
   else that projects from `ViewportSize` by hand lands 10 points low on a notched phone: give it
   `lens`'s screen (D-446). Arrange reopens on the last tab (the door shot): does the doc want
   that? After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting's leftovers
   (D-353): cross-legged on the blanket needs our own animation; lying on the bed.
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
