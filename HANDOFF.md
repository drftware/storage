# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 44 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-12b2 is done** (D-053): sawing the hole. `Saws` (server) puts a Saw button each side of
  every wall two units in a row share, at the hole's front third; only someone carrying a saw
  sees it (ToolView). Hold R / R2 for 4 s with the saw in hand ("Hold the saw" in your other
  slot): checked like Cut, and again before `CrawlHole.saw(from, into, at)` cuts it. `SawView`
  (every screen) plays the motor and blade (heard 200 studs), draws the hot line round the cut
  with sparks, buzzes the sawer's view; the panel tips over and clangs flat, jolting anyone near.
  Rules and numbers: `CrawlHole/Sawing` (pure, `tests/sawing.spec.luau`). `Saws.sawing` fires at
  the motor's start and the panel's fall, with its reach, for keepers. `DealSpot` keeps the deal
  off both side walls' hole spots. A saw now lies by the test hall's spawn.
- **Verified in Studio** (test hall, a computer view, driven by `InputHoldBegin`): cut 103 into
  105, 106 into 108 and the small 109 into 111; wall swapped and tagged, colliders split, both
  buttons gone, panel at rest where the server laid it; a 2.2 s hold stopped clean; "Hold the
  saw" with it in slot 2; the computed hole matched the real cut edge to 0.01. Screens:
  mid-cut line and the use pose read well after one retune. Not seen: the phone (the Device
  Simulator can't be set from a script), a friend's view, the sounds (nobody can listen).
  Studio left in Edit, Play stopped, simulator off. No owner results came (the overnight run).

## Next task: L-12b3 Crawling through
The moment: the keeper's footsteps behind you, you drop to the hole, scrape through on your
belly, and stand up in the next unit while it stands in the one you left.
1. Owner test results first (`OWNER.md`).
2. Read `Saws` (where each side's button stands, its checks) and decide where Crawl lives: the
   same spot each side of a holed wall (`CrawlHole.Tag`), likely the same system grown to own
   a pair's whole life (Saw, then Crawl through), or a sibling.
3. Server: range, inside the unit you crawl from, rate, the wall holed; move the body through
   (a short server-driven move, as DOORS' and Pressure's vents: crouched, low, about a second),
   never through a wall, never with a keeper's height (6.3 can't fit the 2.6 hole).
4. Feel: the camera drops low, a scrape of steel as you pass the cut edge, the view rising as you
   stand; the button one verb ("Crawl"). A friend sees you go down and through.
5. Drop the test hall's two ready-cut holes (`DevCorridor`'s `DEV_HOLES`): the saw makes them.
**Acceptance:** checks green; in Studio, Crawl through from 106 into 108 and back after sawing it;
refused from the hall or a step away; Lune checks for any new pure rule; owner's checks in
`OWNER.md`.
**Read first:** ROADMAP L-12b3; `src/server/Saws.luau`; `src/shared/StorageUnit/CrawlHole/init.luau`
(Tag, frame, Rect); `src/shared/StorageUnit/CrawlHole/Sawing.luau`; `src/client/SawView.luau`;
`docs/STUDIO.md` ("Driving a ProximityPrompt").

## Queue (the next run's order, from ROADMAP)
1. L-12b3 (crawling through). L-06b the Mannequin hunts **waits on Brix**: ENG-07a/b (a chase in
   a place) aren't built, and this repo never edits Brix; a Brix session first. L-12c the hole
   trap needs L-06b's keepers. Then L-13, L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. **Check, small:** G is both a door's Slam and Drop (ToolView binds G since L-11b): with a tool
   in hand, does G at an open door slam, drop, or both? Give Drop its own key if it clashes.
4. L-06b's keepers stand at `Deals.dealt`'s place, hear doors on `Doors.acted` (a Cut carries 40
   studs), the keypad on `Elevators.acted`, a dropped tool on `Slots.changed`, the saw on
   `Saws.sawing` (200 studs while it runs); keepers with eyes see a torch
   (`Flashlights.switched`, GDD); hand `Deal.open` the awake now.
5. **Check:** floor 1's laying peaked at 59 ms in a frame in session 43 (11.5 and 5.1 ms this
   session). And Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not in our code; find what asks for it (the place, a plugin).
6. Studio traps (docs/STUDIO.md): the test hall and the walked floor share unit names (pick by
   Z); a Client `execute_luau` has its own `require` (edit, sync, Play again); prompts pressed by
   script need the camera on them; test hall 105 and 108 are padlocked.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
