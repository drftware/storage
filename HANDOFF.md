# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 183 (S3-02b, D-207; S3-02 done) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-02 done. `Purchasing` takes Roblox's receipts through Brix's Purchases over Saving's saves;
  `Live` holds each product's switch from the experience's configs. Seen in Studio Play with
  made-up receipts (granted once, a repeat ignored, a failed write waited then granted once, a
  switch taking the offer off sale). A real purchase waits on `OWNER.md` ("Buy the test purchase").
- Nothing is on sale to players: S3-03 and S3-04 call `Purchasing:prompt` (answers Brix's listing
  or not-on-sale, `reason` to branch on) and hear `granted`. Their rows go in `Products`.
- The experience has no developer products yet. Nothing was put into the place by hand.
- Studio shows two copies each of `Live`, `Purchasing`, `Feeds`, `Taps` under
  ServerScriptService.Server (a Rojo sync glitch, sources identical; STUDIO.md "Purchases in
  Studio"). If an edit to one of them seems not to run, reconnect Rojo.

## Next task: B-01 The box, built
ROADMAP B-01 (D-205). The moment: a door rolls up on somebody's stuff and one plain taped box sits
there, marked just enough that you know something's inside; you can't tell what. Art only: the
reveal is B-02. Hold it to `art/finds/CRAFT.md`'s bar.
1. Read `art/boxes/README.md` (the moving boxes: the Cardboard bake, the Medium box, the Open
   box with slit tape and flaps up) and CRAFT.md's "The bar", "Things that move or light" and
   "Judging your own work". Build the marked box on `art/boxes`' spec and Cardboard bake (one
   more box in `spec.py`, `scripts/art.sh boxes`), not a new texture set.
2. The marked box: a Medium-size box, tape whole along the top seam, no marker word, nothing
   that tells what's in it. Its four flaps and the tape's two halves are separate parts with
   their hinges in the Specs module, so B-02 can tear the tape and spring the flaps.
3. The open motion as data in the Specs module (the finds kit's way, `art/finds/kit/ease.py`):
   the tape tears from the middle, the flaps spring up and settle past upright. B-02 plays it.
4. The "something inside" cue (default: a faint warm line of light along the tape seam, as
   Fortnite's chests glow): a thin emissive seam part, off by default, in the same FBX.
5. Sounds: the tape tear, the flaps' thump, the cue's soft hum, chosen and named the way the
   finds kit does its own (grep "sound" in `art/finds/README.md`); say each id in STUDIO.md.
6. Look sheets: the box closed in an M unit lit from the hall, in a torch's beam, the seam lit,
   and the open pose; judge at phone size (a 390-wide crop). Import the FBX into Studio per
   STUDIO.md "Importing kit pieces"; say where it lives in HANDOFF and OWNER.md.
**Acceptance:** checks green; `scripts/art.sh boxes` builds it; the sheets read as a plain box
with something in it at phone size; OWNER.md has a "judge the box" item with the sheet paths.
**Read first:** ROADMAP B-01; `art/boxes/README.md`; `art/boxes/spec.py`; `art/finds/CRAFT.md`
(the three sections above); STUDIO.md "Importing kit pieces" (line ~861); D-205.

## Queue (next sessions, the owner's ten-ticket order)
0. **B-02 to B-05** (ROADMAP, D-205), then S3-03 Cut Free (it owns Studio's "CutFree" let-in;
   its rows go in `Products`, prompted with `Purchasing:prompt`), then S3-04 the counter's shop.
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later. A GDD section costs ~15k context: `view`
   with `outline: true` and `from` the heading's id, then `search` with `blocks` on just the part needed.
5. Small, from earlier (ROADMAP and `git log` hold the detail): Rojo's duplicate modules (above);
   a dropped find bumps a walking player (D-182); a take could show the arm first (KeeperView Kit);
   rbxassethash warnings in Play; the Packrat's dead Slots entry and S2-06b1's way home; move the
   Mannequin's pose onto `Rig.luau` (D-176); the watch bar's empty panel; S3-01b's wipe after the
   bring unseen; S1-07a, S2-02b to d4, S2-03b, S2-05a, S2-07a1 to b2 leftovers; unseen S1-10d1 to
   d3, S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
