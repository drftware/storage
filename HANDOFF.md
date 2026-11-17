# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 244 (four make a Gold, the big animation, D-299) ·
**Checks:** green for this commit, proven in a clean worktree (the shared checkout is red only from
the find run's uncommitted GooBall) · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  a Gold made on the server (D-298) and now its show (S5-03c3b2, D-299).
- The show (`BoxPanelView`: `makeGold`, `orbit`, `reveal`, `landGold`, `goHome`, `goldTook`,
  `applyMade`; numbers in `Home/Gold`'s `Show`): Gold over Sell with a shine on a card with four;
  press it and the panel dims, four pictures go to a ring with rising chinks, swirl in turning
  gold, flash, the Gold big with rays and its name, then it flies onto its card. Verified in
  Studio Play with real clicks, three Golds of Teddy: a new card, a bumped x2 and x3, the card
  emptied by the last four; Output clean. Captures `docs/art/S5-03c3b2-*.jpg`.
- Fixed after the Studio pass, unseen: the card emptied by the four jumped to the grid's top-left
  until the flash (its place number went to 0). The refused path (`goHome`) is unseen too.
- Studio: `ServerStorage.ShelfTest:Invoke(player, key)` keeps a find; the box opens from a Client
  `prompt:InputHoldBegin()` on `Unit1`'s `JobBoxSpot` with the camera on it; click with
  `user_mouse_input`'s `instance_path` ("Finds.Teddy.Verbs.Gold"). The test save now has three
  Gold Teddies and no Teddy. Measure a dim, don't eyeball it (STUDIO.md).
- Stage only your own paths: the find run shares this checkout.

## Next task: S5-03c3b3 A Gold on the shelf and in your hand
The moment: your Gold Teddy, taken out, sits in your hand shining gold, and on your shelf it
catches the bulb's light; take it up the climb and it's kept at the gate as a Gold.
1. Server: let a Gold's key come out by Take and Shelf (`JobBoxes`' take handler refuses all but
   Sell for a Gold now); `Slots` and `Shelves` hold "Teddy:Gold" as they hold any find, its row
   from `Gold.base`.
2. Draw it gilded wherever the find's model is made: the held tool (`ToolView`), the shelf
   (`ShelfView`), the hand wells (already ToolPicture). Share one gild (ToolPicture's) from shared.
3. Show Take and Shelf on a Gold's card (`paintVerbs`); the price and sound stay its find's.
4. Kept at the gate: a Gold carried aboard comes home as a Gold (where finds are kept, D-293).
5. Studio Play: take a Gold Teddy out, hold it, shelve one; capture `docs/art/S5-03c3b3-*.jpg`.
**Acceptance:** check green; a Gold comes out to the hand and the shelf, gold everywhere it's
drawn; seen in Studio Play, Output clean.
**Read first:** ROADMAP S5-03c3b3; D-298; `src/client/ToolPicture.luau` (`gild`);
`src/server/JobBoxes.luau` (the take handler); `src/server/Slots.luau` (`unbox`);
`src/client/ToolView.luau` (where the held model is made).

## Queue (next sessions, the owner's ticket order)
1. S5-03c3a2 a cracked find sells first at half, one off `chipped` (small; F-G1e5e is in); S5-03d-h;
   S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4);
   F-G1b4b the hat spent. S5-03d builds on D-293: a box find is never kept at a gate yet.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
