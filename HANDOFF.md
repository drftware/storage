# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j5b1 done: a taken find keeps its spot and snaps back (D-465) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j5b2, j6, j7, ENG-29, k1 to k6.
- **Placing by hand is whole but for the held finger** (D-463 to D-465): a held find shows where
  you look and Place sets it; a Taken find leaves a still, fainter copy where it stood
  (`Tool.kept` on the server, `HandPlace.keptAttribute` on the slot) and a look near it snaps
  back. Seen in Studio Play at A16; `screen_capture` timed out twice, so no captures of it yet.
- **Studio:** `rojo serve` (port 34872) running and in sync; Studio left in Edit, place unsaved.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j5b2 Hold a finger on any of your things and Arrange opens with it lifted
The moment: in your home you press and hold on the lamp on the job box; Arrange rises round you,
the camera lifting to it, and the lamp is already in your fingers, ready to drag; let go and it
lands. Precedent: The Sims' and Animal Crossing's press-and-hold to pick up furniture.
1. Read the plan's "Placing by hand" section (docs tools), item 3.
2. Find what's under a held finger or mouse in your own home (a set-out find or piece, by its
   drawn model's id; `HomeTakeView` knows your set-out things). Use Brix Gestures' hold (ENG-27,
   `vendor/brix`: check its exports) rather than a timer of your own; only your own home, only
   while Arrange is shut, never a friend's things, and a hold on nothing does nothing.
3. Open Arrange with that thing lifted: `ArrangeView`'s `hold` opener (line ~1464) lifts a box
   piece; add the same for a thing already set out, reusing `ArrangeHand`'s `lift` (line 570)
   with its original model, so the drag, the let-go, undo and the server's Place work unchanged.
   Move the new piece into its own module if it's more than wiring (ArrangeView only shrinks).
4. Feedback: the light lift tap (`Feedback.Taps.Light`), the camera's rise; no text.
5. Seen in Studio Play at A16 (STUDIO.md "Placing by hand in Play" has the setup) and captured
   to `docs/art/s5-03j5b2-*` at half scale, plus the kept spot from j5b1 if the capture works.
**Acceptance:** green; a hold on your set-out lamp opens Arrange with it lifted and the drag goes
on under the same finger; a hold on a friend's thing or bare floor does nothing; a tap still
Takes as before.
**Read first:** DECISIONS D-465; `src/client/ArrangeView.luau` 150-160 and 1464-1500 (`hold`);
`src/client/ArrangeHand.luau` 570-620 (`lift`); `src/client/init.client.luau` 98-160;
`src/client/HomeTakeView.luau` 1-40; ROADMAP S5-03j5 (grep `j5b2`).

## Queue (next sessions, the owner's ticket order)
0. After j5b2: j6. Polish by name: the place's squash, a drag's tilt. The huge held-find view at
   the bottom left hides the crates at phone size. Pallet and camp bed cards float back in the
   Small room (D-461). A tray card's drag isn't Gestures': the wheel zooms, no twist (D-453).
   Arrange's opening view: crates ~16 points across (D-449). D held slides the room half off
   screen. Hide the minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox`
   (D-443); rename `BuildView.eyeBox` (D-444). Hand projections land 10 points low on a notch:
   use `lens` (D-446). `ToolView.luau` ~1293 reads the on-screen flag as "ahead" (D-451).
   Arrange reopens on the last tab. A blocked let-go may be judged blocked again (D-456). One
   lamp drag tocked three times (D-457). Capture the kept spot (D-465).
   After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting (D-353).
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; a lifted lit piece's light; a grow while Arrange is open closes it (D-356);
   Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused cubby place
   (D-352). A cracked taken-out find comes out whole. A cubby Take keeps no spot (D-465).
3. The home's warm fill (D-290). Brix (in `../engine`): ENG-25b's two-client run; Driving's
   stick read (D-254); a PlayerSaves hook before a leaving save's last write.
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
