# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 191 (B-04b, D-214) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-04 done. Notes ride in `src/server/Pockets.luau` (give, pin, drop); MarkedBoxes hands each
  box's note to it. Walk within 5 studs of a floor keypad's face holding notes and they fly onto
  the lobby wall beside it in a row (tack's tap, Read buttons); caught or leaving, they tumble out
  flat on the floor with a server Take. `src/client/NotePlaces.luau` plays the flight and tumble.
- Verified in Studio Play (seed 2000013's floor 3) with a test instance of Pockets: pins flush on
  the wall and legible, the flight lands at 0.39 s with its tap; a drop lay flat, Take pocketed
  it. Untested in Studio: a real box's note through the running system, a real catch, leaving,
  two players. The row's tighter spacing (four before the side wall) came after Play.
- Nothing put in the place by hand.

## Next task: B-05 Packed units
ROADMAP B-05 (D-205's agreed defaults, DECISIONS line ~5462). The moment: a door lifts on a wall of
boxes to the ceiling with one dark path through; you squeeze in, the walls close round the
camera, and at the back waits the marked box, or a monster asleep. Never nothing.
1. Split first in ROADMAP if it won't fit: B-05a the stacks' art, B-05b the deal and the path.
2. Art first, the finds kit's way (`art/finds/CRAFT.md` is the bar; `art/boxes/` built the
   marked box: reuse its cardboard texture set). A few stack models (a column, a wide stack, a
   half-height stack, a toppled pair), few triangles each, for low-end phones. FBX + Specs via
   `scripts/art.sh`; import per `art/unit/README.md` (STUDIO.md's FBX recipe).
3. The deal: about one in three medium and large units packed, more on higher floors; small
   units stay open. A packed unit's back holds its marked box or a sleeping monster (`Deal.luau`
   grep `packs`, `noteIn`; `DealSpot` grep `stuffIn`, `holes`). A note's unit may be packed too.
4. The path: a gap the width of a body and a bit, bending once at most, clear of the door's
   swing and of every DealSpot spot; a keeper must still path through (Keepers' map, D-064).
5. Judge the camera in the path at phone size (Device emulator, small phone sideways): it must
   not clip into the stacks; if it does, say how in OWNER.md and add a ROADMAP polish line.
**Acceptance:** checks green; a seed's floor 3 shows packed units with a walkable path to the
back; the marked box or a sleeper sits there; OWNER.md has the steps to walk one.
**Read first:** ROADMAP B-05; D-205 (`docs/DECISIONS.md`, from line 5448); `art/finds/CRAFT.md`;
`art/boxes/README.md`; `src/shared/Deal.luau` (grep `packs`, `noteIn`); `src/shared/DealSpot.luau`
(grep `stuffIn`).

## Queue (next sessions, the owner's ten-ticket order)
0. After B-05: S3-03 Cut Free (it owns Studio's "CutFree" let-in; rows in `Products`,
   `Purchasing:prompt`), then S3-04.
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
   failed: No asset content representation"; Play warns `ConfigService: Config value not found
   for key "sellTestPurchase"`; the reveal, the box's coins and the notes untested with two
   players; Rojo's duplicate modules; a dropped find bumps a walking player (D-182);
   rbxassethash warnings in Play; the Packrat's dead Slots entry and S2-06b1's way home; the
   Mannequin's pose onto `Rig.luau` (D-176); the watch bar's empty panel (it may sit over the
   pocket papers while caught); S1-07a, S2-02b to d4, S2-03b, S2-05a, S2-07a1 to b2 leftovers;
   unseen S1-10d1-3. `NoteSpot`'s back-wall spot now serves only the no-box fallback.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
