# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j3a done: the snapper, pure (D-455) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j3a2, j3b, j3c, j4 to j7, ENG-29, k1 to k6.
- **`Home/Snapping` is pure and specced, not wired** (D-455): only arriving at a wall turns a
  piece; walls and tops hold a little past where they took hold; never the door's wall.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j3a2 The snapper in the hand
The moment: a crate pushed toward the back wall swings its back to it and sits flush; a cup
dragged over the job box hops up onto it, and back down once clearly off the edge (The Sims 4).
1. `ArrangeHand.Lifted` gains `backs: boolean` (furniture by `Furniture.ofPlaced(l.name)`, not
   `Snapping.Flat`, not a `Layout.Lean` kind), `wall: number?`, and `lines:
   Brix.PlacementAlignment` (`{ x = 0, y = 0, count = 0, guides = {} }`, made once per lift).
2. In `lift`, where a placed thing's pose is read (~line 613): `l.wall = Snapping.wall(...)`
   from that pose with `at` nil, so a piece lifted off a wall starts against it and never turns.
3. `settle` (~313): after the grid and clamp, on "Floor", not Free, `l.backs`: `wall =
   Snapping.wall(floor, x, y, rx, ry, turn, l.wall)`; `l.turn = Snapping.turned(l.turn, wall,
   l.wall)`; if the turn changed, snap and clamp again with it; `l.wall = wall`; against a wall,
   `Snapping.flush`. Then (not Free, not the mirror) `r.placements:align(l.id, l.shape, pose,
   Snapping.Line, l.lines)` and `Snapping.lineUp(..., across = wall and Snapping.across(wall))`,
   writing the count back into `l.lines.count`; Free or the mirror: count 0. Layout's lean and
   clear stay last (the job box turns, then keeps its lid's room).
4. `aim` (~238): tops by `Snapping.over(x, y, w, d, l.pose ~= nil and l.pose.on == id)`
   instead of `REACH`; on a near tie in ray distance the current top wins. Rooms keep `REACH`.
5. Studio at A16 (CameraTest "carry", STUDIO.md; aim with `WorldToViewportPoint`; read state
   with execute_luau): a crate turns and sits flush at the back wall; R there keeps its turn.
**Acceptance:** green; both moments seen in Studio (the job box's find too), in `docs/art/`.
**Read first:** `src/shared/Home/Snapping.luau` (whole, ~200 lines); `ArrangeHand.luau` lines
200-345 (aim, settle) and 595-620 (lift's pose); DECISIONS D-455; ROADMAP's S5-03j3a2 and j3b.

## Queue (next sessions, the owner's ticket order)
0. A tray card's drag isn't Gestures': the wheel zooms, no twist (route the wheel, D-453).
   At Arrange's opening view a crate is ~16 points across (D-449): open closer; the wheel zooms
   through the facade (STUDIO.md). D held slides the room half off screen: limit it. Hide the
   minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox` (D-443); rename
   `BuildView.eyeBox` (D-444). Hand projections land 10 points low on a notch: use `lens`
   (D-446). `ToolView.luau` ~1293 reads the on-screen flag as "ahead" (D-451). Arrange reopens
   on the last tab: does the doc want that? `aim`'s room `REACH` stays 2.5 (D-455).
   After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
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
