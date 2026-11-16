# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 194 (B-05b2a, D-217) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-05b2 split: B-05b2a done in code, passes checks, untested in Studio. As a packed unit's
  door first lifts (or a saw's hole goes through), `Deals.layStacks` stands its blocks
  (`Packed.layout(size, number)`, the one layout the deal and the keepers' map share) in the
  hall piece and marks the unit `PackedUnit`; everything it holds stands in its clearing
  (`DealSpot.Unit.room`, `stacks`): a box nearest `lure` (just round the bend), a keeper nearest
  `nook` (the hidden end); the corner's low stack last, only if clear (`layCorner`).
- Keepers: `KeeperMap.pack` makes the unit its path plus its clearing, joined at the bend
  (`Keepers.add` takes `deck.packed`; Studio warns if the map's bend and the stacks' disagree).
- Crawls: no Crawl button on a hole into or out of a packed unit.
- Studio Output: "Deals: packed with boxes on floor N: ..." as a floor is laid, and each packed
  unit's "held" line ends "(packed: its clearing round the bend to your right/left from the hall)".

## Next task: B-05b2b Walk a packed unit in Studio
ROADMAP B-05b2b; D-217. The moment: a door lifts on a wall of boxes with one dark path; you
squeeze in, the walls close round the camera, and round the bend waits the box or a sleeper.
1. Workspace `DevFloorSeed` 2000013, `DevFloorNumber` 3; Play. Read Output's packed list; no
   "bend is off the map" warning (if there is one, the unit frame's X sign in
   `KeeperMap.pack`'s `unitRect` is flipped against `FloorBuilder.face`).
2. Lift a packed unit (teleport the character with execute_luau). Check the stacks stand in
   the unit (not mirrored, not floating), the clearing turns the side Output says, the box
   stands round the bend, and its corner shows from the doorway (one small screenshot).
3. The camera in the path at a small phone sideways: zoomed in? clipping? If Roblox's camera
   pops badly, look for the game's camera code (grep `CameraMinZoomDistance`, `Popper`) before
   building anything; a fix that fits goes in, else a ROADMAP polish line.
4. Wake a sleeper in a packed unit (find one with Output's "held" lines; `Workspace` dev
   attributes or a horn) and watch it walk spot, bend, path middle, door.
5. Saw into a packed unit (the saw dev flow in OWNER.md's crawl steps): no Crawl button.
6. Fix what's wrong; tighten OWNER.md's "Walk a packed unit" steps to what you saw.
**Acceptance:** checks green; the above seen in Play and said so in OWNER.md; Play stopped.
**Read first:** ROADMAP B-05b2b; D-217 (`docs/DECISIONS.md`, last entry); OWNER.md "Walk a packed
unit"; `src/server/Deals.luau` (grep `layStacks`, `layCorner`); `src/shared/KeeperMap.luau`
(grep `function KeeperMap.pack`); `docs/STUDIO.md` (grep `execute_luau`, `Play`).

## Queue (next sessions, the owner's ten-ticket order)
0. After B-05b2b: S3-03 Cut Free (it owns Studio's "CutFree" let-in; rows in `Products`,
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
