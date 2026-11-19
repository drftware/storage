# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j2a1 done: the hand in code (D-448) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now: S5-03j2a2, j2b, j3 to j7, ENG-29, k1 to k6.
- **The hand is in code, untested in Studio** (S5-03j2a1, D-448): `src/client/ArrangeHand.luau`;
  the build camera's one Gestures reader feeds it; let go places (no Place button).
- **Studio has tonight's code**, `rojo serve` (port 34872) connected: restart Play to run edits.
- Studio hooks: `ArrangeTest` ("size", "place", ...), `CameraTest` (client), `GrowTest` "cash".
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j2a2 The hand seen in Studio
The moment: thumb on a find, drag; it comes up with a little stretch and a whoosh, hangs above
your thumb with its soft shadow where it'll land; let go and it's down. Blocked, it hops free.
1. Studio Play at A16 (685 by 338), Medium home (`ArrangeTest` "size"), Arrange open. Run the
   two tells first (STUDIO.md's "Arrange's build camera, first try in Play").
2. `CameraTest:Invoke("left", x, y, dx, dy, seconds)` from a find's screen point (STUDIO.md's
   "Tapping a placed find") to free floor: lifted mid-drag with its shadow, then landed.
3. The same onto the shelf's spot: it hops to free floor and lands. A card dragged up out of the
   tray and let go over the tray floats back into its card; a tapped card glides to the room's
   middle and lands; tap a find, Turn, tap the room: it lands turned.
4. Capture each at half scale to `docs/art/s5-03j2a-*.png`; fix what's off (thumb offset's
   sign, the shadow's size and darkness, a press on the lifted ghost via `pick`'s box test).
**Acceptance:** each seen and captured; check green. Then promote S5-03j2b (ROADMAP): tap
selects with round Turn, Put away and Another; a second finger's twist turns (`intent`'s "twist"
with a target already reaches `ArrangeHand.intent`); Alt and the Free switch; riders bounce.
**Read first:** ROADMAP's S5-03j2a2 (grep it); D-448 in DECISIONS; `ArrangeHand.luau` from
"Letting go" to the end; STUDIO.md's "Tapping a placed find" and "Arrange's build camera, first
try in Play"; the camera's `toHand` and `apply` (grep `src/client/ArrangeCamera.luau`).

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
