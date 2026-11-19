# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j1b tried, blocked on Studio's code (D-440) · **Checks:** green · **Git:** `main`, not pushed; Brix `0b2230c`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now (D-440): ENG-26c, S5-03j1b, j2 to j7, ENG-29, k1 to k6.
- **Studio runs this morning's code** (D-440): no Rojo, so the build camera and Brix's Gestures
  and OrbitCamera aren't in the place; the owner's Connect click fixes it (`OWNER.md`). Before
  Studio work check `require(ReplicatedStorage.Brix).Gestures` isn't nil; if it is, see STUDIO.md's
  "Arrange's build camera, first try in Play" (pasting the files in; the simulator's mouse).
- **The build camera** (S5-03j1a, D-439): `src/client/ArrangeCamera.luau`, `Home/BuildView`,
  `Arrange.Camera`; unseen in Studio. S5-03j1b (ROADMAP, unchanged) comes after ENG-26c.
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`.
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: ENG-26c Nearest free spot and guides, in Brix
The moment (S5-03j2): let go of a piece where it doesn't fit and it slides to the nearest spot
that does; while you drag, faint lines show where its edge or middle lines up with a neighbour's
(The Sims 4, Bloxburg). This is the pure engine half, in `../engine`; the game wires it in j2.
1. `git -C ../engine status --short` clean, or stop and say so. Work by Brix's AGENTS.md; file
   ENG-26c in its ROADMAP. The plan doc's drag section (search "nearest free") says what's needed.
2. Contract first in `src/Contracts/Placements.luau`: the nearest free pose to a blocked one on
   the same area within a reach (grid steps outward, ties broken the same way every time, the
   turn kept), and the guide lines where a footprint's edges or middle meet a neighbour's on the
   same area within a tolerance. Neutral names; each with a doc comment.
3. Suite cases first, each proven to fail a broken stand-in; then implement in
   `src/Systems/Placements.luau`; a bench (an answer allocates only what it returns); the
   module page `docs/modules/Placements.md`. Brix's checks green; commit in `../engine`.
4. Here: move `vendor/brix` to that commit, a line in `docs/FRAMEWORK.md`, `scripts/check.sh`
   green, commit with `-- <paths>`.
**Acceptance:** each new promise fails its suite when broken; both repositories' checks green;
the pin moved; ROADMAP's ENG-26c ticked with its Brix commit.
**Read first:** ROADMAP's ENG-26c (grep `ENG-26c`); `../engine/HANDOFF.md`'s Next task and
`../engine/AGENTS.md`; `../engine/src/Contracts/Placements.luau`;
`../engine/docs/modules/Placements.md`; the plan doc's drag section; `docs/FRAMEWORK.md` (grep
`Placements`).

## Queue (next sessions, the owner's ticket order)
0. After S5-03j and k: the home's three "Polish:" lines under S5-03g2b (the hand-over's shade,
   D-326, D-327; the mirror keeping the old look; the floor's wipe under the tray, D-328), then
   g3b's plate swapping in plays (ROADMAP's "Polish (g3b)").
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting's leftovers
   (D-353): cross-legged on the blanket needs our own animation; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; Arrange shows the job box's "Open" and the door's buttons; a lifted lit
   piece's light; a grow while Arrange is open closes it (D-356); Robux unit and gift cards
   unseen; the XL limit bar; Take through a wall; a refused cubby place (D-352). A taken-out
   find comes out whole even when the save has it cracked. Several of these may fall out of
   S5-03j's rebuild: check each against it before building.
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
