# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 192 (B-05a, D-215) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-05 split: B-05a done. Seven blocks of boxes (`art/packed/`; ColumnA-C, WideA/B, Half,
  Toppled), one MeshPart each, 84-326 triangles, in the boxes' own texture. `src/shared/Packed`:
  `prepare`, `clone`, generated `Specs` (footprint, real reach, height, `Pitch` 2, `Ceiling` 10).
- In the place by hand: `ReplicatedStorage.Props.Packed` (asset 124665632785131), verified in
  Studio Edit: sizes match Specs, fronts face LookVector, all share the boxes' ColorMap. Not yet
  laid on any floor; not seen in Play.
- Sheets `art/sheets/packed-*.png`: a sample packed M unit (`art/packed/spec.py` `SAMPLE`).

## Next task: B-05b The deal and the path
ROADMAP B-05b (D-205's defaults; D-215 for the blocks). The moment: a door lifts on a wall of
boxes to the ceiling with one dark path through; you squeeze in, the walls close round the
camera, and round the bend at the back waits the marked box, or a monster asleep. Never nothing.
1. Pure layout first, with a Lune spec (`tests/packed.spec.luau` exists; add a layout spec): for
   an M unit (12 x 12, door 8 wide), the path 3 wide (a body is 2) in from the doorway, bending
   once at most, to a clearing about 3 deep at the back; blocks along every edge the path and
   the doorway can see, fronts on the path, at `Specs.Pitch`, gaps no wider than ~1.2. The
   sheets' `SAMPLE` in `art/packed/spec.py` is one hand-made answer to copy the feel of.
2. Keep clear (DealSpot): `DealSpot.Door` 2.5 from the doorway's face; side walls' crawl holes
   (`DealSpot.Hole` 3.3 along their stretch, `DealSpot.holes(unit)`); the drop-in landing from
   the top (`LandSide` 1.5, `LandBack` 0.9, clear to the door); the bulb hangs mid-unit at ~8.7
   (keep the path under it, as the sample does). A sleeper needs `DealSpot.Keeper` (2.1 x 1.5)
   or `Packrat` (2.75 x 2.5) in the clearing.
3. The deal (`src/shared/Deal.luau`, grep `packs`, `noteIn`, `StuffShare`): about one in three
   M units packed, more on higher floors (a share in Config with its comment); small units stay
   open; a packed unit's clearing holds its marked box or a sleeper (no "Nothing"), and no
   somebody's stuff. A note's unit may be packed. Lay with `Packed.clone` where `DealSpot.stuffIn`
   lays stuff today (grep `stuffIn` in `src/server`).
4. Keepers must path through (Keepers' map, D-064): check the map sees the blocks as walls and
   the 3 wide path as walkable.
5. Studio Play, seed 2000013's floor 3: walk a packed unit; judge the camera in the path at phone
   size (small phone sideways). Clipping: say how in OWNER.md, add a ROADMAP polish line.
**Acceptance:** checks green; floor 3 shows packed units with a walkable path to the back; the
marked box or a sleeper sits in the clearing; OWNER.md has numbered steps to walk one.
**Read first:** ROADMAP B-05b; D-215 (`docs/DECISIONS.md`, last entry); `art/packed/README.md`;
`src/shared/DealSpot.luau` (lines 50-105, grep `stuffIn`, `holes`); `src/shared/Deal.luau` (grep
`packs`, `noteIn`, `stuffFrom`); `src/shared/Packed/init.luau`.

## Queue (next sessions, the owner's ten-ticket order)
0. After B-05b: S3-03 Cut Free (it owns Studio's "CutFree" let-in; rows in `Products`,
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
   rbxassethash warnings; the Packrat's dead Slots entry, S2-06b1's way home; the Mannequin's
   pose onto `Rig.luau` (D-176); the watch bar's empty panel; S1-07a, S2-02b-d4, S2-03b,
   S2-05a, S2-07a1-b2 leftovers; unseen S1-10d1-3. More box words need the boxes' rebake (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
