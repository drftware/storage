# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 55 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2d2c is done** (D-065): a sawn top's hole is on the tops' map the moment it goes through
  (`Ladders:holed`, called by Saws; `Tops.Map.holes`). Nobody crawls over it; your head goes out
  over its edge to look down. Anyone lying across it glides off onto the steel (`Tops.settle`, the
  server's `FixAttribute`, a 0.25 s glide on screen, the steel's ring and a jolt). The ladder offers
  only spots clear of holes and not rolled across one (`Tops.pathClear`): on a sawn top, one, by
  the ladder; a small unit's first spot moved a quarter stud out (`Leaned.holeClear`).
- **Verified in Studio** (test hall Unit 101, as a player): sawed with my feet over the spot and
  glided 1.75 studs off; the map's hole matched the art's to a thousandth; crawled at the hole for
  5 s and stopped at its edge, view over it, looking down at the floor and panel; the server never
  put me back. A lit bulb shows from the tops through the hole at Level21 (at Automatic graphics it
  lit the whole top through the steel: OWNER.md). Two players and a phone: OWNER.md. The owner
  passed L-13b2d2b's sawing ("looks good").

## Next task: L-13b2d3 Drop in, and out again
The moment: you lie at the hole's edge, torch on the dark floor below, press Drop in and go
through feet first, land in a crouch inside a shut unit, the door at your back, and have to find
your way out before the keeper hears where you went.
1. Owner test results first (`OWNER.md`'s L-13b2d2c and L-13b2d2b sections).
2. Too big for a session? Split it in ROADMAP first (drop in; clear floor and ways out).
3. A Drop in button over each sawn hole, only for crawlers (`Leaned.TopButtonTag`), pressed lying
   at its edge; server checks as `dropDown`'s (crawling, by this hole, rate). Not on an unsawn top.
4. The move, pure in `Tops` as `Tops.drop` is, with Lune checks: over the edge, feet first, arms
   up, through the 2.8 by 2.05 hole without touching its cut edge, a landing crouch inside facing
   the door; under a second; the thud heard (`climbed`, for keepers) and the jolt.
5. The deal keeps the floor under every unit's hole clear, as `DealSpot.Hole` keeps the wall
   holes' spots, so you never land in boxes; a Lune check.
6. Out again: rolling the door up from inside, sawing out sideways, a friend cutting the lock;
   check each from inside a unit you dropped into, refusals naming the fix.
**Acceptance:** checks green; Lune checks for the drop and the clear floor; in Studio drop in
through a sawn hole as a player, land, and get out by the door; what the MCP can't check goes to
OWNER.md.
**Read first:** ROADMAP L-13b2d3; DECISIONS D-059 (the drop off a front) and D-065;
`src/shared/Tops.luau` (Grep `function Tops.drop`); `src/server/Ladders.luau` (Grep `dropDown`,
`holed`); `src/client/LadderView.luau` (Grep `"Drop"`); `src/shared/DealSpot.luau` (Grep `Hole`).

## Queue (the next run's order, from ROADMAP)
1. L-13b2d3, then L-06b1 to L-06b4, the keepers' brain, built here and waiting on nothing in Brix
   (D-064). None of the escapes has been tried against a keeper yet. L-12c needs L-06b. Then L-14;
   L-07, L-08, L-10, L-09.
2. **Check, small:** Climb down or Drop down while lying behind a sawn hole (a small unit) slides
   your body across the hole on the way to the edge; refuse it there or go round.
3. **GDD, small:** its ladder line still says open mesh tops you run across (D-058/D-059 closed
   them, the crawl steered); update it (a Claude Doc: the docs tools).
4. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders:crawling` says who's up).
5. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
6. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
7. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
8. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes.
9. **Look, small:** your torch's head is a flat black disc from behind; a faint rim? Owner's call.
10. L-06b's keepers hear doors, the keypad, a dropped tool, the saw (`kind`), a crawl and the
   ladder (D-059); see a torch; treat a holed wall as solid; can't reach the tops.
11. **Check:** Output's six "rbxassetid://203785492 ... Asset type does not match" per Play.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
