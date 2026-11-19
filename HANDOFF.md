# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j7b1 done: ArrangeView taken apart to wiring, 1744 to 851 lines (D-472) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j7b2, ENG-29 (a then b), k1 to k6.
- **ArrangeView is wiring only (D-472):** the tray and limit bar are `ArrangeTray` (its
  `Palette` holds Arrange's colours), the front tab's camera `ArrangeFront`, your home
  `ArrangeHome`, still and hidden `ArrangeStill`, the grid `ArrangeGrid`, the button
  `ArrangeButton`. New screen pieces go in their own module; ArrangeView only grows by joins.
- **Studio:** `rojo serve` in sync (port 34872); Edit, unsaved; clicks in STUDIO.md (grep "A Play pass").
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j7b2 What j7a didn't reach, and the editor's phone steps
The moment: the whole editor on a phone, every press answering (The Sims 4).
1. Seen and captured at A16 (`docs/art/s5-03j7b2-*`, half scale, looked at): the weighted
   landing (a heavy and a light thing set down: thud and dust, D-461); Put away's flight into its
   card (a RenderStepped logger, STUDIO.md "Watching something too quick"); Redo of a group Put
   away; the carried green (only the red was captured in j7a).
2. A group's Turn: in j7b1 a box of four in Medium's corner (job box, two crates, moon lamp)
   turned nothing and said nothing (D-472). Tell a quiet refusal from a turn that never reaches
   the server (`ArrangeGroup.turnNow`, the `ArrangeGroup` remote's answer); a refusal must answer
   (the plan's table: a shake and a dull click), never nothing.
3. Judge at full scale: the guide line between lined-up edges (`s5-03j3b-crate-lined-up.png`);
   the wall height handle beside the sign (`s5-03j3c2-handle-raised-closeup.png`).
4. Walk the plan doc's "Every action answers" table row by row; fix what's flat, each fix in
   the module that owns it (never back into ArrangeView).
5. OWNER.md's phone steps for the whole editor in one ordered block (what Studio can't drive).
**Acceptance:** green; every row of the table seen or listed in OWNER.md; captures looked at;
ArrangeView no longer than 851 lines.
**Read first:** ROADMAP's j7b lines (grep `j7b2`); D-461, D-470 to D-472; STUDIO.md "A Play
pass through the whole editor" and "Watching something too quick"; the plan doc's "Every action
answers"; `src/client/ArrangeGroup.luau` by grep (`turnNow`, `answered`).

## Queue (next sessions, the owner's ticket order)
0. After j7b2: ENG-29a. **The shelf's cubby finds stand off the shelf:** in the Studio save two
   (the stained-glass lamp, the walking robot, spots 3 and 6) are drawn 8 and 12 studs in front
   of Medium's shelf (D-470): `Shelves`' `spotAt` past this shelf's tiers? Polish by name: the
   place's squash, a drag's tilt, a group's ghost shadows. The held-find view hides the crates at
   phone size. Pallet and camp bed cards float back in Small (D-461). A tray card's drag isn't
   Gestures' (D-453). Hide the minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`,
   `slotBox` (D-443); rename `BuildView.eyeBox` (D-444). Hand projections: use `lens` (D-446).
   `ToolView.luau` ~1293 reads on-screen as "ahead" (D-451). Arrange reopens on the last tab. A
   blocked let-go may be judged blocked again (D-456). One lamp drag tocked three times (D-457).
   Sit and Open hide a held find's kept spot; a cubby find can't be held to open Arrange (D-466).
   A crowded button's key still presses it on a computer (D-471).
   After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting (D-353).
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; a lifted lit piece's light; a grow while Arrange is open closes it (D-356);
   Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused cubby
   place (D-352); a cracked taken-out find comes out whole; a cubby Take keeps no spot (D-465).
3. The home's warm fill (D-290). Brix (in `../engine`): ENG-25b's two-client run; Driving's
   stick read (D-254); a PlayerSaves hook before a leaving save's last write.
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 361.
   Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
