# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 99 (L-16b1) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-16b split in two** (each item needs its own Studio check): L-16b1 the tops (done), L-16b2 a
  press on arrival counts (next).
- **L-16b1 done (D-111).** A landing's crouch, off a front or in through a hole, bends the knees
  so the feet stay on the floor (`Tops.landDip`, `Tops.crouch`, LadderView's `crouch` on every
  lander); straight legs had sunk them 0.63. Climb down and Drop down are ignored while their
  slide would take you over a sawn hole (`Ladders` `slideClear`), no words (owner: "it's common
  sense... no overly verbose"). Door buttons are hidden on a crawler's screen and ignored by the
  server (`Door.ButtonTag`, `Ladders:crawling` in `Doors`).
- **New `ButtonReach`** (client): hides a button by its reach for several reasons at once.
  ToolView's Lock/Saw/Lean gates now go through it ("Hand"); LadderView adds "Tops".
- Verified in Studio: the crouch on the default avatar (feet stay put at 0.4 and 0.6 down, knee
  bends forward). **Not yet in Studio:** the door buttons hidden up top, and the hole check.
- Studio: left in Edit, nothing imported.

## Next task: L-16b2 A press on arrival counts
The moment: you sprint into a unit and press Saw at the wall, or reach the ladder and press
Climb, and it just works, first time, though the server still sees you a few studs back.
1. Owner test results first, if pasted.
2. **L-16b1's Studio checks first** (the tops recipe, docs/STUDIO.md): lying at Unit 101's front
   edge, no door button shows (Open/Slam/Peek; with a padlock in hand, no Lock either), and they
   come back once you're down; lying behind a sawn hole, Climb down and Drop down do nothing.
   Fix anything that fails before going on.
3. Read ROADMAP L-16b2 and D-085. One pure helper (Lune first): judged where the server sees you
   or `Crawling.Lag` (0.4 s) on at the speed it sees you moving, as `Crawling.counts` does, which
   then uses it. Apply it where a press checks where you stand: `Saws` (reach and `inside`),
   `Ladders` (Lean, Climb, Climb down's reach, `slideClear`), `Doors` (reach; `sideOf` for Cut and
   Lock). Only where a press can be lost: measure first (Studio, a run in at full speed).
4. Each fix keeps its feedback; nothing new on screen.
**Acceptance:** checks green; Lune for the helper; in Studio, a press made the moment you arrive
counts for Saw, Climb and Lean, Output clean but 203785492. Two players go to `OWNER.md`.
**Read first:** ROADMAP L-16b2; DECISIONS D-085; `src/shared/StorageUnit/CrawlHole/Crawling.luau`
(`counts`); `src/server/Saws.luau` (the press checks near `ladders:crawling`);
`src/server/Ladders.luau` (`inReach`, `climbUp`, `climbDown`, `lean`, `slideClear`);
docs/STUDIO.md "Getting a player up on the tops from the MCP".

## Queue (the next run's order, from ROADMAP)
1. L-19a one look for every button in the world (fold `ButtonReach` into it); L-19b a door's
   buttons where your hand goes.
2. L-20a the inventory wheel and three slots (L-20b, six bought, waits on the store).
3. L-17 every button on a phone at once; L-16d the tops still jitter on a computer (before
   friends); then L-09a the first run with friends, floors 1 to 3.
4. L-08e (the start, in the lobby) waits for the owner's lobby plan. L-18 optional.
5. Seen: a ladder stood on a floor when it's cleared should go with it (untested); anyone still
   in the car 6 s after it opens is shut in (`OWNER.md`'s L-08a decision 2); watching a friend
   ride doesn't draw their shaft (ROADMAP polish); DevCorridor's "Walk a floor" sign keeps the
   old floor's number after "Again" (Studio only); the ladder can't be knocked flat yet, so that
   noise waits for whatever knocks it (D-107).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
