# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j4b1 done: things land as heavy as they are (D-461) · **Checks:** green · **Git:** `main`, not pushed; Brix `e62e218`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j4b2, j5 to j7, ENG-29, k1 to k6.
- **Every action answers, part one** (D-461): `Home/Feedback` picks a thud, dust and phone tap
  by a thing's catalog `heft` (furniture rows gained one); `ArrangeTaps` plays taps through
  `HapticEffect` on Touch only; Put away flies into its tray card. Heard in Studio: the crate's
  Medium knock and dust. The flight and the taps weren't seen there (OWNER.md).
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j4b2 The blocker glows
The moment: you drag the bed against the shelf and it goes soft red, and the shelf itself glows
red a moment with one dull knock, so you see what's in the way without a word (The Sims 4).
1. Brix first (ENG-26d, in `../engine` by its AGENTS.md; `git -C ../engine status` clean):
   Placements gains `blocking(id, shape, pose, into?) -> { Id }`: the things on the pose's area
   whose footprints the shape at that pose overlaps (`blockedAt`'s loop, gathering instead of
   stopping), `id` itself never; fills `into` (cleared first) so a drag asks with no allocation.
   A contract promise, suite cases (none, one, two, touching edges aren't, other areas aren't),
   its module page, checks, commit; move `vendor/brix` and note it in `docs/FRAMEWORK.md`.
2. The hand (`ArrangeHand.paint`/`setPose`): while the ghost is red for "overlaps", put a
   Highlight on each drawn blocker (soft red, fading in 0.1 s), swap as the set changes, clear
   on fit, let go, put away and close. One soft dull knock as it first turns red (the table's
   "once" per red spell), no phone tap. Colours and fade in `Arrange.Feel`.
3. Studio at A16: drag a crate into the job box; half-scale capture to `docs/art/` and a
   full-scale close-up beside it (STUDIO.md "Phone taps" for driving notes).
**Acceptance:** green; Brix's suite has the new promise; the blocker glows in Studio.
**Read first:** ROADMAP S5-03j4 (grep it); `../engine/src/Systems/Placements.luau` 203-232 and
`judge` (~385-430); `../engine/src/Contracts/Placements.luau` 30-60 and 196-240; `ArrangeHand.luau`
`paint` and `setPose` (grep); DECISIONS D-461; `../engine/AGENTS.md`.

## Queue (next sessions, the owner's ticket order)
0. Pallet and camp bed cards float back in the Small room (no free spot near the middle?):
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
