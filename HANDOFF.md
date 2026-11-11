# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 96 (overnight run, 11 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-16a done (D-108): in hand and caught.** One client `Joints` module finds and turns either
  kind of avatar joint (players' arms are `AnimationConstraint`s) for FlashlightView, HornView,
  CrawlView, LadderView and KneelView, so a friend's torch arm rises. A catch ends a climb or
  crawl on the server (`Prompts.wrapped` in Ladders' and Crawls' steps) and the caught screen
  lets go of the body at once (LadderView, CrawlView on `Kept.Attribute`); CaughtLunge hands
  back Custom, never a crawl's Scriptable camera. G at an open door is Slam (ToolView passes the
  key to a shown prompt on it); a click on an active GUI button is never a use (HornView,
  `GetGuiObjectsAtPosition`). DoorSounds, HallLights, UnitLights and KneelView prime their
  recordings. KeeperView binds a body that arrives in pieces once whole; Keepers finishes a body
  before parenting it. Studio-only `ServerStorage.CatchTest` catches you anywhere (docs/STUDIO.md).
- Verified in Studio: your own arm raised via `Joints`; caught on the ladder and mid-crawl, kept,
  cut free by a stand-in, walking; Slam over Drop; a slot click blowing nothing; Output clean but
  Roblox's 203785492 (traced: not the game's). Not reproduced either way: the late first play,
  the KeeperView race. A friend's arm, two players, the phone: `OWNER.md`.
- Studio: nothing imported; left in Edit.

## Next task: L-16b The tops and arriving
The moment: coming down off the tops, dropping in, and pressing a button the instant you arrive
all just work, first time, with a friend watching.
1. Owner test results first, if pasted.
2. Read ROADMAP L-16b. Then each item, smallest first:
   - Climb down or Drop down while lying behind a sawn hole slides you across it: the move's
     slide from where you lie (`LadderView.rootAt`, `m.from:Lerp`, `Leaning.Slide`) must go round
     the hole, or the button refuse there ("Hole in the way").
   - A friend's drop-in lands 0.2 under the floor on other screens (`inPose`, the "In" move's
     stand height for a friend vs your own).
   - Crawlers refused a door's buttons and the ladder (`Ladders:crawling` and its callers).
   - A press made as you arrive is judged where the server saw you a moment ago (D-085): Saws,
     Ladders (Lean, Climb, Climb down) and a door's Cut and Lock allow for it as `Crawling.counts`
     does (where it sees you, or 0.4 s on at your speed). A pure helper gets Lune first.
3. Each fix ships with its feedback; nothing new on screen without a sound and motion.
**Acceptance:** checks green; Lune for each pure change; in Studio each item checked on floor 1
(the tops recipe and "Testing a catch anywhere" in docs/STUDIO.md), Output clean but 203785492.
Two players go to `OWNER.md`.
**Read first:** ROADMAP L-16b; DECISIONS D-085; `src/server/Ladders.luau` (`climbDown`,
`dropDown`, `crawling`); `src/client/LadderView.luau` (`rootAt`, `inPose`);
`src/shared/StorageUnit/CrawlHole/Crawling.luau` (`counts`); docs/STUDIO.md "Getting a player up
on the tops from the MCP".

## Queue (the next run's order, from ROADMAP)
1. L-08e (the start, in the lobby) waits for the owner's lobby plan (Nov 11).
2. L-16c the roof crawl, smooth (owner's words in ROADMAP).
3. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
4. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.
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
