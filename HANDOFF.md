# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 54 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-13b2d2b is done** (D-063): lying up on the tops with a saw, a Saw button over every unit's
  hole spot (`Saws`, now jobs of two kinds, a wall or a top). The wall's hold, sounds and checks,
  plus crawling (`Ladders:crawling`), over this top, and not on the hole ("Move off it",
  `Sawing.onHole`). The line runs round on the steel's face (`Sawing.flat`, `TopHole.cutFrame`);
  through, `TopHole.saw`, and every screen drops the panel from its spot in the hole
  (`TopHole.unfallen`, from the art's exported `Specs.Fall`) with a floor-wide clang.
- **Verified in Studio** (M, test hall Unit 101): climbed as a player, held, let go early (lost),
  held through; the thin line and sparks; the panel hung, fell ~0.33 s and hopped; the sawn top,
  its edge and split collider; the button gone after. Once, the first cut's panel didn't drop
  (not repeated; in `OWNER.md`). How to get a player up there from the MCP: `docs/STUDIO.md`.
- Still to come: the hole is still on the tops' map (you can crawl over it), and nothing drops
  you in yet.

## Next task: L-13b2d2c The map
The moment: crawling along the tops you reach a sawn hole, can't crawl over it, push your head
out over its edge and shine your torch down into the dark unit before you commit.
1. Owner test results first (`OWNER.md`'s L-13b2d2b, L-13b2d2a, L-13b2c2, L-13b2c sections).
2. The hole off the map: `Tops`' rectangles with each sawn top's hole cut out (`TopHole.frame`,
   `Rect`; a sawn top carries `TopHole.Tag`), on the server's check and every crawler's screen,
   updated the moment a top is sawn. A lip like a front's (D-059) so the head can go out over it.
3. Anyone lying across the hole as it goes through (a friend; the sawer can't) slides off its edge
   onto the steel, told to their screen as the server's put-back is (`Leaned.FixAttribute`).
4. The ladder's lying spots that touch a hole (`Leaning.lying`): on an S the hole reaches all three;
   move them behind it or refuse the ladder there, with a refusal that names the fix.
5. A lit unit's bulb shining up through the hole: check it does (it's the tell from the tops).
**Acceptance:** checks green; Lune checks for the map with a hole cut out (can't cross it, the head
may go over its lip, a body on it is put off it); in Studio crawl up to a sawn hole as a player,
look down it with the torch; what the MCP can't check goes to OWNER.md.
**Read first:** ROADMAP L-13b2d2c; DECISIONS D-059 and D-063; `src/shared/Tops.luau` (the map,
`near`, the lip); `src/server/FloorBuilder.luau` (Grep `MapAttribute`); `src/server/Ladders.luau`
(Grep `map`, `checkCrawl`); `src/shared/Tools/Leaning.luau` (Grep `function Leaning.lying`).

## Queue (the next run's order, from ROADMAP)
1. L-13b2d2c, then L-13b2d3 (the drop in; out by the door or sawing sideways). Then L-06b the
   Mannequin hunts, which **no longer waits on Brix**: the keepers' brain is this game's (D-064),
   split into L-06b1 to L-06b4, the halls as a map first. None of the escapes has been tried
   against a keeper yet. L-12c needs L-06b. Then L-14; L-07, L-08, L-10, L-09.
2. **GDD, small:** its ladder line still says open mesh tops you run across (D-058/D-059 closed
   them, the crawl steered); update it (a Claude Doc: the docs tools).
3. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders:crawling` now says who's up).
4. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
5. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
6. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
7. **Check, small:** G is both a door's Slam and Drop: with a tool in hand, does G at an open
   door slam, drop, or both? Give Drop its own key if it clashes.
8. **Look, small:** your torch's head is a flat black disc from behind; a faint rim? Owner's call.
9. L-06b's keepers hear doors, the keypad, a dropped tool, the saw (walls and tops, `kind`), a
   crawl and the ladder (D-059's signals); see a torch; treat a holed wall as solid; can't reach
   the tops.
10. **Check:** Output warns six times per Play, "rbxassetid://203785492 failed: Asset type does
   not match": not our code; find what asks for it.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
