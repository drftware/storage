# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 94 (overnight run, 9 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08d done (D-106): the climb ends.** Nobody left climbing (all kept or watching) ends it as
  a loss; the car leaving the top (a stand-in, floor 3: `Climb.Top`) with friends aboard ends it
  as an escape. One screen on everyone's (`EndView`, from `ClimbEnd` on Workspace): a wipe's
  black, the world quiet, two doors far off, "Kept" slamming down, the photos greyed with the
  floor each was lost on, "Floor N · m:ss", "Again"; an escape's white on the cable's knock, the
  bell, "Made it". The server clears the climb under it (`ClimbEnds`: `Climbs:finish`,
  `Watching:release`, every character taken). "Again" waits for everyone or 10 s after the
  first press, then a fresh floor 1 with everyone side by side (`ClimbEnds.go`, the owner's
  lobby replaces it). Watching's "Alone" let-in is gone.
- Verified in Studio on seed 7 (a real catch, the top ridden alone, left behind into a wipe;
  Again by mouse and Enter; a carried saw went with the floor, none in the new floor 1: the
  climb's tools are now cleared after its floors go, as at a hand-off). Two players, a phone,
  the sounds: `OWNER.md`.
- Studio: nothing imported; left in Edit, seed 7, floor 1; `DevRideHold` unset; quality back on
  Automatic. The Mac's screen was locked: Studio only drew with `caffeinate -d -u` running (a
  40-minute timer that ends on its own; STUDIO.md, "A locked Mac stops Studio drawing").

## Next task: L-15 Keepers hear the rest
The moment: you punch the keypad, drop a tool, saw, crawl, set the ladder or drop into a unit,
and somewhere down the hall a keeper turns toward the sound, as Lethal Company's Eyeless Dogs come
to any noise. Noise is a choice with a price.
1. Owner test results first, if pasted.
2. Read ROADMAP L-15, then D-092 (how bubble wrap is heard: `Keepers:hear(at, reach, why)`), and
   skim D-059 and D-066 for where crawls and drop-ins happen.
3. Each noise calls `Keepers:hear` at its spot with a reach that matches what players hear
   (the sound rows' `Reach`, as `Doors.acted` and `Wraps` do): the keypad's beeps and the wrong
   code's buzzer (`Elevators.acted`), a tool dropped (`Slots`), the saw at work (`Saws`), a crawl
   through a hole or along the tops (`Crawls`), the ladder raised or knocked flat (`Ladders`),
   a drop into a unit. Feel numbers in shared Config with a comment each.
4. Same ticket: a trapped keeper's every blow stops printing to Output (one line per trap is
   enough), and a crawler's feet sit within `Wrap.Under` (3) so crawling over bubble wrap pops it.
5. No new keepers and no lobby. Every noise already has its own sound on screen; check it does.
**Acceptance:** checks green; Lune covers any new pure numbers; in Studio, each noise turns a
keeper that's in reach (Output names what it heard) and none that's past it; Output clean but
the known asset lines. Feel with friends goes to `OWNER.md`.
**Read first:** ROADMAP L-15; D-092; `src/server/Keepers.luau` (`hear`, `hearHorn`);
`src/server/Wraps.luau` (its `hear` call); `src/server/Elevators.luau` (`acted`);
`src/server/Slots.luau` (drops).

## Queue (the next run's order, from ROADMAP)
1. L-08e (the start, in the lobby) waits for the owner's lobby plan (Nov 11).
2. L-16a and L-16b, the fix pass before friends play; L-16c the roof crawl made smooth.
3. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
4. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.
5. Seen: a ladder stood on a floor when it's cleared should go with it (untested); anyone still
   in the car 6 s after it opens is shut in (`OWNER.md`'s L-08a decision 2); watching a friend
   ride doesn't draw their shaft (ROADMAP polish); DevCorridor's "Walk a floor" sign keeps the
   old floor's number after "Again" (Studio only); an asset in the place,
   `rbxassetid://120448020095820`, started printing "content representation is being
   generated" tonight (not in the repo).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
