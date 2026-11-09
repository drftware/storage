# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 56 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2d3 was split in two; L-13b2d3a, Drop in, is done** (D-066). Lying at a sawn hole's edge
  with your head out over it you get a Drop in button (F, pad B) three studs down the hole, and
  that unit's Drop down hides while you do. Pressed, you tip up, your legs slide down the hole's
  middle, you hang a beat under the ceiling, fall with your arms going up and land in a crouch on
  the unit's floor facing its door: 0.96 s, the steel's ring, a thud and a jolt, heard 45 studs
  (`Ladders.climbed` "In"). The move is pure (`Tops.dropIn`, `inArms`, `inCues`, `atHole`) with
  Lune checks: head under the 14-stud ceiling, body through the hole clear of its cut edge.
- **Verified in Studio** (test hall Unit 101, as a player): picked up the saw and ladder, leaned,
  climbed, sawed the top, crawled to the hole's edge (Drop in on, Drop down off), pressed F
  looking at the floor below, landed standing under the hole's middle; head never above 13.66;
  the server didn't put me back. Not checked: the button's look (captures don't show prompts), a
  friend's view, a phone, a small unit, getting out. Those are in OWNER.md or the next task.

## Next task: L-13b2d3b A clear floor, and out again
The moment: you land in a crouch in a shut unit, nothing under your feet but concrete, the door
a step ahead, and have to get out before the keeper comes to the thud.
1. Owner test results first (`OWNER.md`'s L-13b2d3a section: the hang, which way you land, when
   the button shows).
2. The deal keeps the floor under every unit's hole clear, as `DealSpot.Hole` keeps the wall
   holes' spots: the landing is under the hole's middle (`TopHole.Rect`), a body 2 across by 1
   deep plus a step toward the door. A Lune check over real floors.
3. In Studio, drop into a dealt unit: nothing under you. Check your left foot against the fallen
   panel's corner (the panel lies 0.4 from the landing's middle); if it shows, slide the art's
   panel aside in `art/tophole` or note it for the owner.
4. Out again, each tried from inside a unit you dropped into: the door rolled up from inside
   (Open and Lift were in reach from inside Unit 101, untried), sawing out sideways, a friend
   cutting the lock. A padlocked door from inside refuses naming the fix.
**Acceptance:** checks green; a Lune check for the clear floor; in Studio drop into a unit with
boxes dealt and leave by the door; what the MCP can't check goes to OWNER.md.
**Read first:** ROADMAP L-13b2d3b; DECISIONS D-066; `src/shared/DealSpot.luau` (Grep `Hole`);
`tests/dealspot.spec.luau` (Grep `Hole`); `src/shared/StorageUnit/ShutIn.luau`;
`src/server/Doors.luau` (Grep `inside`).

## Queue (the next run's order, from ROADMAP)
1. L-13b2d3b, then L-06b1 to L-06b4, the keepers' brain, built here and waiting on nothing in Brix
   (D-064). None of the escapes has been tried against a keeper yet. L-12c needs L-06b. Then L-14;
   L-07, L-08, L-10, L-09.
2. **Check, small:** Climb down or Drop down while lying behind a sawn hole (a small unit) slides
   your body across the hole on the way to the edge; refuse it there or go round.
3. **Look, small:** from a friend's view, dropping in from behind the hole lunges you toward the
   door before your legs go down; the landing crouch dips your feet 0.2 under the floor.
4. **GDD, small:** its ladder line still says open mesh tops you run across (D-058/D-059 closed
   them, the crawl steered); update it (a Claude Doc: the docs tools).
5. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders:crawling` says who's up).
6. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
7. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
8. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
9. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes.
10. **Look, small:** your torch's head is a flat black disc from behind; a faint rim? Owner's call.
11. L-06b's keepers hear doors, the keypad, a dropped tool, the saw (`kind`), a crawl, the
   ladder and a drop in (D-059, D-066); see a torch; treat a holed wall as solid; can't reach the tops.
12. **Check:** Output's six "rbxassetid://203785492 ... Asset type does not match" per Play.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
