# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 57 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2d3b, a clear floor and out again, is done** (D-067), which finishes L-13b2d3. The deal
  lays nothing where you land under a top's hole (3 studs across, from the door's line to 0.9
  behind the hole's middle) nor where the top's cut-out panel falls (`DealSpot.landing`,
  `unit.fallen`; Lune checks over both unit sizes, 300 unit numbers, with and without a note).
- **A saw's hole now deals the unit it opens** (its top, or the unit a wall's hole leads into),
  as a lifting door does (before, its contents appeared round you when you lifted the door).
- **A padlocked door's Lift from inside says "Saw a wall"** as it rattles, not "Padlocked".
- **Verified in Studio** (walked floor, Unit 102, as a player): sawed its top and Output dealt
  it (a boombox, at the back, off the landing and the panel); dropped in under the hole's middle
  onto bare floor; Lift padlocked rattled and flashed "Saw a wall"; unlocked from the server,
  sawed the wall into Unit 104 (dealt a saw as the hole went through, clear of every kept spot);
  Lift heaved the door up and I walked out. Not checked: a friend's cut, a small unit, a phone,
  how the foot in the fallen panel looks (captures were black). Those are in OWNER.md.

## Next task: L-06b1 The halls as a map keepers walk
The moment it serves (L-06b2 on): you slam a door and, two halls off, something turns and comes
the shortest way. This ticket is the map it walks, pure, with Lune checks; nothing on screen yet.
1. Owner test results first, if pasted (`OWNER.md`'s L-13b2d3b and L-13b2d3a sections).
2. Read Brix's Pathing contract (`docs/FRAMEWORK.md` says where) and what `Floor` already gives:
   hall pieces, their ends, each unit's doorway.
3. Build the floor's walk graph from `Floor`: hall pieces joined end to end, each unit's doorway
   a link that is shut while its door is down. No crawl holes, no tops (keepers can't use them).
4. Shortest trips by A* in the shape of Brix's Pathing: `length`, `advance`, and a `route` a
   keeper keeps between steps that plans again when a door changes.
5. Lune checks on seeded floors: Brix's Pathing promises hold; no trip crosses a wall or a shut
   door; a step along a warm route allocates nothing.
**Acceptance:** checks green; the new spec covers seeded floors of every plan; CODEMAP has the
module; any number the GDD doesn't give is a default listed in OWNER.md.
**Read first:** ROADMAP L-06b (the ticket and its four parts); DECISIONS D-064; `docs/FRAMEWORK.md`
(Pathing, Reach, Zone); `src/shared/Floor.luau` (Grep its exported types, then line ranges);
`tests/floor.spec.luau` (how seeded floors are checked); the GDD's tech plan section (docs tools).

## Queue (the next run's order, from ROADMAP)
1. L-06b1 to L-06b4, the keepers' brain (D-064); no escape has been tried against a keeper
   yet. L-12c needs L-06b. Then L-14; L-07, L-08, L-10, L-09.
2. **Look, waits on `OWNER.md`:** landed, one foot stands in the fallen panel (ROADMAP polish).
3. **Check, small:** Climb down or Drop down while lying behind a sawn hole (a small unit) slides
   your body across the hole on the way to the edge; refuse it there or go round.
4. **Look, small:** from a friend's view, dropping in from behind the hole lunges you toward the
   door before your legs go down; the landing crouch dips your feet 0.2 under the floor.
5. **GDD, small:** its ladder line still says open mesh tops you run across (D-058/D-059 closed
   them, the crawl steered); update it (a Claude Doc: the docs tools).
6. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders:crawling` says who's up).
7. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
8. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
9. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
10. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes.
11. L-06b's keepers hear doors, the keypad, a dropped tool, the saw (`kind`), a crawl, the
   ladder and a drop in (D-059, D-066); see a torch; treat a holed wall as solid; can't reach
   the tops. A keeper can now be dealt by a saw's hole, not only a lifted door (D-067).
12. **Check:** Output's six "rbxassetid://203785492 ... Asset type does not match" per Play, and
   24 lines of "rbxassetid://105182707303690 ... being generated" after a wall was sawn.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
