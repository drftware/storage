# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 189 (B-03b, D-212) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-03 done. B-03b verified in Studio Play (one player, seed 2000013's floor 3): no coins lie on
  floors; a unit's coins come in its box (with its find or tool, or a box of their own), jump out
  at the burst round the find and fly into the opener's count, which waits for them (CoinView's
  `Pour`). Unit301: 2 coins alone; Unit312: padlock and 3; Unit319: skates and 2. No errors.
- Somebody's stuff now in 7 of 10 units with no keeper or note, laid last clear of the box.
- Nothing put in the place by hand. Studio shows two copies of new modules (Rojo glitch; harmless).

## Next task: B-04 The code's notes in boxes (split it first)
ROADMAP B-04 (D-205, D-044, D-045). The moment: a box opens on a scrap of paper with a digit on
it; you hold it up to read, then run it to the car where your friends are piecing the code
together by the keypad. Too big for one session: split in ROADMAP before building.
1. Split: **B-04a** a note comes in a box (dealt into the note unit's marked box, not stuck on
   the back wall; the box's reveal brings it to the hand; hold it up to read as D-045's view
   does today); **B-04b** carry it to the car (drop it in the car and it stays by the keypad for
   anyone to read; caught holding one, it drops where you were caught).
2. B-04a: notes are stuck by `FloorBuilder` (grep `Elevator.note`, `laying.notes`, ~line 368 and
   449); `Deal.Deck.notes` says which slot holds which note; `NoteView.luau` reads them on screen.
   A note in a box: `MarkedBoxes:stand(unit, place, nil, coins)` takes a find key; add a note
   (its text, never a catalog key), stamped with the open like `Find`. Decide how a held note is
   carried: a slot (Slots) or its own hand, and say so in OWNER.md if it's a default.
3. Note units get no stuff (`Deal.open`'s note check) and their back wall's faint mark and the
   guarded note's awake keeper (D-072) are tied to the note's unit: keep both working.
4. Every action answers: the note's own reveal (paper rustle, a lighter hold than a find's).
5. Prove in Play on seed 2000013 (STUDIO.md "Opening many doors fast": press the "Open" prompt
   by ActionText). Unit304's note is guarded by a keeper; Unit325's awake Mannequin ends the
   climb within seconds of getting near.
**Acceptance:** checks green; B-04a's note comes out of a box on screen and can be read; no note
on a back wall; OWNER.md has two-player steps.
**Read first:** ROADMAP B-04; D-044, D-045, D-205 (`docs/DECISIONS.md`); `src/server/FloorBuilder.luau`
(grep `note`); `src/client/NoteView.luau` (header); `src/server/MarkedBoxes.luau` (header, `open`).

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
   failed: No asset content representation"; the reveal and the box's coins untested with two
   players; Rojo's duplicate modules; a dropped find bumps a walking player (D-182); rbxassethash
   warnings in Play; the Packrat's dead Slots entry and S2-06b1's way home; the Mannequin's pose
   onto `Rig.luau` (D-176); the watch bar's empty panel; S1-07a, S2-02b to d4, S2-03b, S2-05a,
   S2-07a1 to b2 leftovers; unseen S1-10d1-3.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
