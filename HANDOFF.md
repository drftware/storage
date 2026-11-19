# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j6b2b done: the group seen in Studio Play at A16 (D-470) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j7a, j7b, ENG-29 (a then b), k1 to k6.
- **Several at once works** (D-470, `docs/art/s5-03j6b2b-*`): carry, refuse (nothing changes),
  land as one ask, Undo/Redo, Turn, Put away and its Undo, all seen. A shelf is now boxed by its
  own body (`Arranged.bounds(model, Shelf.Tag)`). Unseen: a refused group Turn, Redo of Put away.
- **Studio:** `rojo serve` in sync (port 34872); Edit, unsaved; clicks in STUDIO.md (D-470's).
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j7a The editor seen whole, and the screen's fixes
The moment: a whole room rearranged on a phone, every press answering clearly (The Sims 4).
1. World buttons that overlap at phone size (the "Open" and "Sit" on two neighbouring crates,
   `docs/art/s5-03j5b2-kept-spot-closeup.png`, `s5-03j5a2-place-close.png`): fix it in
   `ButtonView` for every button, naming no find (nudge overlapping chips apart on screen, or
   show only the nearest thing's). Capture before and after.
2. Arrange's opening view: open closer (a crate now ~16 points across, `s5-03j6a-selected.png`,
   D-449) and limit D's slide (D held slides the room half off screen).
3. See and capture what's never been seen: the weighted landing (a heavy and a light place,
   thud and dust, D-461); Put away's flight into its card (sample it with a RenderStepped logger,
   STUDIO.md "Watching something too quick"); a group's Turn refused; Redo of a group Put away.
4. Judge at full scale: the guide line between lined-up edges (`s5-03j3b-crate-lined-up.png`);
   the wall height handle beside the sign (`s5-03j3c2-handle-raised-closeup.png`): say whether
   it reads right or move it above. The carried group's green and the box's glow read faint at
   phone size (`s5-03j6b2b-carried-green.png`): make them read, for one thing and a group alike.
5. Walk the plan's feedback table ("Every action answers") row by row in Play; fix what's flat.
**Acceptance:** green; captured to `docs/art/s5-03j7a-*` at half scale and looked at: no
overlapping buttons, a larger opening view, the landing and flight seen, the glows readable.
**Read first:** ROADMAP's S5-03j7a lines (grep `j7a`); `src/client/ButtonView.luau` 1-80 then by
function; `src/client/ArrangeCamera.luau` (grep "opening"); D-461 and D-470; STUDIO.md "Driving
the group in Play" and "Boxing several things in Play"; the plan doc's "Every action answers".

## Queue (next sessions, the owner's ticket order)
0. After j7a: j7b (ArrangeView, 1744 lines, taken apart to wiring well under 1520; OWNER.md's
   phone steps). **The shelf's cubby finds stand off the shelf:** in the Studio save two (the
   stained-glass lamp, the walking robot, spots 3 and 6) are drawn 8 and 12 studs in front of
   Medium's shelf (D-470): `Shelves`' `spotAt` past this shelf's tiers? Polish by name: the
   place's squash, a drag's tilt, a group's ghost shadows. The held-find view hides the crates
   at phone size. Pallet and camp bed cards float back in Small (D-461). A tray card's drag isn't Gestures': the wheel zooms, no twist
   (D-453). Hide the minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox`
   (D-443); rename `BuildView.eyeBox` (D-444). Hand projections: use `lens` (D-446).
   `ToolView.luau` ~1293 reads on-screen as "ahead" (D-451). Arrange reopens on the last tab. A blocked let-go may be judged blocked again (D-456). One
   lamp drag tocked three times (D-457). Sit and Open hide a held find's kept spot; a cubby
   find can't be held to open Arrange (D-466).
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
