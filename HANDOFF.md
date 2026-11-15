# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 188 (B-03a, D-211) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-03a done, verified in Studio Play (one player, seed 2000013's floor 3): real units deal their
  find or tool inside the marked box when it packs (`Deal.packs`, `Deal.BoxWall`; Deals'
  `layBoxed`); the padlock opened as a Common into slot 1, the skates as an Uncommon into slot 2;
  the oil lamp and desk lamp stood loose; `DevBox` "StainedGlassLamp" forced a box. No errors.
- 16 of 23 finds pack; no Legendary or Secret does (all lamps): a tall marked box is suggested in
  `OWNER.md`. Of the tools only the padlock packs. The Packrat leaves shut boxes alone.
- Nothing put in the place by hand. Studio shows two copies of new modules (Rojo glitch; harmless).

## Next task: B-03b Coins in boxes, and somebody's stuff in most units
ROADMAP B-03b (D-205, D-211, D-136). The moment: a door rolls up on a unit with somebody's stuff
and one warm-lined box; you open it and coins jingle out into your bank, maybe with a find.
1. Coins in the box: a unit's coins (`contents.coins`, 1 to 3) go in its box instead of
   `layCoins` (Deals.luau): a unit with coins and nothing else stands a box holding only coins;
   with a boxed find or tool, both in the one box. A big loose find's coins: default in a box
   beside it (one box a unit, D-205), OWNER.md line.
2. `MarkedBoxes.stand(unit, place, find, coins)`: stamp `Coins` with the open (beside `Find`);
   pay with `Coins:pay(player, n)` (Coins.luau line ~84; check what it plays and whether the HUD
   counter jumps) at the reveal's burst or hand beat; an empty-but-coins box plays as a Common
   with coins rising (MarkedBoxView: a few coin copies from `Coins` art, `CoinSpecs.Piles`).
   Every action answers: the coins' own sound as they land in the bank.
3. Somebody's stuff in most units (D-136's `Deal.StuffShare` 0.5 of empty units, Deal.luau ~367,
   read from the pick): now most units, a box unit too (stuff against a wall, the box clear of
   it: `DealSpot.stuffIn` then the box with `taken`). Keep `tests/stuffdeal.spec`'s fingerprint
   rule: no new draw that moves what a seed lays; update the fingerprint deliberately.
4. Battery (`layBattery`) stays loose (a tool for the torch, picked up on the floor). Decide.
5. Prove in Play on seed 2000013 (STUDIO.md "Opening many doors fast"): Unit301 had 2 coins and
   nothing else; Unit312 a padlock and 3 coins; Unit319 the skates and 2 coins.
**Acceptance:** checks green; in Play a unit's coins come only in its box and reach the bank on
the open with a sound; most units show somebody's stuff; OWNER.md has two-player steps.
**Read first:** ROADMAP B-03b; D-211, D-136; `src/server/Deals.luau` (grep `layCoins`,
`layStuff`, `layBoxed`); `src/server/MarkedBoxes.luau`; `src/server/Coins.luau` (grep `pay`).

## Queue (next sessions, the owner's ten-ticket order)
0. **B-04, B-05** (ROADMAP, D-205); then S3-03 Cut Free (it owns Studio's "CutFree"
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
   content representation" (a find's mesh or texture; check which); the reveal untested with two
   players and with a laid (full-hands) find; Rojo's duplicate modules; a dropped find bumps a
   walking player (D-182); rbxassethash warnings in Play; the Packrat's dead Slots entry and
   S2-06b1's way home; the Mannequin's pose onto `Rig.luau` (D-176); the watch bar's empty
   panel; S1-07a, S2-02b to d4, S2-03b, S2-05a, S2-07a1 to b2 leftovers; unseen S1-10d1-3.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
