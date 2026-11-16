# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 198 (Cut Free sold and used, on the server) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-03 split (ROADMAP): S3-03a1 done, S3-03a2 the button next, then S3-03b, S3-03c.
- S3-03a1 (D-220): `Products.Rows.cutFree` (title `Cut Free`); the save is at version 3
  (`spares`); `CutFrees` (server system) takes `Remotes.CutFree` and the watch bar's ask
  (Watching's `onCutFree`), spends a spare or prompts, and on Purchasing's `granted` frees you:
  wrapped, the film rips and the door hauls itself up (KeptPlayers' `cutFree`); left behind or
  carried up, you stand in the car once it has reached the next floor (Watching's `cutFree`,
  Climbs' car spot). A grant that lands once you're free waits as a spare.
- Seen in Studio Play: the server starts clean, `Remotes.CutFree` has `On` true, a made-up
  receipt (`DevReceipt:Invoke({ offer = "cutFree" })`) printed `granted cutFree` then "waits in
  their save". Not yet run: a catch freed by Cut Free, the car arrival. Play stopped.
- Rojo synced `CutFrees` twice into ServerScriptService (the known duplicate gotcha).
- No "Cut Free" product exists yet: OWNER.md "Make the Cut Free product".

## Next task: S3-03a2 The Cut Free button on the caught screen
ROADMAP S3-03a2. The moment: wrapped in the dark, one warm button beside Bang; press it, pay,
and the film rips off you and the door hauls up on the hall's light.
1. CaughtView (`src/client/CaughtView.luau`): a Cut Free button that comes up with Bang
   (`showButton`, `placeButton`; on a phone left of Bang, smaller, never under the right thumb),
   only while `ReplicatedStorage.Remotes.CutFree` has `On` true (watch the attribute). A press
   springs it (as Bang's `PRESS`), plays a click, fires the remote (nothing carried), and dims
   it for `CutFree.AskEvery`; it fades with Bang as you're let out (`finish`). One word, "Cut
   Free"; no price text (Roblox's prompt shows it), no rule text.
2. WatchView: its Cut Free button (lines near 243 and 954) shows on the same `On` flag instead
   of Studio only; it can keep asking through the Watch remote (Watching hands it to CutFrees).
3. Feel numbers in `src/shared/CutFree.luau`, each with what it does to the player.
4. Prove in Play: get caught (STUDIO.md "Testing a catch anywhere from the MCP":
   `ServerStorage.CatchTest`, a stand-in friend first so it isn't a wipe), wait for the button,
   press it (in Studio with no product it frees for nothing): the rip, the door rising, walk
   out. Then a spare: `DevReceipt:Invoke({ offer = "cutFree" })` while free, get caught, press:
   freed with no prompt. Before any Play test, count Client `RenderStepped` frames: 0 means
   Studio isn't drawing. Capture only what you must judge, at small scale.
**Acceptance:** checks green; the button seen at phone size; a caught player freed by it in
Play, the door up; a spare spent with no prompt; OWNER.md steps for the real purchase.
**Read first:** ROADMAP S3-03; DECISIONS D-220 (grep `^## D-220`); `src/shared/CutFree.luau`;
`src/client/CaughtView.luau` (grep `function`, lines 48-75 and 120-240); `src/client/WatchView.luau`
(grep `cutFree`).

## Queue (next sessions, the owner's ten-ticket order)
0. S3-03b Free a Friend, S3-03c Free Everyone before the results (and playing alone), then
   S3-04 The counter's shop and wrap colours (gifts wait on `OWNER.md`).
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. B-05b2b polish: a guard's box still hides wholly round the bend. L-08e3c, L-14b2d wait on
   `OWNER.md`; R-01 later. A GDD section costs ~15k context: docs `read` with `kind: "search"`,
   `text`, then `blocks` on just the part needed.
5. Small: Play logs "rbxassetid://203785492 failed: Asset type does not match"; a find's copy
   out of a box logged "rbxassetid://73742731927159 failed"; `ConfigService: Config value not
   found` lines; the reveal, coins and notes untested with two players; Rojo's duplicate
   modules; a dropped find bumps a walking player (D-182); rbxassethash warnings; the Packrat's
   dead Slots entry; the Mannequin's pose onto `Rig.luau` (D-176); the watch bar's empty panel;
   S1-07a, S2-02b-d4, S2-03b, S2-05a, S2-07a1-b2 leftovers; unseen S1-10d1-3; box words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
