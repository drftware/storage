# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 47 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b1 is done** (D-056): the ladder. An aluminium extension ladder built the unit's way
  (`art/ladder/`, README), two MeshParts in one 1024² set: `Ladder` (the base, the tool's body)
  and `LadderFly` welded on it by `Tools.prepare` (never anchored), 6.8 studs collapsed, the fly's
  travel 5 for L-13b2 (`Specs/Ladder`: `Bounds`, `Feet`, `Top`, `Travel`, `Rungs`). Its
  `Catalog` row adds `shoulder` (friends see it on the left shoulder, welded to the upper
  torso), `bothHands` (no switching or picking up while it's in hand: "Drop the ladder first";
  nobody can hand you a tool) and `walkSpeed` 12. `Slots` lays and deals tools by
  `Tools.bounds` (both parts); ToolView moves its whole view model (`PivotTo`). Lies in the
  test hall by the spawn. `tests/dealspot.spec` now covers it: wall to wall in a small unit (over
  a hole strip, one place), deeper than the bulb's pool in a big one.
- **Verified in Studio** (Play, floor 1 of seed 7): lies flat by the spawn with the fly in place;
  E picks it up (slot 1, walk 12, welded to UpperTorso, the fly riding); 2 refused with "Drop
  the ladder first"; G drops it flat in front (lowest point on the floor), walk back to 16.
  Seen on the shoulder (`docs/art/L-13b1-carried.jpg`), in your view (`-view.jpg`, dark in your
  body's shadow), and laid at DealSpot's spot in S unit 144 as Deals lays it (`-unit144.jpg`).
  Sounds picked by loudness, unheard. Not checked: the phone, two players. Studio in Edit, Play
  stopped. `Props.Tools.Ladder` lives only in the open place (OWNER.md's save item).

## Next task: L-13b2a Lean it and climb
The moment: a keeper's coming, one friend leans the ladder on a unit's front, it shoots up with a
rattle, and the team climbs out of reach, as Lethal Company's extension ladder.
1. Owner test results first (`OWNER.md`); the "taller floors" decision may change step 4.
2. Read ROADMAP L-13b2a, D-056 and D-055 (the tops), `Specs/Ladder.luau`, the saw's wall button
   (`src/server/Saws.luau`, how a tool's button shows only to its carrier, `Tools.SawTag`).
3. A "Lean" button at each unit's front (the hall side, above the door) for whoever holds the
   ladder; pressed, the server stands it there at the 4-to-1 rule (feet in the hall, top on the
   front's top edge), tweens the fly out `Travel` along its LookVector with the rope's rattle and
   a lock's clack, and gives it a "Take" button; one ladder per front.
4. Climbing: pick the precedent (Roblox's own climbing on an invisible TrussPart along the rails,
   or a pressed "Climb" moving you up as the crawl does), reach the top edge and lie down on the
   wire top on your belly (CrawlView's pose). Keepers can't climb.
5. Feedback for each step: lean, run out, climb (a rung's clank), the roll onto the top.
**Acceptance:** checks green; in Studio a ladder leans on a unit's front, runs out, is climbed
onto the wire top and taken back down; judged at phone size (Galaxy A16).
**Read first:** ROADMAP L-13b2a; DECISIONS D-056, D-055; `src/shared/Tools/Specs/Ladder.luau`;
`src/server/Saws.luau` (the wall button); `src/client/CrawlView.luau` (the belly pose).

## Queue (the next run's order, from ROADMAP)
1. L-13b2a, then L-13b2b (along the tops and down; crawl-only, OWNER.md). L-06b the Mannequin
   hunts **waits on Brix**: ENG-07a/b (a chase in a place) aren't built, and this repo never edits
   Brix; a Brix session first. L-12c needs L-06b's keepers. Then L-14; L-07, L-08, L-10, L-09.
2. **Small:** refuse crawling through a hole with the ladder in hand (`Crawls`; in L-13b2a).
3. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
   Take either, as CrawlView's `joint()`; check with two players.
4. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
5. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes (the ladder makes it matter).
6. L-06b's keepers stand at `Deals.dealt`'s place, hear doors on `Doors.acted`, the keypad on
   `Elevators.acted`, a dropped tool on `Slots.changed`, the saw on `Saws.sawing` (200 studs), a
   crawl on `Crawls.crawled` (35); keepers with eyes see a torch (`Flashlights.switched`); a
   keeper's path treats a holed wall as solid; keepers can't reach the tops (`Floor.runs`, lids).
7. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not our code; find what asks for it.
8. Studio traps (docs/STUDIO.md): the live deal isn't `floor-deal`'s map; your body shades your
   view's tool; the tops are black on screen.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
