# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 49 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2b is done** (D-058, the owner's call): the unit tops are closed in steel. With open
  wire, a torch from the tops showed every unit's code and keepers. Now every unit's top and
  junction lid is the walls' ribbed steel laid flat (`art/unit/parts.py` `top`, part `Top`, was
  `WireTop`), two sheets lapped on the middle channel, rib ends closed; same collider, so the
  ladder's spots didn't move. Landing on it is a steel thud (`Leaning.Sounds.Steel`). M and S
  rebuilt, uploaded over their asset IDs, and swapped into the open place's
  `ReplicatedStorage.Units` (the owner must save the place: `OWNER.md`).
- **Verified in Studio** (Play): all 72 units on floor 1 have the steel top, 13 lids built, Output
  clean but for the known six asset warnings; the view lying on the tops (`docs/art/L-13b2b-tops.jpg`,
  lit by a stand-in torch) shows closed steel, nothing inside a unit. Look sheet
  `art/sheets/unit-tops.png` re-rendered. Not checked: the landing sound by ear, the phone.
  Studio in Edit, Play stopped.
- The ladder ticket is now three: b (done), c the steered crawl and drop, d sawing down into a
  unit (ROADMAP).

## Next task: L-13b2c Along the tops and down
The moment: up on the steel in the dark, you creep along the tops over the units while a keeper
stalks the hall below, round a corner, peek over the edge, and drop down behind it.
1. Owner test results first (`OWNER.md`'s L-13b2b and L-13b2a sections).
2. Read ROADMAP L-13b2c, D-058 (steered, kept on the run), D-057 (how you lie up there), D-055
   (the tops, `Run.lids`), D-054 (the crawl's screen-moved body).
3. Steered crawl: your screen moves your lying body (PlatformStand, the `Crawling` group) along
   the run from the stick, slow (pick a speed, Config with a comment), held on the tops: never
   past a front edge, a back panel or a dead end; round a junction lid. The server checks the
   claimed spot (on the tops, reachable, speed), as `Ladders` checks climbs. Friends see you crawl.
4. Sound: the steel booms softly as you move, heard below (a `Ladders.climbed`-style signal for
   L-06b, say 30 studs). A view low over the steel.
5. Down: a "Drop down" button (not G) at any unit front's edge while you lie by it; a thud and a
   jolt as you land in the hall. Then `Ladders.take` no longer waits for an empty top.
6. Feedback for each step; keepers can't follow (note for L-06b). May split: crawl first, drop
   second, if it won't fit one session.
**Acceptance:** checks green; in Studio crawl from one unit's top to the next and round a lid,
drop into the hall; judged at phone size (Galaxy A16).
**Read first:** ROADMAP L-13b2c; DECISIONS D-058, D-057; `src/shared/Tools/Leaning.luau`;
`src/server/Ladders.luau` (Grep `climbDown`, `take`); `src/shared/Floor.luau` (`runs`, `lids`).

## Queue (the next run's order, from ROADMAP)
1. L-13b2c, then L-13b2d (saw down into a unit). L-06b the Mannequin hunts **waits on Brix**:
   ENG-07a/b (a chase in a place) aren't built, and this repo never edits Brix; a Brix session
   first. Worth doing soon: none of the escapes (saw, crawl hole, ladder, tops) has been tried
   against a keeper. L-12c needs L-06b's keepers. Then L-14; L-07, L-08, L-10, L-09.
2. **GDD, small:** its ladder line still says open mesh tops you run across; D-058 closes them
   and makes the crawl steered. Update that line (a Claude Doc: the docs tools).
3. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
4. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
5. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes.
6. L-06b's keepers hear doors on `Doors.acted`, the keypad on `Elevators.acted`, a dropped tool on
   `Slots.changed`, the saw on `Saws.sawing` (200), a crawl on `Crawls.crawled` (35), the ladder
   on `Ladders.climbed` (60, 30); see a torch (`Flashlights.switched`); treat a holed wall as
   solid; can't reach the tops (`Floor.runs`, lids) and never get the ladder's buttons.
7. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not our code; find what asks for it.
8. Studio traps (docs/STUDIO.md): the MCP's `require` can return stale modules (clone Shared);
   the tops are black on screen (light them from the Client to judge).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
