# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 48 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2a is done** (D-057): leaning the ladder and climbing it. Each unit's front has a Lean
  button (R) up by its top edge, left of the door, shown only with the ladder in hand
  (`Tools.LeanTag`, ToolView). `Ladders` (server) takes it from your hand (`Slots:place`) and
  stands it at the 4-to-1 rule; every screen plays the swing, the bang, the fly's rattle and the
  locks' clack (`LadderView`, `Leaning.raise`). Climb (E) is a pressed move the game makes, as the
  crawl's: up the rungs with Roblox's own climb animation, over the edge onto your belly in a spot
  of your own on the wire top (`Leaning.up`, `lying`; 3 spots on an S, 4 on an M), held there by
  your screen (PlatformStand, the `Crawling` collision group) with your view free; Climb down (E)
  ahead of you; Take (F) refused while anyone's on it or up there. Climbers carry `OnLadder` with
  `LadderMove` "Up", "Top" or "Down". Pure numbers in `Tools/Leaning` (Lune, 177 checks), CFrames
  in `Tools/Leaned`. Crawling through a hole with the ladder in hand is refused.
- **Verified in Studio** (Play, the test hall, units 102 and 103, both M): Lean, the raise sampled
  on the client (swing settles by 0.36 s, fly out at 0.85 s), Climb (lying at the spot in 2.0 s,
  the server's "Top"), the lying view and body (`docs/art/L-13b2a-*.jpg`), Climb down (standing in
  the hall, Running), Take (back on the shoulder, walk 12, Lean button back); Output clean. Not
  checked: an S unit in Studio (Lune covers it), the phone, two players, the refusals, sounds
  (picked by loudness, unheard). Studio in Edit, Play stopped.

## Next task: L-13b2b Along the tops and down
The moment: up on the wire in the dark, you crawl along the tops over the units while a keeper
stalks the hall below, round a corner, and drop down behind it.
1. Owner test results first (`OWNER.md`'s L-13b2a section); a "climb steered or pressed" answer
   there may change step 3.
2. Read ROADMAP L-13b2b, D-057 (how you lie up there), D-055 (the tops, `Run.lids`), D-054.
3. Crawling along the tops: pick the precedent and say it in DECISIONS (a crawl you steer with
   the stick, low and slow, as games' crouch-crawls do, or pressed moves from unit top to unit top
   as the crawl's); the view low over the wire, the wire's rattle under you, round a junction's lid.
4. Down: a "Drop down" button at any unit front's top edge while you lie by it; a thud and a jolt
   as you land in the hall. Then Take no longer waits for an empty top (`Ladders.take`).
5. Feedback for each step; keepers can't follow (note for L-06b).
**Acceptance:** checks green; in Studio crawl from one unit's top to the next and round a lid,
drop into the hall; judged at phone size (Galaxy A16).
**Read first:** ROADMAP L-13b2b; DECISIONS D-057, D-055; `src/shared/Tools/Leaning.luau`;
`src/client/LadderView.luau`; `src/shared/Floor.luau` (`runs`, `lids`, by Grep).

## Queue (the next run's order, from ROADMAP)
1. L-13b2b. L-06b the Mannequin hunts **waits on Brix**: ENG-07a/b (a chase in a place) aren't
   built, and this repo never edits Brix; a Brix session first. L-12c needs L-06b's keepers.
   Then L-14; L-07, L-08, L-10, L-09.
2. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
   Take either, as CrawlView's `joint()`; check with two players.
3. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
4. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes (the ladder makes it matter).
5. L-06b's keepers stand at `Deals.dealt`'s place, hear doors on `Doors.acted`, the keypad on
   `Elevators.acted`, a dropped tool on `Slots.changed`, the saw on `Saws.sawing` (200 studs), a
   crawl on `Crawls.crawled` (35), the ladder going up and climbs on `Ladders.climbed` (60, 30);
   keepers with eyes see a torch (`Flashlights.switched`); a keeper's path treats a holed wall
   as solid; keepers can't reach the tops (`Floor.runs`, lids) and never get the ladder's buttons.
6. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not our code; find what asks for it.
7. Studio traps (docs/STUDIO.md): the live deal isn't `floor-deal`'s map; your body shades your
   view's tool; the tops are black on screen (light them from the Client to judge); a leaned
   truss can't be climbed with Roblox's own climbing.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
