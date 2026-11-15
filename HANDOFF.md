# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 190 (B-04a, D-213) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-04 split in ROADMAP: B-04a done, B-04b next. B-04a verified in Studio Play (one player, seed
  2000013's floor 3): no note on any back wall; Unit317's box held "_ _ _ 4", the paper rose,
  flew to the screen and the card lifted with it; the pocket paper showed at the left edge. The
  pocket paper's writing now stays on one line (fixed after Play, untested in Studio); tapping a
  pocket paper to hold it up again is untested in Studio.
- A note's unit is dealt no find or tool (`Deal.noteIn`); its box holds the note and its coins.
- Held notes live in `MarkedBoxes`' `pockets` (server), mirrored on the player as `NoteCard.Held`.
  Caught players keep theirs; a player who leaves puts theirs back on its unit's back wall.
- Nothing put in the place by hand.

## Next task: B-04b Carry it to the car
ROADMAP B-04b (D-205, D-213, D-045). The moment: you run your note to the car where friends are
piecing the code together; you leave it by the keypad and anyone can read it there. Caught (or
gone) holding one, it drops where you were, for a friend to fetch.
1. Move the pockets out of `MarkedBoxes` into a server system of their own (grep `pockets`,
   `putBack`, `mirror`): `give(player, note, unit)`, `drop(player, at)`, `leave(player)`.
2. A dropped note is a world note: `Elevator.note(pivot, parent, text)` (tagged `CodeNote`, so
   NoteView gives it its Read button), lying flat on the floor or stuck where it lands; a Take
   prompt puts it back in a pocket (rate-limited, server-checked as every press is).
3. In the car: a "Leave" press by the keypad, or notes laid by it as you step in; pick one, name
   the hit game it comes from (AGENTS.md), and put the default in `OWNER.md`. The car is
   `ReplicatedStorage.Shared.Elevator` (grep `keypad`, `Keypad`) and `src/client/KeypadPad.luau`.
4. Caught: find the caught signal (`src/server/KeptPlayers.luau` header) and drop the caught
   player's notes where they were caught; on leaving, drop them where they were (not the wall).
5. Every action answers: a paper flap and a tumble as it drops, a pin's tap by the keypad.
6. Prove in Play on seed 2000013 floor 3 (STUDIO.md "Opening many doors fast": the camera must
   point at a prompt before pressing it). Unit317 and Unit313 hold unguarded notes.
**Acceptance:** checks green; a note left in the car is readable by the keypad; a note dropped on
being caught lies on the floor and can be taken; OWNER.md has two-player steps.
**Read first:** ROADMAP B-04b; D-213 (`docs/DECISIONS.md`); `src/server/MarkedBoxes.luau` (grep
`pockets`); `src/server/KeptPlayers.luau` (header); `src/shared/Elevator/init.luau` (grep `note`,
`keypad`); `src/client/NoteView.luau` (header).

## Queue (next sessions, the owner's ten-ticket order)
0. **B-05** Packed units (ROADMAP, D-205); then S3-03 Cut Free (it owns Studio's "CutFree"
   let-in; rows in `Products`, `Purchasing:prompt`), then S3-04.
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later. A GDD section costs ~15k context: `view`
   with `outline: true` and `from` the heading's id, then `search` with `blocks` on just the part needed.
5. Small: Play logs "rbxassetid://203785492 failed: Asset type does not match" (find which
   script asks for it); a find's copy coming out of a box logged "rbxassetid://73742731927159
   failed: No asset content representation"; the reveal, the box's coins and the note untested
   with two players; Rojo's duplicate modules; a dropped find bumps a walking player (D-182);
   rbxassethash warnings in Play; the Packrat's dead Slots entry and S2-06b1's way home; the
   Mannequin's pose onto `Rig.luau` (D-176); the watch bar's empty panel (it may sit over the
   pocket papers while caught); S1-07a, S2-02b to d4, S2-03b, S2-05a, S2-07a1 to b2 leftovers;
   unseen S1-10d1-3. `NoteSpot`'s back-wall spot now serves only the no-box fallback.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
