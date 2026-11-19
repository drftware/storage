# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j1d3a done: the floor fills the band, on the drawn screen (D-446) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now: S5-03j1d3b, j2 to j7, ENG-29, k1 to k6.
- **Studio has tonight's code**, `rojo serve` (port 34872) connected: restart Play to run edits.
- **The build camera's home view** (D-446, `docs/art/s5-03j1d3-small.png`, `-medium`, `-large`):
  the room's floor fills the band (58 to 186 on the A16, less 6 each end), centred; Small 21
  studs out and Medium 32 with their far walls' tops off the top; Large 48.5 and XL 68.5 whole.
  `ArrangeCamera.lens` gives the orbit and fit the screen the camera draws (779 by 359 on the
  A16), not `ViewportSize`'s safe area (685 by 338): measured floor 64 to 180, as the sums say.
  Done's close seen: your eyes, Roblox's camera, world buttons and light all back.
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`; `CameraTest` (client: "state",
  "frame", "right", "wheel", "tap", "drag").
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j1d3b The build camera's turn, its shots and a lift
The moment: whatever home you own, Arrange lifts you out over it and you can turn all the way
round it with the room clean; the front tab dips to your door; a tap on a find picks it up.
Verification only: fix what's broken; anything bigger goes in S5-03j2's ROADMAP lines.
1. `get_studio_state`; Play. Server: `ArrangeTest:Invoke(player, "size", "Medium")`, wait 4,
   pivot to (62, 3, 479). Click Arrange (692, 27) then `wait` 2500 in the same list. Capture by
   STUDIO.md's "Capturing the phone" (window 25030; crop 360 356, 672 by 314).
2. Medium, then Large: `CameraTest` "right", 342, 200, 196, 0 (90°) three times, a capture
   after each. Look for: the masks fading with their walls (no dark slab between you and the
   room), nothing of the lobby at the screen's edges. XL: the home view captured ("frame" too).
3. The front tab (gui 138, 328): the dip to the door; after a card chip, the hall dip. Done
   (666, 38) from a front shot: the swoop back. WASD after picking a desktop device in the
   simulator's menu (`user_keyboard_input`), then back to the A16.
4. A tap on a find in the room lifts it (today's drag): `WorldToViewportPoint` of a placed
   find's pivot, tapped with `user_mouse_input` (add 47 across), the ghost rising.
5. Stop Play; don't save. Captures to `docs/art/` at half scale (`sips -Z 336`). **Acceptance:** the turn, XL, the dips, WASD and a lift seen and captured; check green.
**Read first:** D-446 in DECISIONS; ROADMAP's S5-03j1d3b (grep it); STUDIO.md's "build camera
over a smaller home" section (its last four bullets); `CameraTest` in `ArrangeCamera.luau` (grep
"hook.OnInvoke").

## Queue (next sessions, the owner's ticket order)
0. Then S5-03j2 (drag it, let go). A yellow sliver shows at the right edge (capture ~628, 100)
   in Arrange, past the safe area (D-446): check what UI it is. Drop the unread
   `ArrangeCamera.Room.slot` and `slotBox` (D-443); rename `BuildView.eyeBox` (D-444). Anything else that projects from `ViewportSize` by hand (ArrangeView's
   drag?) lands 10 points low on a notched phone: give it `lens`'s screen (D-446). After S5-03j
   and k: the home's three "Polish:" lines under S5-03g2b (D-326 to D-328), then g3b.
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
