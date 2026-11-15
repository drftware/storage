# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 187 (B-02b, D-210) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-02 done. B-02b verified in Studio Play (one player): `DevBox` "OilLamp" stood a box in
  Unit301; Open: rip 0.12 s, the hold's rattle and blue glow from the tear, flaps held and
  trembling, the burst at 0.78 s (light flaring to 2.8), slap 0.86 s, the lamp's copy rising and
  turning, in the hand at 2.25 s as the copy went. A hand-stamped Legendary box's hold washed the
  unit gold at Level01 (`docs/art/B-02b-hold-legendary-level01.jpg`). Output: no script errors.
- New: `Opening` reveal rules (`Reveals`, `flapTime`, `glow`, `shake`, `lift`, `handAt`; specced),
  `Grades.Colours`, `Boxes.Reveal` sounds, `MarkedBoxes.stand(unit, place, find)` stamping
  `Find`/`Grade`/`LaidAt` and giving the find, `MarkedBoxView`'s held beat, glow, light and copy.
- Nothing put in the place by hand. Studio shows two copies of new modules (Rojo glitch; harmless).

## Next task: B-03a A unit's find or tool comes in its box
ROADMAP B-03 (D-205, D-210). Split it first in ROADMAP: B-03a (this: finds and tools go in the
box), B-03b (coins in boxes to the bank; somebody's stuff in most units, D-136). The moment:
a door rolls up on a unit with one warm-lined box; the find is never seen until you open it.
1. Read how Deals lays a find now (grep `Deals.luau` for `slots:lay`, `"Find"`, `contents.kind`)
   and the `DevBox` block (it already finds a spot: `DealSpot.inUnit(size, "Find", footprint,
   note, number, taken)` with the box's footprint, then `markedBoxes:stand(unit, placed(unit,
   spot), key)`). Replace the find's lay with that, for finds that fit the box.
2. Big finds stay out: a find whose `Tools.bounds(key).Size` won't fit inside
   `Boxes.Marked.Size` (less 0.1 a side) is laid as now. Pure rule + spec (e.g. in `Deal.luau`).
3. A tool dealt to a unit (grep `Deal.luau` for tool kinds) goes in the box too: `stand` takes
   a catalog key, and `Slots.give` gives tools as it gives finds; a tool's reveal plays as a
   Common (its row has no grade: check `MarkedBoxes`' `grade` fallback still holds).
4. The deck's odds, the Packrat's fetching (`Slots.finds`, `loose`) and the faint mark
   (`FaintMark`) assume finds lie loose: grep `finds(`, `loose`, `FaintMark` and decide each
   (a boxed find can't be fetched; default it, OWNER.md).
5. Remove `DevBox`'s "stands in the next unit" once real boxes deal (keep the find-key form if
   useful for testing grades). Prove in Play as STUDIO.md "Opening a marked box in Play" does.
**Acceptance:** checks green; in Play a dealt unit's find comes only in a box and its reveal
plays; a big find still stands loose; OWNER.md has two-player steps.
**Read first:** ROADMAP B-03; D-205, D-210; `src/server/Deals.luau` (grep, not whole);
`src/shared/Deal.luau` (grep); `src/server/MarkedBoxes.luau`; `src/shared/DealSpot.luau` (grep).

## Queue (next sessions, the owner's ten-ticket order)
0. **B-03b, B-04, B-05** (ROADMAP, D-205); then S3-03 Cut Free (it owns Studio's "CutFree"
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
5. Small: a find's copy coming out of a box logged "rbxassetid://73742731927159 failed: No asset
   content representation" nine times in Play (a find's mesh or texture; check which); the reveal
   is untested with two players and with a laid (full-hands) find; Rojo's duplicate modules; a
   dropped find bumps a walking player (D-182); a take could show the arm first (KeeperView Kit);
   rbxassethash warnings in Play; the Packrat's dead Slots entry and S2-06b1's way home; the
   Mannequin's pose onto `Rig.luau` (D-176); the watch bar's empty panel; S3-01b's wipe after the
   bring unseen; S1-07a, S2-02b to d4, S2-03b, S2-05a, S2-07a1 to b2 leftovers; unseen S1-10d1-3.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
