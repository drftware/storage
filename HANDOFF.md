# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 98 (the owner's Nov 11 play; L-16c) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-16c done (D-110): the tops glide.** Your view sits 1.5 studs up your lying body, and the
  body turning after your mouse swung it sideways; you nearly stopped while turning; each pull
  surged ±55%. Now `Tops.step` turns the body about your eye (`Tops.Eye`), you move where you push
  at once, the surge is ±10%, LadderView's head dip and sway are halved, and the server's crawl
  check (`Ladders` `checkCrawl`) allows for the hips' swing. Lune covers it (`tests/tops.spec`).
- **Reaching through doors (D-110):** `ShutIn.reaches` and `RollUpDoor.keepsApart`; `Slots`
  refuses a pick-up through a shut or peeked door, `BehindDoors` hides that Pick up on screen.
- **The floor's flicker (D-110):** a junction's floor ran under units' fronts at the same height;
  `FloorBuilder.unit` lifts the unit's drawn floor 0.03.
- Verified in Studio: a quarter turn mid-crawl moved the eye 0.4 studs sideways in all, 4 to 5
  studs a second, no put-backs; the tool behind 101's door hidden, refused when forced, hidden
  under a peek, taken once open; 106's floor at 0.03. Feel on a live server and phone: `OWNER.md`.
- New tickets from the owner's notes: L-19 (every button in the world small and modern, a door's
  laid out where your hand goes) and L-20 (the inventory wheel; three slots, six bought).
- Studio: left in Edit, nothing imported.

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
1. L-19a one look for every button in the world; L-19b a door's buttons where your hand goes.
2. L-20a the inventory wheel and three slots (L-20b, six bought, waits on the store).
3. L-17 every button on a phone at once; then L-09a the first run with friends, floors 1 to 3.
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
