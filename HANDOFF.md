# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 195 (B-05b2b, D-218) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-05 packed units are done. Seen in Play (floor 3, seed 2000013): Unit302's stacks stand true
  with one dark path; Unit316's Mannequin, woken by a horn, turned at the bend and came down the
  path's middle through no stack; no "bend is off the map" warning.
- Fixed: the box round the bend hid wholly from the doorway. A box with no guard now stands at
  `peek` (`PackedLayout.Peek`), poking 0.4 into the path's line; a guard's box keeps the lure so
  its keeper fits at the path's end (D-218). Passes checks; its look is untested in Studio,
  because Studio stopped drawing frames mid-session (`docs/STUDIO.md`, "When Studio stops
  drawing"). OWNER.md "Walk a packed unit" has the exact steps.
- Two polish lines under B-05b2b in ROADMAP: a sleeper walks through a box in its clearing; a
  guard's box still hides.
- Studio's Workspace `DevFloorSeed` is back to 7 and `DevFloorNumber` cleared, as found.

## Next task: S3-03 Cut Free, Free a Friend, Free Everyone
ROADMAP S3-03. The moment: you're wrapped and carried off; one button on the caught screen
stands you back in the car at the next floor, and a friend can pay to free you instead.
1. Size it first. Three offers is more than one session: split in ROADMAP (S3-03a Cut Free paid
   on the caught screen, incl. while carried up; S3-03b Free a Friend; S3-03c Free Everyone
   before the results) and do S3-03a properly.
2. Read what exists: Cut Free is built and free in Studio (L-07d, L-08c, `CutFreeView`,
   `Watching`'s "CutFree" let-in, which still stands you in the lobby). The paid path goes
   through `Products` rows and `Purchasing:prompt` (S3-02, D-206, D-207): grant only after the
   save, never lost.
3. Cut Free while carried up stands you in the car at the next floor (a decision near
   DECISIONS line 5128 left that to S3-03; grep `that's Cut Free's`).
4. Every press answers: the button's motion and sound, the unwrap, the arrival. No rule text.
5. Prove it in Play with Studio's test purchase (`Workspace` `DevPrompt`, `Purchasing.luau`
   header). Before any Play test, count Client `RenderStepped` frames: 0 means Studio isn't
   drawing and prompts won't show.
**Acceptance:** checks green; the caught screen's Cut Free buys (Studio test purchase), saves,
then frees you into the car; OWNER.md steps for each offer; Play stopped.
**Read first:** ROADMAP S3-03; DECISIONS D-105 and D-206 (grep `^## D-105`, `^## D-206`);
OWNER.md (grep `(D-105)`); `src/shared/Products.luau`;
`src/client/CutFreeView.luau`; `src/server/Purchasing.luau` (grep `function`, `prompt`).

## Queue (next sessions, the owner's ten-ticket order)
0. After S3-03: S3-04 The counter's shop and wrap colours (gifts wait on `OWNER.md`).
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
   A sleeping Mannequin in a packed unit faces the stacks, not the path (Unit316): judge it.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
