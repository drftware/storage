# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 53 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2d2 split in three** (the art in, the cut, the map). **L-13b2d2a is done** (D-062): the
  sawn top's kit is uploaded, prepared and at `ReplicatedStorage.Props.TopHole` (unsaved: the
  owner's "Save the place" line). `TopHole` (`src/shared/StorageUnit/TopHole/init.luau`):
  `saw(unit, at?)` swaps the unit's `Top` for the holed one, lays `TopEdge` and the fallen
  `TopPanel` model (`Panel` + `PanelEdge`; with `at` tagged `TopPanel` and `TopCutAt`), splits
  the top's collider round the hole; `frame(unit)` reads the hole's frame off the unit's top
  (+Z back from the hall, origin under the first channel's middle), `Rect`, `sawn(unit)`.
- **Verified in Studio:** an M (DevCorridor `Unit101`) and an S (`Unit109`) cut from the server;
  looked at from the tops, head out over the hole, and inside, judged at phone size. Owner liked
  the look sheets (L-13b2d1). Nothing saws a top in play yet.

## Next task: L-13b2d2b The cut
The moment: lying on a unit's top with the saw, you hold Saw, the whole floor hears it, the line
crawls round the cut, the panel drops ten studs and clangs, and the hole is there to look down.
1. Owner test results first (`OWNER.md`'s L-13b2d2a, L-13b2c2, L-13b2c, L-13b2a sections).
2. Split in ROADMAP first if it won't fit (likely: the server's button and checks one session,
   the line, sparks and the panel's drop on screens the next).
3. The button: a Saw button over the hole spot (`TopHole.frame`, `Rect`) for a crawler lying by
   it with the saw (either slot; "Hold the saw" in the other, as D-053). The server checks you're
   on that unit's top (`Ladders`' crawler record, `Tops`), in reach, saw in hand, rate; the hold
   ran its time before it goes through; walk off, switch tools, drop down or die stops it.
   Reuse `Saws` and `Sawing` (D-053's hold, keys R/R2, sounds, `Saws.sawing` for keepers) rather
   than a second system: a wall cut and a top cut differ in where, the frame and the result.
4. The line round the cut (`Sawing.line`'s way, on the hole's rectangle laid flat), sparks up top,
   the buzz on the sawer's view.
5. Through: `TopHole.saw(unit, at)`; screens drop the panel ten studs and clang it (SawView's
   fall, with the pose before it fell: see ROADMAP L-13b2d2b's note on the art's `lay`), heard
   floor-wide, the jolt near it.
**Acceptance:** checks green; Lune checks for any new pure rules (the line on a flat rectangle);
in Studio saw a top as a player (lie, hold R), hear it, see the line, see the panel fall and land;
phone-size judged; what can't be checked from the MCP goes to OWNER.md.
**Read first:** ROADMAP L-13b2d2b; DECISIONS D-053 and D-062; `src/server/Saws.luau` (the press,
the hold, the checks); `src/shared/StorageUnit/CrawlHole/Sawing.luau` (`decide`, `line`);
`src/client/SawView.luau` (the line, the fall); `src/server/Ladders.luau` (Grep `move == "Top"`).

## Queue (the next run's order, from ROADMAP)
1. L-13b2d2b, L-13b2d2c (the map: the hole off `Tops`, a lip, the ladder's lying spots), then
   L-13b2d3 (the drop in; out by the door or sawing sideways). L-06b the Mannequin hunts **waits
   on Brix** (ENG-07a/b); a Brix session first. None of the escapes has been tried against a
   keeper yet. L-12c needs L-06b. Then L-14; L-07, L-08, L-10, L-09.
2. **GDD, small:** its ladder line still says open mesh tops you run across (D-058/D-059 closed
   them, the crawl steered); update it (a Claude Doc: the docs tools).
3. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders` knows who's up).
4. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
5. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
6. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
7. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes.
8. **Look, small:** your torch's head is a flat black disc from behind; a faint rim? Owner's call.
9. L-06b's keepers hear doors, the keypad, a dropped tool, the saw, a crawl and the ladder (see
   D-059's signals); see a torch; treat a holed wall as solid; can't reach the tops.
10. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not our code; find what asks for it.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
