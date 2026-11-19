# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j5a1 done: a held find shows where it'd go (D-463) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j5a2, j5b, j6, j7, ENG-29, k1 to k6.
- **S5-03j5a1 is built and green, unseen in Studio** (D-463): `PlaceAim` (the one aim and judge,
  out of ArrangeHand and ArrangeView), `HandPlaceView` (the faint copy, Drop reads Place), the
  server's `HandPlace` ask (Arranging `placeHeld`, Slots `heldFromBox`/`setDown`).
- **Studio:** `rojo serve` (port 34872) was running; this session didn't open Studio.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j5a2 See placing by hand in Studio, and fix what's seen
The moment: in your own home, holding the teddy, you look at the job box's top and a faint teddy
sits there; Drop reads Place; one press sets it down with the landing's knock.
1. Run STUDIO.md's two tells ("Arrange's build camera, first try in Play"); if Studio lacks
   `PlaceAim`, `HandPlaceView`, `Shared/Home/HandPlace`, paste them by that section's recipe.
2. Play at Galaxy A16 (685 by 338). In your home, take a find into your hand (Take on a shelf
   find, or `ServerStorage.ArrangeTest:Invoke(player, "take", id)`). Aim the camera at the job
   box's top, the floor, a wall: the faint copy shows, glides, fades; Drop reads Place. Press it
   (or `:Invoke(player, "hand", on, x, y, turn)` for the server alone): the find stands there,
   your hand is empty, the save's rows have it (`"rows"`). Try a far spot (refused `far`), a
   friend's held find (not marked own: no Place), and Drop elsewhere (unchanged).
3. Fix what's wrong (watch: the third-person camera's look ray from behind your back may aim
   past near tops; the copy's first pivot; Drop's word coming back after a refusal). Capture the
   copy and the Place button: half scale plus a full-scale close-up in `docs/art/s5-03j5a2-*`.
**Acceptance:** green; seen in Studio Play at A16 and captured; the server refuses a far, bad or
someone else's ask.
**Read first:** DECISIONS D-463; `src/client/HandPlaceView.luau` (all, 382 lines);
`src/server/Arranging.luau` 520-540 and 698-715 (placeHeld, onHandPlace), 859-866 (the "hand"
test verb); `src/client/ToolView.luau` 596-606, 930-940, 1128-1136; STUDIO.md 3591 on.

## Queue (next sessions, the owner's ticket order)
0. S5-03j5b next after j5a2 (ROADMAP's split). Polish by name: the place's squash, a drag's tilt.
   Pallet and camp bed cards float back in the Small room (no free spot near the middle?):
   check (D-461). A tray card's drag isn't Gestures': the wheel zooms, no twist (route the wheel, D-453).
   At Arrange's opening view a crate is ~16 points across (D-449): open closer; the wheel zooms
   through the facade (STUDIO.md). D held slides the room half off screen: limit it. Hide the
   minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox` (D-443); rename
   `BuildView.eyeBox` (D-444). Hand projections land 10 points low on a notch: use `lens`
   (D-446). `ToolView.luau` ~1293 reads the on-screen flag as "ahead" (D-451). Arrange reopens
   on the last tab: does the doc want that? `aim`'s room `REACH` stays 2.5 (D-455). A blocked
   let-go's slide settles flush and lined up and may be judged blocked again: watch (D-456).
   One lamp drag off the job box tocked three times (D-457): find the third surface.
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
