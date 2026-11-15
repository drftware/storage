# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 193 (B-05b1, D-216) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-05b split: B-05b1 done, pure only. `src/shared/PackedLayout.luau`: `lay(unit, number, reach,
  pitch)` gives a medium unit's blocks (name, x, z, yaw in DealSpot's frame), its `path` and
  `clearing` rectangles, the clearing's `side` and the `bend` (0, about 10). The path is 3 wide
  up the middle (takes the top hole's landing and runs under the bulb); unit 214 comes out
  almost as the art sheets' sample. 9 to 11 blocks, at most about 2,100 triangles.
- `Deal`: `deck.packed` (drawn last, nothing else moved), `packedShare`, `canPack`; a packed unit
  holds no stuff and an empty one gets `PackedCoins` (1). Specs `tests/packedlayout.spec.luau`,
  `tests/packeddeal.spec.luau`. Nothing lays the stacks yet: a packed door opens on an ordinary
  unit without stuff. Blocks in the place: `ReplicatedStorage.Props.Packed` (B-05a, by hand).

## Next task: B-05b2 The stacks on the floor
ROADMAP B-05b2; D-216. The moment: a door lifts on a wall of boxes to the ceiling with one dark
path through; you squeeze in, the walls close round the camera, and round the bend at the back
waits the marked box, or a monster asleep. Never nothing.
1. Lay the stacks wherever a unit is dealt (`open` and `dealShut` in `src/server/Deals.luau`; a
   saw's hole deals too): if `deck.packed[index]`, `PackedLayout.lay(size, number, reach,
   Packed.Specs.Pitch)` with `size` from `shape`, `reach` built once from `Packed.Specs.Blocks`
   (`PackedLayout.reachOf(b.Lo, b.Hi)`), each block by `Packed.clone(name, placed(unit, block),
   unit.Parent or unit)` (the hall piece, as `Stuff.lay` is). Lay them before anything else.
2. Everything the unit holds goes in the clearing, never the path: give `DealSpot.Unit` an
   optional `room` (the clearing's rectangle) that `spots` (DealSpot ~190) bounds to, ignoring
   `From`/`To`; `shape` sets it for a packed unit. Add a dealspot spec case. Want the marked box
   near the bend's corner so its warm line just shows from the doorway (D-215's lure).
3. Keepers walk out by the bend: find how a keeper leaves its unit (grep `lookOut`, `doorFront`,
   `offWalls` in `src/shared/Keeper.luau` and `KeeperMap.luau`); a sleeper in the clearing must
   go spot, `bend`, path middle, door, never through a stack (they move by CFrame, so they'd
   clip). The Packrat never packs (`canPack`).
4. Saws: OWNER.md's default (a hole into a packed unit opens onto boxes, no crawl through). Play on seed 2000013's floor 3 (Workspace `DevFloorSeed`, `DevFloorNumber`): Output
   says which units packed; walk one; judge the camera in the path at a small phone sideways;
   wake a sleeper in one. Clipping: say how in OWNER.md and add a ROADMAP polish line.
**Acceptance:** checks green; floor 3 shows packed units with a walkable path to the back; the
box or a sleeper waits in the clearing; a woken sleeper walks out by the path; OWNER.md has
numbered steps to walk one.
**Read first:** ROADMAP B-05b2; D-216 (`docs/DECISIONS.md`, last entry); the head comment of
`src/shared/PackedLayout.luau`; `src/server/Deals.luau` (grep `local function shape`, `placed`,
`local function open`, `dealShut`); `src/shared/DealSpot.luau` lines 190-240 and 330-395.

## Queue (next sessions, the owner's ten-ticket order)
0. After B-05b2: S3-03 Cut Free (it owns Studio's "CutFree" let-in; rows in `Products`,
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
